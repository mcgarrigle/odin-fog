package environment

import "core:fmt"
import "core:os"
import "core:strings"
import "core:reflect"

import "project:util"


// ------------------------------------------------------------------

@(private)
value :: proc(tag: string) -> string {
  if tag == "" do return ""
  parts := strings.split(tag, ":")
  defer delete(parts)
  if len(parts) == 1 {
    return util.get_env(parts[0])
  } else {
    return util.get_env(parts[0], parts[1])
  }
}

// ------------------------------------------------------------------
// public

extract :: proc(s: ^$T) {
  fields := reflect.struct_fields_zipped(T)
  for field in fields {
    if len(field.tag) > 0 {
      v := value(string(field.tag))
      _ = util.set_string_field(s^, field.name, v)
    }
  }
}

environment_delete :: proc(s: $T) {
  fields := reflect.struct_fields_zipped(T)
  for field in fields {
    v := util.get_string_field(s, field.name)
    delete(v)
  }
}
