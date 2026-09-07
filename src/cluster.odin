package main

import vir "project:libvirt"

// --------------------------------------------------------------

ClusterNode :: struct {
  name: string,
  conn: ^vir.Connect
}

Cluster :: []ClusterNode

cluster_init :: proc(names: []string) -> Cluster {
  cluster := make(Cluster, len(names))
  for name, i in names {
    cluster[i].name = name
    cluster[i].conn = vir.ConnectOpen(name)
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
