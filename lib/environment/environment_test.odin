package environment

import "core:testing"
import "core:os"
import "core:fmt"
import "project:environment"


Example :: struct {
  host:            string "HOST",
  machine:         string "MACHINE:q35",
  disk:            string
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
test_empty_tag_assignment :: proc(t: ^testing.T) {
  e: Example
  environment.extract(&e)
  testing.expect_value(t, e.disk, "")
}

@(test)
test_override_default_assignment :: proc(t: ^testing.T) {
  e: Example
  os.set_env("MACHINE", "pc")
  environment.extract(&e)
  testing.expect_value(t, e.machine, "pc")
}

@(test)
test_default_assignment :: proc(t: ^testing.T) {
  e: Example
  os.set_env("MACHINE", "")
  environment.extract(&e)
  testing.expect_value(t, e.machine, "q35")
}

@(test)
test_unset_assignment :: proc(t: ^testing.T) {
  e: Example
  os.unset_env("MACHINE")
  environment.extract(&e)
  testing.expect_value(t, e.machine, "q35")
}
