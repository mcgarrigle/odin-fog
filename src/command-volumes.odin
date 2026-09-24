package main

import "core:fmt"
import "core:sort"
import "core:text/table"

import vir "project:libvirt"

// --------------------------------------------------------------

compare_vols :: proc(a, b: vir.StorageVolDetails) -> int {
  return sort.compare_strings(a.name, b.name)
}

create_vol_list_table :: proc(vols: []vir.StorageVolDetails, units: bool) -> ^table.Table {
  // sort.heap_sort_proc(domains, compare_vols)

  tbl := table.init(new(table.Table), context.allocator)
  table.caption(tbl,"Volumes")
  table.header(tbl, "Host", "Pool", "Key", "Capacity", "Allocation")
  for vol in vols {
    table.row(tbl, vol.host, vol.pool, vol.key, format_bytes(vol.capacity, units), format_bytes(vol.allocation, units))
  }
  return tbl
}

// --------------------------------------------------------------

command_volumes :: proc() {
  list: [dynamic]vir.StorageVolDetails

  format := table_format(.Decorated)
  units := (format != .Stream)

  for node in cluster {
    pools := vir.pool_list(node.conn, node.name)
    for pool in pools {
      vols := vir.vol_list(pool.pool, node.name, pool.name)
      append(&list, ..vols)
    }
  }
  tab := create_vol_list_table(list[:], units)
  render_table(tab, format)
}
