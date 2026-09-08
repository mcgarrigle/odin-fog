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

create_domain_vol_table :: proc(vols: []vir.DomainDiskInfo) -> ^table.Table {
  tbl := table.init(new(table.Table), context.allocator)
  table.caption(tbl,"Volumes")
  table.header(tbl, "target", "source")
  for vol in vols {
    table.row(tbl, vol.target, vol.source)
  }
  return tbl
}

// --------------------------------------------------------------

command_info :: proc(args: []string) {
  if len(args) == 0 do error("domain name required")

  domain, ok := cluster_find_domain(cluster_list(cluster), args[0])

  if !ok do error("domain not found")

  dtab := create_domain_table(domain)

  vols := vir.DomainGetDiskInfo(domain.domain)
  vtab := create_domain_vol_table(vols)

  render_table(dtab, .Lines)
  render_table(vtab, .Lines)
}
