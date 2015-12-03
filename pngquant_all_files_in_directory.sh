#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

#Get command line parameters
destDir="$1"

#Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 DESTINATION_DIRECTORY" >&2
  exit 1
fi

#Get the number of online CPUs
cpus=$(getconf _NPROCESSORS_ONLN)

sizeBeforeOptimization=$(du -s -h $destDir)

#Optimize all of the .png tiles
echo "Optimize PNGs in $destDir with pngquant, using $cpus CPUS"
find $destDir -type f -iname "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus pngquant -s2 -q 100 --ext=.png --force

sizeAfterOptimization=$(du -s -h $destDir)

echo "$destDir: Size before: $sizeBeforeOptimization, size after: $sizeAfterOptimization"
