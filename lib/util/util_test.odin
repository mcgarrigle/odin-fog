package util

import "core:testing"
import "core:os"
import "core:log"

import "project:util"

// ---------------------------------------------------------------------

@(test)
test_get_env_simple_assignment :: proc(t: ^testing.T) {
  os.set_env("HOST", "foo")
  value := util.get_env("HOST")
  defer delete(value)
  testing.expect_value(t, value, "foo")
}

@(test)
test_get_env_override_default_assignment :: proc(t: ^testing.T) {
  os.set_env("MACHINE", "pc")
  value := util.get_env("MACHINE", "q35")
  defer delete(value)
  testing.expect_value(t, value, "pc")
}

@(test)
test_get_env_empty_assignment :: proc(t: ^testing.T) {
  os.set_env("MACHINE", "")
  value := util.get_env("MACHINE", "q35")
  defer delete(value)
  testing.expect_value(t, value, "q35")
}

@(test)
test_get_env_unset_assignment :: proc(t: ^testing.T) {
  os.unset_env("MACHINE")
  value := util.get_env("MACHINE", "q35")
  defer delete(value)
  testing.expect_value(t, value, "q35")
}

// ---------------------------------------------------------------------

@(test)
test_run_capture_success :: proc(t: ^testing.T) {
  out, err := util.run_capture({"ls", "-l"})
  defer delete(out)
  // log.info(err, out)
  testing.expect_value(t, err, false)
}

@(test)
test_run_capture_failure :: proc(t: ^testing.T) {
  out, err := util.run_capture({"ls", "--ERR"})
  defer delete(out)
  // log.info(err, out)
  testing.expect_value(t, err, true)
}
