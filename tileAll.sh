#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Where to put tile directories
destDir="./individual_tiled_charts"

#Determine the full path to where this script is
#Use this as the root of directories where our processed images etc will be saved
pushd `dirname $0` > /dev/null
destinationRoot=`pwd`
popd > /dev/null


#Use "tilers_tools" to create tiled versions
./tileEnrouteHigh.sh $destDir
./tileEnrouteLow.sh $destDir
./tileGrandCanyon.sh $destDir
./tileHeli.sh $destDir
./tileSectional.sh $destDir
./tileTac.sh $destDir
./tileWac.sh $destDir