#!/usr/bin/bash

clear

source t9-rocky-10.def

if [ "$1" = "-t" ]; then
  # OS variables are global shared state so run tests in single thread
  odin test lib -collection:project=./lib -all-packages \
    -define:ODIN_TEST_THREADS=1 \
    -define:ODIN_TEST_RANDOM_SEED=1971089818485440 
else
  ./c $1 || exit 1
  ./fog up this
fi
