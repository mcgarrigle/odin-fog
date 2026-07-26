#!/usr/bin/bash

clear

if [ "$1" = "-d" ]; then
  odin build fog.odin -file -collection:project=./lib -define:DEBUG=true
else
  odin build fog.odin -file -collection:project=./lib
fi

exit $?
