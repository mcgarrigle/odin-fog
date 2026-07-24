package template

import "core:fmt"
import "core:strings"
import "core:reflect"

// ----------------------------------------------------------------------

@(private)
varname :: proc(name: string) -> string {
  return strings.concatenate({"${", name, "}"})
}

@(private)
get_string_field :: proc(s : any, field_name: string) -> string {
  value := reflect.struct_field_value_by_name(s, field_name)
  return value.(string)
}

render :: proc(text: string, s: $T) -> string {
  result := text
  for name in reflect.struct_field_names(typeid_of(T)) {
    value := get_string_field(s, name)
    result, _ = strings.replace_all(result, varname(name), value)
  }
  return result
}
