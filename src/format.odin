package main

import "core:fmt"
import "core:strconv"
import "core:strings"


format_enabled :: proc(state: i32) -> string {
  if state == 0 do return "disabled"
  return "enabled"
}

format_bytes :: proc(bytes: u64, units: bool=true) -> string {
  return format_byte_units(bytes) if units else fmt.aprintf("%d", bytes)
}

format_byte_units :: proc(bytes: u64) -> string {
  units := []string{ "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", }

  value := f64(bytes)
  unit := 0

  for value >= 1024.0 && unit < len(units)-1 {
    value /= 1024.0
    unit += 1
  }

  return fmt.aprintf("%.2f %s", value, units[unit])
}

format_id :: proc(id: i32) -> string {
  if id == -1 do return strings.clone("-")
  buf := make([]byte, 10)
  return strconv.write_int(buf[:], i64(id), 10)
}
