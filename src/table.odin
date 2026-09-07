package main

import "core:fmt"
import "core:io"
import "core:strings"
import "core:strconv"
import "core:text/table"

Format :: enum {
  ASCII,
  Lines,
  Simple,
  None
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
    for col in 0..<tbl.nr_cols {
      cell := table.get_cell(tbl, row, col)
      io.write_string(w, cell.text)
      io.write_byte(w, '\t')
    }
    io.write_byte(w, '\n')
  }
}

render_table :: proc(tbl: ^table.Table, format: Format = .Lines) {
  table.padding(tbl, 1, 1)
  stdout := table.stdio_writer()
  switch format {
  case .ASCII: 
    table.write_plain_table(stdout, tbl)
  case .Lines:
    table.write_decorated_table(stdout, tbl, decorations)
  case .Simple:
    write_simple_table(stdout, tbl)
  case .None:
    table.padding(tbl, 0, 0)
    write_stream_table(stdout, tbl)
  }
}
