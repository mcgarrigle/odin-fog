package main

import "core:sort"
import "core:text/table"

import vir "project:libvirt"

// --------------------------------------------------------------

array2string :: proc (s: []u8) -> string {
  for i in 0..<len(s) {
    if s[i] == 0 do return string(s[:i])
  }
  return ""
}

// --------------------------------------------------------------

command_cluster :: proc() {
  format, units := table_format(.Decorated)

  tab := table.init(new(table.Table), context.allocator)
  table.caption(tab, "Nodes")
  table.header(tab, "Name", "URI", "Model", "Memory", "CPUs", "Sockets", "Cores", "Threads")

  for node in cluster {
    info: vir.NodeInfo

    vir.NodeGetInfo(node.conn, &info)
    uri   := vir.ConnectGetURI(node.conn)
    model := array2string(info.model[:])
    mem   := format_bytes(info.memory * 1024, units)
    table.row(tab, node.name, uri, model, mem, info.cpus, info.sockets, info.cores, info.threads)
  }
  render_table(tab, format)
}
