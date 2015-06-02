#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#The base type of chart we're processing in this script
chartType=heli

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
Baltimore_HEL
Boston_Downtown_HEL
Boston_HEL
Chicago_HEL
Chicago_O\'Hare_Inset_HEL
Dallas-Ft_Worth_HEL
Dallas-Love_Inset_HEL
Detroit_HEL
Downtown_Manhattan_HEL
Eastern_Long_Island_HEL
Houston_North_HEL
Houston_South_HEL
Los_Angeles_East_HEL
Los_Angeles_West_HEL
New_York_HEL
U.S._Gulf_Coast_HEL
Washington_HEL
Washington_Inset_HEL
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
directories=$(find "$destDir" -type d -name "*_HEL*" | sort)

echo $directories

./memoize.py \
    ./tilers_tools/tiles_merge.py \
        $directories \
        ./$chartType