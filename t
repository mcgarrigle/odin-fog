#!/usr/bin/bash

clear

source t9-rocky-10.def

./c $1

if [ $? = "0" ]; then
  ./fog up this
fi
