package environment

import "core:testing"
import "core:os"
import "core:fmt"
import "project:environment"


Example :: struct {
  host:            string "HOST",
  machine:         string "MACHINE:q35",
//  os:              string "OS",
//  cpus:            string "CPUS",
//  memory:          string "MEMORY",
//  pool:            string "POOL",
//  dns_server:      string "DNS_SERVER",
//  disk:            string
}

// ---------------------------------------------------------------------

@(test)
test_simple_assignment :: proc(t: ^testing.T) {

  e: Example

  os.set_env("HOST", "foo")
  environment.extract(&e)
  testing.expect_value(t, e.host, "foo")
}

@(test)
test_default_assignment :: proc(t: ^testing.T) {

  e: Example

  os.set_env("MACHINE", "")
  environment.extract(&e)
  testing.expect_value(t, e.machine, "q35")
}
