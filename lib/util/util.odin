package util

import "core:fmt"
import "core:os"
import "core:math/rand"
import "core:strings"
import "core:reflect"

DEBUG :: #config(DEBUG, false)

// --------------------------------------------------------------

get_env :: proc(key: string, default: string = "") -> string {
  value := os.get_env(key, context.allocator)
  if value == "" {
    return strings.clone(default, context.allocator)  // clone default so delete() can be used in a consistent manner
  }
  return value
}

// --------------------------------------------------------------

strcat :: proc(list: ..string) -> string {
  return strings.concatenate(list)
}

// --------------------------------------------------------------
// run commands

run_capture :: proc(args: []string) -> (result : string, err: bool) #optional_ok {
  command := os.Process_Desc{command=args}
  state, stdout, stderr, _ := os.process_exec(command, context.allocator)
  if state.exit_code == 0 {
    return string(stdout), false
  } else {
    return string(stderr), true
  }
}

run_slice :: proc(args: []string) {
  when DEBUG {
    fmt.println(args)
  } else {
    out, err := run_capture(args)
    fmt.println(out)
    if err do os.exit(1)
  }
}

run :: proc(args: ..string) {
  run_slice(args)
}

// --------------------------------------------------------------

tempfile :: proc(prefix: string = "tmp") -> string {
  temp, _ := os.temp_directory(context.allocator)
  defer delete(temp)
  return fmt.aprintf("%s/%s.%x", temp, prefix, rand.uint64())
}

// --------------------------------------------------------------
// support (de)serialisation of structs

get_string_field :: proc(s : any, field_name: string) -> string {
  value := reflect.struct_field_value_by_name(s, field_name)
  return value.(string)
}

set_string_field :: proc(v: $T, field_name: string, value: string) -> bool {
  field := reflect.struct_field_by_name(typeid_of(T), field_name)
  if field.name == "" || !reflect.is_string(field.type) {
    return false
  }
  p: any = v
  dst := (^string)(rawptr(uintptr(p.data) + field.offset))
  dst^ = value
  return true
}
