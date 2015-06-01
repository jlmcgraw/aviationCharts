#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

destDir="./tiles2"
chartType=enroute

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


directories=$(find "$destDir" -type d \( -name "ENR_H*" -o -name "ENR_AKH*" \) | sort)

echo $directories

./memoize.py \
./tilers_tools/tiles_merge.py \
  $directories \
  "./$chartType-high"