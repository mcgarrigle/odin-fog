package main

import vir "project:libvirt"

// --------------------------------------------------------------

destroy_disk :: proc(conn: ^vir.Connect, path: string) {
  vol := vir.StorageVolLookupByPath(conn, path)
  _ = vir.StorageVolDelete(vol)
}

// -- commands --------------------------------------------------

command_down :: proc(domain: vir.DomainDetails) {
  conn := vir.DomainGetConnect(domain.domain)
  vir.DomainDestroy(domain.domain)
  _ = vir.DomainUndefineFlags(domain.domain, .UndefineNVRAM)
  disks := vir.DomainGetDiskInfo(domain.domain)
  for disk in disks {
    if disk.device == "disk" do destroy_disk(conn, disk.source)
  }
}
