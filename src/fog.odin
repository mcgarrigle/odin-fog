package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:slice"

import "project:util"
import "project:template"
import "project:environment"

import vir "project:libvirt"


DEBUG :: #config(DEBUG, false)

base_directory: string

cluster: Cluster

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

exit_domain :: proc(m: string) -> vir.DomainDetails {
  error(m)
  return vir.DomainDetails{}
}

domain :: proc(args: []string) -> vir.DomainDetails {
  switch len(args) {
  case 0:
    return exit_domain("missing parameter: domain name required")
  case 1:
    dom, ok := cluster_find_domain(cluster_list(cluster), args[0])
    if ok do return dom
    return exit_domain(fmt.aprintf("domain '%s' not found", args[0]))
  case:
    return exit_domain("single domain name required")
  }
}

dispatch :: proc(args: []string) {
  command, rest := shift(args)
  switch command {
  case "list", "ls":
    command_list()
  case "info":
    command_info(domain(rest))
  case "pools":
    command_pools()
  case "vols":
    command_vols()
  case "build":
    command_build()
  case "down":
    command_down(domain(rest))
  case: 
    error("unknown command")
  }
}

// -- main ------------------------------------------------------

main :: proc() {
  base_directory, _ = os.get_executable_directory(context.allocator)
  names := strings.split(util.get_env("FOG_CLUSTER", "local"), " ")
  cluster = cluster_init(names)
  dispatch(os.args[1:])
}
