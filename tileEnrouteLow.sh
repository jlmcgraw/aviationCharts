#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

destDir="./tiles2"
chartType=enroute

alaska_chart_list=(
)

chart_list=(
ENR_AKL01 ENR_AKL02C ENR_AKL02E ENR_AKL02W ENR_AKL03 ENR_AKL04
ENR_L01 ENR_L02 ENR_L03 ENR_L04 ENR_L05 ENR_L06N ENR_L06S ENR_L07 ENR_L08
ENR_L09 ENR_L10 ENR_L11 ENR_L12 ENR_L13 ENR_L14 ENR_L15 ENR_L16 ENR_L17
ENR_L18 ENR_L19 ENR_L20 ENR_L21 ENR_L22 ENR_L23 ENR_L24 ENR_L25 ENR_L26
ENR_L27 ENR_L28 ENR_L29 ENR_L30 ENR_L31 ENR_L32 ENR_L33 ENR_L34 ENR_L35
ENR_L36
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
      --zoom=0,1,2,3,4,5,6,7,8,9,10,11,12 \
      ~/Documents/myPrograms/mergedCharts/warpedRasters/$chartType/$chart.tif
  done

directories=$(find "$destDir" -type d \( -name "ENR_L*" -o -name "ENR_AKL*" \)| sort)

echo $directories

./memoize.py \
./tilers_tools/tiles_merge.py \
  $directories \
  "./$chartType-low"