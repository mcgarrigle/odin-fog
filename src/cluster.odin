package main

import "core:sort"
import "core:c/libc"

import vir "project:libvirt"

// --------------------------------------------------------------

ClusterNode :: struct {
  name: string,
  conn: ^vir.Connect
}

Cluster :: []ClusterNode

// --------------------------------------------------------------

error_handler :: proc "cdecl" (data: rawptr, err: ^vir.Error) {
  // libc.fprintf(libc.stderr, "%s\n", err.message)
}

cluster_init :: proc(names: []string) -> Cluster {
  sort.heap_sort_proc(names, sort.compare_strings)
  cluster := make(Cluster, len(names))
  for name, i in names {
    cluster[i].name = name
    cluster[i].conn = vir.ConnectOpen(name)
    vir.ConnSetErrorFunc(cluster[i].conn, nil, error_handler)
  }
  return cluster[:]
}

cluster_list :: proc(cluster: Cluster) -> []vir.DomainDetails {
  res: [dynamic]vir.DomainDetails

  for node in cluster {
    list := vir.list(node.conn, node.name)
    append(&res, ..list)
  }
  return res[:]
}

cluster_find_domain :: proc(domains: []vir.DomainDetails, name: string) -> (vir.DomainDetails, bool) {
  for domain in domains {
    if domain.name == name do return domain, true
  }
  return vir.DomainDetails{}, false
}
