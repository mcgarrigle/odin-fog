package util

import "core:testing"
import "core:os"
import "project:util"

// ---------------------------------------------------------------------

@(test)
test_simple_assignment :: proc(t: ^testing.T) {
  os.set_env("HOST", "foo")
  value := util.get_env("HOST")
  defer delete(value)
  testing.expect_value(t, value, "foo")
}

@(test)
test_override_default_assignment :: proc(t: ^testing.T) {
  os.set_env("MACHINE", "pc")
  value := util.get_env("MACHINE", "q35")
  defer delete(value)
  testing.expect_value(t, value, "pc")
}

@(test)
test_empty_assignment :: proc(t: ^testing.T) {
  os.set_env("MACHINE", "")
  value := util.get_env("MACHINE", "q35")
  defer delete(value)
  testing.expect_value(t, value, "q35")
}

@(test)
test_unset_assignment :: proc(t: ^testing.T) {
  os.unset_env("MACHINE")
  value := util.get_env("MACHINE", "q35")
  defer delete(value)
  testing.expect_value(t, value, "q35")
}
