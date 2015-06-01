#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

destDir="./tiles2"

chartType=grand_canyon

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

directories=$(find "$destDir" -type d \( -name "*Grand_Canyon*" -o -name "*_VFR_Wall_Planning_Chart*" \) | sort)

echo $directories

./memoize.py \
    ./tilers_tools/tiles_merge.py \
    $directories \
    ./$chartType
