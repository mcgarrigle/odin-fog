#!/usr/bin/bash

clear

source t9-rocky-10.def

if [ "$1" = "-t" ]; then
  odin test lib -collection:project=./lib -all-packages
else
  ./c $1 || exit 1
  ./fog up this
fi
