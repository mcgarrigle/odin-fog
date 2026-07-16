package main

import "core:fmt"
import "core:os"

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

build_vm :: proc(guest: map[string]string) {
  args := [dynamic]string{}
  append(&args, "--name", guest["HOST"]) 
  append(&args, "--osinfo", guest["OS"]) 
  append(&args, "--vcpu", guest["CPUS"]) 
  append(&args, "--memory", guest["MEMORY"]) 
  append(&args, "--machine", guest["MACHINE"])
  append(&args, "--boot", guest["BOOT"])
  append(&args, "--disk", guest["DISK"])
  append(&args, "--cloud-init", guest["CLOUD_INIT"])
  append(&args, "--network", guest["NETWORK"])
	fmt.println(args)
  // run({"virsh", "list"})
}

// -- commands --------------------------------------------------

command_up :: proc(args: []string) {
	fmt.println("command up")
  build_vm(guest())
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

main :: proc() {
  dispatch(os.args[1:])
}
