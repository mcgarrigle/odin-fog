package main

import vir "project:libvirt"

// --------------------------------------------------------------

destroy_disk :: proc(conn: ^vir.Connect, path: string) {
  vol := vir.StorageVolLookupByPath(conn, path)
  vir.StorageVolDelete(vol)
}

destroy_domain :: proc(domain: ^vir.Domain) {
  conn := vir.DomainGetConnect(domain)
  vir.DomainDestroy(domain)
  vir.DomainUndefineFlags(domain, .UndefineNVRAM)
  disks := vir.DomainGetDiskInfo(domain)
  for disk in disks {
    if disk.device == "disk" do destroy_disk(conn, disk.source)
  }
}

// -- commands --------------------------------------------------

command_down :: proc(domain: vir.DomainDetails) {
  destroy_domain(domain.domain)
}
