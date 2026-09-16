package main

import "core:fmt"
import "core:text/table"

import vir "project:libvirt"

// --------------------------------------------------------------

create_domain_table :: proc(domain: vir.DomainDetails) -> ^table.Table {
  tbl := table.init(new(table.Table), context.allocator)
  table.caption(tbl,"Domain")
  table.row(tbl, "ID:", format_id(domain.id))
  table.row(tbl, "Name:", domain.name)
  table.row(tbl, "State:", domain.state)
  table.row(tbl, "CPUs:", domain.nrVirtCpu)
  table.row(tbl, "Memory:", format_bytes(domain.memory * 1024))
  table.row(tbl, "Autostart:", format_enabled(domain.autostart))
  table.row(tbl, "AutostartOnce:", format_enabled(domain.autostart_once))
  table.row(tbl, "Host:", domain.host)
  return tbl
}

// --------------------------------------------------------------

get_volume_info :: proc(conn: ^vir.Connect, path: string) -> (capacity: string, allocation: string) {
  v := vir.StorageVolLookupByPath(conn, path)
  if v == nil do return "-", "-"
  d := vir.vol_get_details(v)
  return format_bytes(d.capacity), format_bytes(d.allocation)
}

create_domain_vol_table :: proc(conn: ^vir.Connect, vols: []vir.DomainDiskInfo) -> ^table.Table {
  tbl := table.init(new(table.Table), context.allocator)
  table.caption(tbl,"Volumes")
  table.header(tbl, "Target", "Source", "Capacity", "Allocation")
  for vol in vols {
    capacity, allocation := get_volume_info(conn, vol.source)
    table.row(tbl, vol.target, vol.source, capacity, allocation)
  }
  return tbl
}

// --------------------------------------------------------------

command_info :: proc(domain: vir.DomainDetails) {
  conn := vir.DomainGetConnect(domain.domain)
  dtab := create_domain_table(domain)

  vols := vir.DomainGetDiskInfo(domain.domain)
  vtab := create_domain_vol_table(conn, vols)

  render_table(dtab, .Lines)
  render_table(vtab, .Lines)
}
