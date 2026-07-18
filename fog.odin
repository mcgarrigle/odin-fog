package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:math/rand"
import "core:strings"
import "core:strconv"
import "core:encoding/hex"


base_directory: string

variables: []string = {
  "HOST",
  "MACHINE",
  "IMAGE",
  "OS",
  "CPUS",
  "MEMORY",
  "POOL",
  "DISK",
  "ROOT_DEVICE",
  "ROOT_SIZE",
  "BOOT",
  "BOOTPROTO",
  "NETWORK",
  "NETWORK_DEVICE",
  "IP_ADDRESS",
  "GATEWAY_ADDRESS",
  "DNS_SERVER",
  "USER",
  "PASSWORD",
  "SSH_PUBLIC_KEY"
}

// --------------------------------------------------------------

guest :: proc() -> map[string]string {
  result := make(map[string]string)
  for key in variables {
    result[key] = os.get_env(allocator=context.allocator, key=key)
  }
  return result
}

run_slice :: proc(args: []string) {
  command := os.Process_Desc{command=args}

  state, stdout, stderr, err := os.process_exec(desc=command, allocator=context.allocator)
  if err != nil {
    fmt.panicf("Failed to start command: %v", err)
  }
  fmt.println(string(stdout))
}

run :: proc(args: ..string) {
  run_slice(args)
}

// --------------------------------------------------------------

tempfile :: proc() -> string {
  return fmt.aprintf("/tmp/fog.%x", rand.uint64())
}

varname :: proc(name: string) -> string {
  parts := []string{"${", name, "}"}
  return strings.concatenate(parts)
}

template :: proc(text: string, vars: map[string]string) -> string {
  result := text
  for v in vars {
    pattern := varname(v)
    result, _ = strings.replace_all(result, pattern, vars[v])
  }
  return result
}

cloud_init_file :: proc(file: string, guest: map[string]string) -> string {
  template_path, _ := filepath.join({base_directory, "cloud-init", file})
  t, err := os.read_entire_file(template_path, context.allocator)
  config := template(string(t), guest)
  path := tempfile()
  err = os.write_entire_file(path, config)
  return path
}

build_cloud_init :: proc(guest: map[string]string) -> string {
  user_path := cloud_init_file("user-data", guest)
  meta_path := cloud_init_file("meta-data", guest)
  netw_path := cloud_init_file("network-config-static", guest)
  config: []string = {"user-data=", user_path, ",meta-data=", meta_path, ",network-config=", netw_path}
  return strings.concatenate(config)
}

// --------------------------------------------------------------

upload_image :: proc() {
  // virsh vol-create-as --pool "${POOL}" --name "$2" --capacity 1m
  // virsh vol-upload --pool "${POOL}" --vol "$2" --file "$1"
  // virsh vol-list --pool "${POOL}"
}

build_disk :: proc(guest: map[string]string) -> string {
  size, ok := strconv.parse_int(guest["ROOT_SIZE"])
  image_path, _ := filepath.join({base_directory, "images", guest["IMAGE"]})
  disk_path, _  := filepath.join({base_directory, "images", guest["HOST"]})
  run("echo", "truncate", "--reference", image_path, "--size", guest["ROOT_SIZE"], disk_path)
  run("echo", "virt-resize", "--quiet", "--expand", guest["ROOT_DEVICE"], image_path, disk_path)
  // upload "${DISK}" "${PRIMARY}"
  return "device=disk"
}

// --------------------------------------------------------------

build_vm :: proc(guest: map[string]string, disk: string, cloud_init: string) {
  args: []string = {"echo", "virt-install", 
    "--import", 
    "--noautoconsole",
    "--virt-type", "kvm", 
    "--graphics", "none", 
    "--name", guest["HOST"],
    "--osinfo", guest["OS"],
    "--vcpu", guest["CPUS"],
    "--memory", guest["MEMORY"],
    "--machine", guest["MACHINE"],
    "--boot", guest["BOOT"],
    "--network", guest["NETWORK"],
    "--disk", disk,
    "--cloud-init", cloud_init
  }
	// fmt.println(args)
  run_slice(args)
}

build_guest :: proc(guest: map[string]string) {
  disk := build_disk(guest)
  cloud_init := build_cloud_init(guest)
  build_vm(guest, disk, cloud_init)
}
 
// -- commands --------------------------------------------------

command_up :: proc(args: []string) {
  build_guest(guest())
}

command_down :: proc(args: []string) {
  fmt.println("command down")
}

dispatch :: proc(args: []string) {
  switch args[0] {
  case "up":
    command_up(args[1:])
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
