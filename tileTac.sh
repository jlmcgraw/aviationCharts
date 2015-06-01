#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

destDir="./tiles2"

chartType=tac

chart_list=(
Anchorage_TAC Atlanta_TAC Baltimore-Washington_TAC Boston_TAC Charlotte_TAC
Chicago_TAC Cincinnati_TAC Cleveland_TAC Colorado_Springs_TAC Dallas-Ft_Worth_TAC
Denver_TAC Detroit_TAC Fairbanks_TAC Houston_TAC Kansas_City_TAC Las_Vegas_TAC
Los_Angeles_TAC Memphis_TAC Miami_TAC Minneapolis-St_Paul_TAC New_Orleans_TAC
New_York_TAC Orlando_TAC Philadelphia_TAC Phoenix_TAC Pittsburgh_TAC
Puerto_Rico-VI_TAC Salt_Lake_City_TAC San_Diego_TAC San_Francisco_TAC Seattle_TAC
St_Louis_TAC Tampa_TAC
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
      --zoom=12,13 \
      ~/Documents/myPrograms/mergedCharts/warpedRasters/$chartType/$chart.tif
  done

directories=$(find "$destDir" -type d -name "*_TAC*" | sort)

echo $directories

./memoize.py \
    ./tilers_tools/tiles_merge.py \
    $directories \
    ./$chartType
