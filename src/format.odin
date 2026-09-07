package main

import "core:fmt"
import "core:strconv"


format_enabled :: proc(state: i32) -> string {
  if state == 0 do return "disabled"
  return "enabled"
}

format_bytes :: proc(bytes: u64) -> string {
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
  buf := make([]byte, 10)
  buf[0] = '-'
  if id == -1 do return string(buf)
  return strconv.write_int(buf[:], i64(id), 10)
}
