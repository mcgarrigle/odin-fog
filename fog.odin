package main

import "core:fmt"
import "core:os"

run :: proc (args: []string) {
  command := os.Process_Desc{command=args}

  state, stdout, stderr, err := os.process_exec(desc=command, allocator=context.allocator)
  if err != nil {
        fmt.panicf("Failed to start command: %v", err)
  }
  fmt.println(string(stdout))
}

command_up :: proc(args: []string) {
	fmt.println("command up")
  fmt.println(args)
  run({"echo", "Hello, World 😉"})
}

command_down :: proc(args: []string) {
	fmt.println("command down")
  fmt.println(args)
}

dispatch :: proc(args: []string) {
  fmt.println(args)
  switch args[0] {
  case "up":
    command_up(args[1:])
  case "down":
    command_down(args[1:])
  case: 
	  fmt.println("unknown command")
  }
}

main :: proc() {
	fmt.println("fog")
  dispatch(os.args[1:])
}
