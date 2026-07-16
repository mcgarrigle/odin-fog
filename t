#!/usr/bin/bash

clear

source ~/projects/docker-odin/setup.sh
source t1-rocky-10.def

odin build fog.odin -file 
if [ $? = "0" ]; then
  ./fog up this
fi
