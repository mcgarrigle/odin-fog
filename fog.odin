package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:math/rand"
import "core:strings"
import "core:reflect"


DEBUG :: #config(DEBUG, false)

base_directory: string

Guest :: struct {
  host:            string "HOST",
  machine:         string "MACHINE",
  image:           string "IMAGE",
  os:              string "OS",
  cpus:            string "CPUS",
  memory:          string "MEMORY",
  pool:            string "POOL",
  root_device:     string "ROOT_DEVICE",
  root_size:       string "ROOT_SIZE",
  boot:            string "BOOT",
  bootproto:       string "BOOTPROTO",
  network:         string "NETWORK",
  network_device:  string "NETWORK_DEVICE",
  ip_address:      string "IP_ADDRESS",
  gateway_address: string "GATEWAY_ADDRESS",
  dns_server:      string "DNS_SERVER",
  user:            string "USER",
  password:        string "PASSWORD",
  ssh_public_key:  string "SSH_PUBLIC_KEY",
  disk:            string,
  cloud_init:      string
}

// --------------------------------------------------------------

get_env :: proc(key: string, default: string = "") -> string {
  value := os.get_env(key, context.allocator)
  if value == "" do return default
  return value
}

get_string_field :: proc(guest: Guest, field_name: string) -> string {
  value := reflect.struct_field_value_by_name(guest, field_name)
  return value.(string)
}

set_string_field :: proc(v: any, field_name: string, value: string) -> bool {
  // field := reflect.struct_field_by_name(typeid_of(type_of(v)), field_name)   // this does not work but probably should
  field := reflect.struct_field_by_name(typeid_of(Guest), field_name)
  if field.name == "" || !reflect.is_string(field.type) {
      return false
  }
  dst := (^string)(rawptr(uintptr(v.data) + field.offset))
  dst^ = value
  return true
}

guest :: proc() -> Guest {
  guest: Guest

  fields := reflect.struct_fields_zipped(Guest)
  for field in fields {
    if len(field.tag) > 0 {
      value := get_env(string(field.tag))
      set_string_field(guest, field.name, value)
    }
  }

  return guest
}

// --------------------------------------------------------------

strcat :: proc(list: ..string) -> string {
  return strings.concatenate(list)
}

run_slice :: proc(args: []string) {
  fmt.println(args)
  when !DEBUG {
    command := os.Process_Desc{command=args}
    state, stdout, stderr, err := os.process_exec(command, context.allocator)
    if err != nil {
      fmt.panicf("Failed to start command: %v", err)
    }
    fmt.println(string(stdout))
  }
}

run :: proc(args: ..string) {
  run_slice(args)
}

// --------------------------------------------------------------

tempfile :: proc() -> string {
  return fmt.aprintf("/tmp/fog.%x", rand.uint64())
}

varname :: proc(name: string) -> string {
  return strcat("${", name, "}")
}

render :: proc(text: string, guest: Guest) -> string {
  result := text
  for name in reflect.struct_field_names(Guest) {
    value := get_string_field(guest, name)
    result, _ = strings.replace_all(result, varname(name), value)
  }
  return result
}

cloud_init_file :: proc(file: string, guest: Guest) -> string {
  template_path, _ := filepath.join({base_directory, "cloud-init", file})
  template, _ := os.read_entire_file(template_path, context.allocator)
  config := render(string(template), guest)
  path := tempfile()
  _ = os.write_entire_file(path, config)
  return path
}

build_cloud_init :: proc(guest: Guest) -> string {
  user_path := cloud_init_file("user-data", guest)
  meta_path := cloud_init_file("meta-data", guest)
  netw_path := cloud_init_file("network-config-static", guest)
  return strcat("user-data=", user_path, ",meta-data=", meta_path, ",network-config=", netw_path)
}

// --------------------------------------------------------------

upload_image :: proc(source, pool, volume: string) {
  run("virsh", "vol-create-as", "--capacity", "1m", "--pool", pool, "--name", volume)
  run("virsh", "vol-upload", "--file", source, "--pool", pool, "--vol", volume)
}

resize_image :: proc(image_path, volume_path, root_device, root_size: string) {
  run("truncate", "--reference", image_path, "--size", root_size, volume_path)
  run("virt-resize", "--quiet", "--expand", root_device, image_path, volume_path)
}

build_disk :: proc(guest: Guest) -> string {
  volume_name    := strcat(guest.host, ".qcow2")
  volume_path, _ := filepath.join({base_directory, "images", volume_name})
  image_path, _  := filepath.join({base_directory, "images", guest.image})
  resize_image(image_path, volume_path, guest.root_device, guest.root_size)
  upload_image(volume_path, guest.pool, volume_name)
  return strcat("device=disk,vol=", guest.pool, "/", volume_name)
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
  run_slice(args)
}

build_guest :: proc(guest: Guest) {
  disk := build_disk(guest)
  cloud_init := build_cloud_init(guest)
  build_vm(guest, disk, cloud_init)
}
 
destroy_guest :: proc(guest: string) {
  pool := get_env("POOL", "filesystems")
  volume_name := strcat(guest, ".qcow2")
  run("virsh", "destroy", guest)
  run("virsh", "undefine", "--nvram", guest)
  run("virsh", "vol-delete", "--pool", pool, "--vol", volume_name)
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
