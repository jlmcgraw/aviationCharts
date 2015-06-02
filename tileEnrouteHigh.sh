#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#The base type of chart we're processing in this script
chartType=enroute

#Get command line parameters
destDir="$1"

#Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 DESTINATION_DIRECTORY" >&2
  exit 1
fi

#Check that the destination directory exists
if [ ! -d $destDir ]; then
    echo "$destDir doesn't exist"
    exit 1
fi


alaska_chart_list=()

chart_list=(
ENR_AKH01_SEA ENR_AKH01 ENR_AKH02 
ENR_H01 ENR_H02 ENR_H03 ENR_H04 ENR_H05 
ENR_H06 ENR_H07 ENR_H08 ENR_H09 ENR_H10 ENR_H11 ENR_H12 
)



for chart in "${chart_list[@]}"
  do
  echo $chart
  
  ./memoize.py \
    ./tilers_tools/gdal_tiler.py \
        --release \
        --paletted \
        --dest-dir="$destDir" \
        --noclobber \
        ~/Documents/myPrograms/mergedCharts/warpedRasters/$chartType/$chart.tif
  done

#Create a list of directories of this script's type
directories=$(find "$destDir" -type d \( -name "ENR_H*" -o -name "ENR_AKH*" \) | sort)

echo $directories

#Merge all of those directory's tiles together and store in a separate directory
./memoize.py \
    ./tilers_tools/tiles_merge.py \
    $directories \
    "./$chartType-high"