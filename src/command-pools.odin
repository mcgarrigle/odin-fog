package main

import "core:fmt"
import "core:sort"
import "core:text/table"

import vir "project:libvirt"

// --------------------------------------------------------------

compare_pools :: proc(a, b: vir.StorageVolDetails) -> int {
  return sort.compare_strings(a.name, b.name)
}

create_pool_list_table :: proc(pools: []vir.StoragePoolDetails) -> ^table.Table {
  // sort.heap_sort_proc(domains, compare_vols)

  tbl := table.init(new(table.Table), context.allocator)
  table.caption(tbl,"Pools")
  table.header(tbl, "Host", "Name", "Capacity", "Allocation")
  for pool in pools {
    table.row(tbl, pool.host, pool.name, format_bytes(pool.capacity), format_bytes(pool.allocation))
  }
  return tbl
}

// --------------------------------------------------------------

command_pools :: proc() {
  list: [dynamic]vir.StoragePoolDetails

  for node in cluster {
    pools := vir.pool_list(node.conn, node.name)
    append(&list, ..pools)
  }
  tab := create_pool_list_table(list[:])
  render_table(tab, .Lines)
}
