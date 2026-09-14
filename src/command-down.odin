package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:slice"

import vir "project:libvirt"


// --------------------------------------------------------------

destroy_guest :: proc(name: string) {
  // util.run("virsh", "destroy", "--domain", name)
  // util.run("virsh", "undefine", "--domain", name, "--remove-all-storage", "--nvram")
}

// -- commands --------------------------------------------------

command_down :: proc(domain: vir.DomainDetails) {
  // destroy_guest(name)
  vols := vir.DomainGetDiskInfo(domain.domain)
  fmt.println(vols)
}
