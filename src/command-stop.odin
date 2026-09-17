package main

import vir "project:libvirt"

// -- commands --------------------------------------------------

command_stop :: proc(domain: vir.DomainDetails) {
  vir.DomainDestroy(domain.domain)
}
