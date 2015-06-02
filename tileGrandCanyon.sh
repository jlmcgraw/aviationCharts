#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#The base type of chart we're processing in this script
chartType=grand_canyon

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

chart_list=(
Grand_Canyon_General_Aviation
Grand_Canyon_Air_Tour_Operators
U.S._VFR_Wall_Planning_Chart
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
directories=$(find "$destDir" -type d \( -name "*Grand_Canyon*" -o -name "*_VFR_Wall_Planning_Chart*" \) | sort)

echo $directories

./memoize.py \
    ./tilers_tools/tiles_merge.py \
        $directories \
        ./$chartType
