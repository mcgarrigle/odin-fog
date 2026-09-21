package main

import "core:fmt"
import "core:strings"
import "core:sort"
import "core:text/table"

import vir "project:libvirt"

// --------------------------------------------------------------

command_cluster :: proc() {
  tab := table.init(new(table.Table), context.allocator)
  table.caption(tab,"Nodes")
  table.header(tab, "Name", "URI", "Model", "CPUs", "Sockets", "Cores", "Threads")

  for node in cluster {
    info: vir.NodeInfo

    vir.NodeGetInfo(node.conn, &info)
    uri   := vir.ConnectGetURI(node.conn)
    model := string(info.model[:])
    table.row(tab, node.name, uri, model, info.cpus, info.sockets, info.cores, info.threads)
  }
  render_table(tab, .Lines)
}
