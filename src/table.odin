package main

import "core:fmt"
import "core:os"
import "core:io"
import "core:strings"
import "core:strconv"
import "core:terminal"
import "core:text/table"

Format :: enum {
  Plain,
  Decorated,
  Simple,
  Stream
}

decorations :: table.Decorations {
  "┌", "┬", "┐",
  "├", "┼", "┤",
  "└", "┴", "┘",
  "│", "─",
}

// --------------------------------------------------------------

write_simple_table :: proc(w: io.Writer, tbl: ^table.Table, width_proc: table.Width_Proc = table.unicode_width_proc) {
  table.build(tbl, width_proc)

  width := 0
  for col in 0..<tbl.nr_cols {
    width = width + tbl.colw[col] + tbl.lpad + tbl.rpad
  }

  for row in 0..<tbl.nr_rows {
    for col in 0..<tbl.nr_cols {
      table.write_table_cell(w, tbl, row, col)
    }
    io.write_byte(w, '\n')
    if tbl.has_header_row && row == table.header_row(tbl) {
      table.write_byte_repeat(w, width, '-')
      io.write_byte(w, '\n')
    }
  }
}

write_stream_table :: proc(w: io.Writer, tbl: ^table.Table, width_proc: table.Width_Proc = table.unicode_width_proc) {
  table.build(tbl, width_proc)
  for row in 0..<tbl.nr_rows {
    cell := table.get_cell(tbl, row, 0)
    io.write_string(w, cell.text)
    for col in 1..<tbl.nr_cols {
      io.write_byte(w, '\t')
      cell = table.get_cell(tbl, row, col)
      io.write_string(w, cell.text)
    }
    io.write_byte(w, '\n')
  }
}

table_format :: proc(format: Format) -> (Format, bool) {
  format := format if terminal.is_terminal(os.stdout) else Format.Stream
  units  := format != Format.Stream
  return format, units
}

render_table :: proc(tbl: ^table.Table, format: Format = .Decorated) {
  stdout := table.stdio_writer()
  table.padding(tbl, 1, 1)
  switch format {
  case .Plain: 
    table.write_plain_table(stdout, tbl)
  case .Decorated:
    table.write_decorated_table(stdout, tbl, decorations)
  case .Simple:
    write_simple_table(stdout, tbl)
  case .Stream:
    table.padding(tbl, 0, 0)
    write_stream_table(stdout, tbl)
  }
}
