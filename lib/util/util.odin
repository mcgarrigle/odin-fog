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
  if value == "" do return default
  return value
}

// --------------------------------------------------------------

strcat :: proc(list: ..string) -> string {
  return strings.concatenate(list)
}

// --------------------------------------------------------------
// run commands

run_slice :: proc(args: []string) {
  fmt.println(args)
  when !DEBUG {
    command := os.Process_Desc{command=args}
    state, stdout, stderr, err := os.process_exec(command, context.allocator)
    if err != nil {
      fmt.panicf("Failed to start command: %v", err)
    }
    fmt.println(string(stdout))
  }
}

run :: proc(args: ..string) {
  run_slice(args)
}

// --------------------------------------------------------------

tempfile :: proc() -> string {
  return fmt.aprintf("/tmp/fog.%x", rand.uint64())
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
