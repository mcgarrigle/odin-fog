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
  memory:          string "MEMORY",
  pool:            string "POOL:filesystems",
  root_device:     string "ROOT_DEVICE",
  root_size:       string "ROOT_SIZE",
  boot:            string "BOOT",
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

guest :: proc() -> Guest {
  guest: Guest

  environment.extract(&guest)
  return guest
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
  user_path := cloud_init_file("user-data", guest)
  meta_path := cloud_init_file("meta-data", guest)
  netw_path := cloud_init_file("network-config-static", guest)
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
 
destroy_guest :: proc(guest: string) {
  pool := util.get_env("POOL", "filesystems")
  volume_name := util.strcat(guest, ".qcow2")
  util.run("virsh", "destroy", guest)
  util.run("virsh", "undefine", "--nvram", guest)
  util.run("virsh", "vol-delete", "--pool", pool, "--vol", volume_name)
}

// -- commands --------------------------------------------------

command_up :: proc() {
  build_guest(guest())
}

command_down :: proc(args: []string) {
  destroy_guest(args[0])
}

dispatch :: proc(args: []string) {
  switch args[0] {
  case "up":
    command_up()
  case "down":
    command_down(args[1:])
  case: 
	  fmt.println("unknown command")
  }
}

// -- main ------------------------------------------------------

main :: proc() {
  base_directory, _ = os.get_executable_directory(context.allocator)
  dispatch(os.args[1:])
}
