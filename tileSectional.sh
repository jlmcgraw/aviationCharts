#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

destDir="./tiles2"

chartType=sectional

chart_list=(
Albuquerque_SEC Anchorage_SEC Atlanta_SEC Bethel_SEC Billings_SEC
Brownsville_SEC Cape_Lisburne_SEC Charlotte_SEC Cheyenne_SEC Chicago_SEC
Cincinnati_SEC Cold_Bay_SEC Dallas-Ft_Worth_SEC Dawson_SEC Denver_SEC
Detroit_SEC Dutch_Harbor_SEC El_Paso_SEC Fairbanks_SEC Great_Falls_SEC
Green_Bay_SEC Halifax_SEC Hawaiian_Islands_SEC Honolulu_Inset_SEC Houston_SEC
Jacksonville_SEC Juneau_SEC Kansas_City_SEC Ketchikan_SEC Klamath_Falls_SEC
Kodiak_SEC Lake_Huron_SEC Las_Vegas_SEC Los_Angeles_SEC Mariana_Islands_Inset_SEC
McGrath_SEC Memphis_SEC Miami_SEC Montreal_SEC New_Orleans_SEC New_York_SEC
Nome_SEC Omaha_SEC Phoenix_SEC Point_Barrow_SEC Salt_Lake_City_SEC
Samoan_Islands_Inset_SEC San_Antonio_SEC San_Francisco_SEC Seattle_SEC
Seward_SEC St_Louis_SEC Twin_Cities_SEC Washington_SEC
Western_Aleutian_Islands_East_SEC Western_Aleutian_Islands_West_SEC
Whitehorse_SEC Wichita_SEC
)
#       --cut \
#       --cutline=/home/jlmcgraw/Documents/myPrograms/mergedCharts/clippingShapes/$chartType/$chart.shp \
      
for chart in "${chart_list[@]}"
  do
  echo $chart
  
  ./memoize.py \
  ./tilers_tools/gdal_tiler.py \
      --release \
      --paletted \
      --dest-dir="$destDir" \
      --noclobber \
      --zoom=8,9,10,11,12 \
      ~/Documents/myPrograms/mergedCharts/warpedRasters/$chartType/$chart.tif
  done

directories=$(find "$destDir" -type d -name "*_SEC*" | sort)

echo $directories

./memoize.py \
    ./tilers_tools/tiles_merge.py \
    $directories \
    ./$chartType




















