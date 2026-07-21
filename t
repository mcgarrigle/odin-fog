#!/usr/bin/bash

clear

source t9-rocky-10.def

odin build fog.odin -file 
if [ $? = "0" ]; then
  ./fog up this
fi
