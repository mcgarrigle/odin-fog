package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:slice"

import "project:util"
import "project:template"
import "project:environment"


DEBUG :: #config(DEBUG, false)

base_directory: string

cluster: Cluster

// --------------------------------------------------------------

destroy_guest :: proc(name: string) {
  util.run("virsh", "destroy", "--domain", name)
  util.run("virsh", "undefine", "--domain", name, "--remove-all-storage", "--nvram")
}

// -- commands --------------------------------------------------

shift :: proc(array: $T/[]$E) -> (E, []E) {
  x := array[0]
  slice.rotate_left(array, 1)
  return x, array[0:len(array)-1]
}

error :: proc(m: string) {
  fmt.println(m)
  os.exit(1)
}

command_down :: proc(name: string) {
  destroy_guest(name)
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
  command, rest := shift(args)
  switch command {
  case "list", "ls":
    command_list()
  case "info":
    command_info(rest)
  case "pools":
    command_pools()
  case "vols":
    command_vols()
  case "build":
    command_build()
  case "down":
    command_down(domain(args))
  case: 
    fmt.println("unknown command")
  }
}

// -- main ------------------------------------------------------

main :: proc() {
  base_directory, _ = os.get_executable_directory(context.allocator)
  names := strings.split(util.get_env("FOG_CLUSTER", "local"), " ")
  cluster = cluster_init(names)
  dispatch(os.args[1:])
}
