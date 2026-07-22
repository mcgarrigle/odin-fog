#!/usr/bin/bash

clear

if [ "$1" = "-d" ]; then
  odin build fog.odin -file -define:DEBUG=true
else
  odin build fog.odin -file
fi

exit $?
