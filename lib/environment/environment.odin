package environment

import "core:fmt"
import "core:os"
import "core:log"
import "core:reflect"

import "project:util"

extract :: proc(s: ^$T) {
  fields := reflect.struct_fields_zipped(T)
  for field in fields {
    if len(field.tag) > 0 {
      value := util.get_env(string(field.tag))
      _ = util.set_string_field(s^, field.name, value)
      // log.info(field.name, field.tag, "'", value, "'")
    }
  }
}
