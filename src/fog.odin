package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:reflect"

import "project:util"
import "project:template"
import "project:environment"


DEBUG :: #config(DEBUG, false)

base_directory: string

Guest :: struct {
  host:            string "HOST",
  machine:         string "MACHINE:q35",
  image:           string "IMAGE",
  os:              string "OS",
  cpus:            string "CPUS:1",
  memory:          string "MEMORY:2048",
  pool:            string "POOL:filesystems",
  root_device:     string "ROOT_DEVICE",
  root_size:       string "ROOT_SIZE",
  boot:            string "BOOT:uefi",
  bootproto:       string "BOOTPROTO:static",
  network:         string "NETWORK",
  network_device:  string "NETWORK_DEVICE",
  ip_address:      string "IP_ADDRESS",
  gateway_address: string "GATEWAY_ADDRESS",
  dns_server:      string "DNS_SERVER:1.1.1.1",
  user:            string "USER",
  password:        string "PASSWORD",
  ssh_public_key:  string "SSH_PUBLIC_KEY",
  disk:            string,
  cloud_init:      string
}

// --------------------------------------------------------------

cloud_init_file :: proc(file: string, guest: Guest) -> string {
  template_path, _ := filepath.join({base_directory, "cloud-init", file})
  text, _ := os.read_entire_file(template_path, context.allocator)
  config := template.render(string(text), guest)
  path := util.tempfile()
  _ = os.write_entire_file(path, config)
  return path
}

build_cloud_init :: proc(guest: Guest) -> string {
  netw_template := util.strcat("network-config-", guest.bootproto)
  user_path := cloud_init_file("user-data", guest)
  meta_path := cloud_init_file("meta-data", guest)
  netw_path := cloud_init_file(netw_template, guest)
  return util.strcat("user-data=", user_path, ",meta-data=", meta_path, ",network-config=", netw_path)
}

// --------------------------------------------------------------

upload_image :: proc(source, pool, volume: string) {
  util.run("virsh", "vol-create-as", "--capacity", "1m", "--pool", pool, "--name", volume)
  util.run("virsh", "vol-upload", "--file", source, "--pool", pool, "--vol", volume)
}

resize_image :: proc(image_path, volume_path, root_device, root_size: string) {
  util.run("truncate", "--reference", image_path, "--size", root_size, volume_path)
  util.run("virt-resize", "--quiet", "--expand", root_device, image_path, volume_path)
}

build_disk :: proc(guest: Guest) -> string {
  volume_name    := util.strcat(guest.host, ".qcow2")
  volume_path, _ := filepath.join({base_directory, "images", volume_name})
  image_path, _  := filepath.join({base_directory, "images", guest.image})
  resize_image(image_path, volume_path, guest.root_device, guest.root_size)
  upload_image(volume_path, guest.pool, volume_name)
  return util.strcat("device=disk,vol=", guest.pool, "/", volume_name)
}

// --------------------------------------------------------------

build_vm :: proc(guest: Guest, disk: string, cloud_init: string) {
  args: []string = {
    "virt-install", 
    "--import", 
    "--autorestart",
    "--noautoconsole",
    "--virt-type", "kvm", 
    "--graphics", "none", 
    "--name", guest.host,
    "--osinfo", guest.os,
    "--vcpu", guest.cpus,
    "--memory", guest.memory,
    "--machine", guest.machine,
    "--boot", guest.boot,
    "--network", guest.network,
    "--disk", disk,
    "--cloud-init", cloud_init
  }
  util.run_slice(args)
}

build_guest :: proc(guest: Guest) {
  disk := build_disk(guest)
  cloud_init := build_cloud_init(guest)
  build_vm(guest, disk, cloud_init)
}
 
destroy_guest :: proc(name: string) {
  util.run("virsh", "destroy", "--domain", name)
  util.run("virsh", "undefine", "--domain", name, "--remove-all-storage", "--nvram")
}

// -- commands --------------------------------------------------

error :: proc(m: string) {
  fmt.println(m)
  os.exit(1)
}

command_ls :: proc() {
  util.run("virsh", "list", "--all")
}

command_up :: proc() {
  guest: Guest
  environment.extract(&guest)
  build_guest(guest)
}

command_down :: proc(name: string) {
  destroy_guest(name)
}

command_vols :: proc() {
  pool := util.get_env("POOL", "filesystems")
  util.run("virsh", "vol-list", "--pool", pool)
}

command_info :: proc(name: string) {
  util.run("virsh", "dominfo", "--domain", name)
  util.run("virsh", "domblklist", "--domain", name)
}

domain :: proc(args: []string) -> string {
  switch len(args) {
  case 1:
    error("missing parameter: domain name required")
    return "err"
  case 2:
    return args[1]
  case:
    error("extra parameter: domain name required")
    return "err"
  }
}

dispatch :: proc(args: []string) {
  switch args[0] {
  case "ls":
    command_ls()
  case "up":
    command_up()
  case "down":
    command_down(domain(args))
  case "vols":
    command_vols()
  case "info":
    command_info(domain(args))
  case: 
	  fmt.println("unknown command")
  }
}

// -- main ------------------------------------------------------

main :: proc() {
  base_directory, _ = os.get_executable_directory(context.allocator)
  dispatch(os.args[1:])
}
