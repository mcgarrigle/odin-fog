package main

import vir "project:libvirt"

// -- commands --------------------------------------------------

command_start :: proc(domain: vir.DomainDetails) {
  vir.DomainCreateWithFlags(domain.domain)
}
