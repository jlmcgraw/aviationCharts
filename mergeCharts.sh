#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=wac

#Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 DESTINATION_DIRECTORY" >&2
  exit 1
fi

#Get command line parameters
destinationRoot="$1"

#Where to put tiled charts (each in its own directory)
destDir="$destinationRoot/individual_tiled_charts"

#Check that the destination directory exists
if [ ! -d $destDir ]; then
    echo "$destDir doesn't exist"
    exit 1
fi

#Charts that are at 1:1,000,000 scale
wac_chart_list=(
CC-8_WAC CC-9_WAC CD-10_WAC CD-11_WAC CD-12_WAC CE-12_WAC CE-13_WAC CE-15_WAC
CF-16_WAC CF-17_WAC CF-18_WAC CF-19_WAC CG-18_WAC CG-19_WAC CG-20_WAC CG-21_WAC
CH-22_WAC CH-23_WAC CH-24_WAC CH-25_WAC CJ-26_WAC CJ-27_WAC
)

for chart in "${wac_chart_list[@]}"
  do
  echo $chart

  ./merge_tile_sets.pl \
    /media/sf_Shared_Folder/individual_tiled_charts/$chart.tms/ \
    ./tile_merging_test/WAC
  done


#Charts that are at 1:500,000 scale
sec_chart_list=(
Albuquerque_SEC Anchorage_SEC Atlanta_SEC Bethel_SEC Billings_SEC
Brownsville_SEC Cape_Lisburne_SEC Charlotte_SEC Cheyenne_SEC Chicago_SEC
Cincinnati_SEC Cold_Bay_SEC Dallas-Ft_Worth_SEC Dawson_SEC Denver_SEC
Detroit_SEC Dutch_Harbor_SEC El_Paso_SEC Fairbanks_SEC Great_Falls_SEC
Green_Bay_SEC Halifax_SEC Hawaiian_Islands_SEC Houston_SEC
Jacksonville_SEC Juneau_SEC Kansas_City_SEC Ketchikan_SEC Klamath_Falls_SEC
Kodiak_SEC Lake_Huron_SEC Las_Vegas_SEC Los_Angeles_SEC 
McGrath_SEC Memphis_SEC Miami_SEC Montreal_SEC New_Orleans_SEC New_York_SEC
Nome_SEC Omaha_SEC Phoenix_SEC Point_Barrow_SEC Salt_Lake_City_SEC
San_Antonio_SEC San_Francisco_SEC Seattle_SEC
Seward_SEC St_Louis_SEC Twin_Cities_SEC Washington_SEC
Western_Aleutian_Islands_East_SEC Western_Aleutian_Islands_West_SEC
Whitehorse_SEC Wichita_SEC
)

for chart in "${sec_chart_list[@]}"
  do
  echo $chart  
  ./merge_tile_sets.pl \
    /media/sf_Shared_Folder/individual_tiled_charts/$chart.tms/ \
    ./tile_merging_test/SEC
  done

#Charts that are at 1:250,000 scale
tac_chart_list=(
  Honolulu_Inset_SEC
  Mariana_Islands_Inset_SEC
  Samoan_Islands_Inset_SEC
)

for chart in "${tac_chart_list[@]}"
  do
  echo $chart
  
  ./merge_tile_sets.pl \
    /media/sf_Shared_Folder/individual_tiled_charts/$chart.tms/ \
    ./tile_merging_test/TAC
  done
