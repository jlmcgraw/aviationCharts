#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

echo "Optimization disabled for now, just to speed things up"
exit 0

# Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 DESTINATION_DIRECTORY" >&2
  exit 1
fi

# Get command line parameters
destDir="$1"

# Get the number of online CPUs
cpus=$(getconf _NPROCESSORS_ONLN)

# Get the size of the dir before
sizeBeforeOptimization=$(du -s -h "$destDir" | awk '{print $1;}' )

# Optimize all of the .png tiles
echo "Optimize PNGs in $destDir with pngquant, using $cpus CPUS"

find                        \
    "$destDir"              \
    -type f                 \
    -iname "*.png"          \
    -print0                 \
    | xargs                 \
        --null              \
        --max-args=10       \
        --max-procs="$cpus" \
        pngquant            \
            -s2             \
            -q 100          \
            --ext=.png      \
            --force

# Get the size of the dir after
sizeAfterOptimization=$(du -s -h "$destDir" | awk '{print $1;}' )

echo "$destDir: $sizeBeforeOptimization -> $sizeAfterOptimization"
