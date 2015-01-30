#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

baseDirs=(sourceRasters expandedRasters clippingShapes warpedRasters clippedRasters tiles mbtiles)
chartTypes=(enroute grand_canyon heli sectional tac wac)

#Create the tree of output directories  
for DIR in ${baseDirs[@]};  do
    for CHARTTYPE in ${chartTypes[@]}; do
#         echo $DIR/$CHARTTYPE
        mkdir -p ./$DIR/$CHARTTYPE
      done
  done