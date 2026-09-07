package main

import "core:fmt"
import "core:os"
import "core:io"
import "core:strings"
import "core:strconv"
import "core:sort"
import "core:text/table"
import "core:path/filepath"

import vir "project:libvirt"

// --------------------------------------------------------------

compare_domains :: proc(a, b: vir.DomainDetails) -> int {
  return sort.compare_strings(a.name, b.name)
}

create_domain_list_table :: proc(domains: []vir.DomainDetails) -> ^table.Table {
  sort.heap_sort_proc(domains, compare_domains)

  tbl := table.init(new(table.Table), context.allocator)
  table.header(tbl, "ID", "Name", "State", "Host")
  for domain in domains {
    table.row(tbl, format_id(domain.id), domain.name, domain.state, domain.host)
  }
  return tbl
}

// --------------------------------------------------------------

command_ls :: proc() {
  domains := cluster_list(cluster)
  tab := create_domain_list_table(domains)
  render_table(tab, .Lines)
}
