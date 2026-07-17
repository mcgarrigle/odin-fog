package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:math/rand"
import "core:strings"
import "core:strconv"
import "core:encoding/hex"


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

run :: proc(args: []string) {
  command := os.Process_Desc{command=args}

  state, stdout, stderr, err := os.process_exec(desc=command, allocator=context.allocator)
  if err != nil {
    fmt.panicf("Failed to start command: %v", err)
  }
  fmt.println(string(stdout))
}

// --------------------------------------------------------------

tempfile :: proc() -> string {
  return fmt.aprintf("/tmp/%x", rand.uint64())
}

var :: proc(name: string) -> string {
  parts := []string{"${", name, "}"}
  return strings.concatenate(parts)
}

template :: proc(text: string, vars: map[string]string) -> string {
  result := text
  for v in vars {
    pattern := var(v)
    result, _ = strings.replace_all(result, pattern, vars[v])
  }
  return result
}

make_cloud_init_file :: proc(file: string, vars: map[string]string) -> string {
  path, _ := filepath.join({"cloud-init", file})
  fmt.println(tempfile())
  return path
}

// --------------------------------------------------------------

build_disk :: proc(guest: map[string]string) -> string {
  size, ok := strconv.parse_int(guest["ROOT_SIZE"])
  return "device=disk"
}

// --------------------------------------------------------------

build_cloud_init :: proc(guest: map[string]string) -> string {
  // meta_data := template("aa ${HOST} ${IMAGE}bb", guest)
  path := make_cloud_init_file("meta-data", guest)
  fmt.println(path)
  return "meta-data=file"
}

// --------------------------------------------------------------

build_vm :: proc(guest: map[string]string, disk: string, cloud_init: string) {
  args := [dynamic]string{}
  append(&args, "virt-install", "--import", "--virt-type", "kvm", "--graphics", "none", "--noautoconsole")
  append(&args, "--name", guest["HOST"]) 
  append(&args, "--osinfo", guest["OS"]) 
  append(&args, "--vcpu", guest["CPUS"])
  append(&args, "--memory", guest["MEMORY"]) 
  append(&args, "--machine", guest["MACHINE"])
  append(&args, "--boot", guest["BOOT"])
  append(&args, "--disk", disk)
  append(&args, "--cloud-init", cloud_init)
  append(&args, "--network", guest["NETWORK"])
	fmt.println(args)
  // run({"virsh", "list"})
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
  dispatch(os.args[1:])
}
