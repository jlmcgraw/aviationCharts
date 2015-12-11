#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=sectional

verbose='false'
optimize_tiles_flag=''
create_mbtiles_flag=''
list=''

while getopts 'oml:v' flag; do
  case "${flag}" in
    o) optimize_tiles_flag='true' ;;
    m) create_mbtiles_flag='true' ;;
    l) list="${OPTARG}" ;;
    v) verbose='true' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

#Remove the flag operands
shift $((OPTIND-1))

#Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 <DESTINATION_BASE_DIRECTORY>" >&2
  echo "    -o  Optimize tiles"
  echo "    -m  Create mbtiles file"
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

#Charts that are at 1:500,000 scale
chart_list_500000=(
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

      
for chart in "${chart_list_500000[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
        ./tilers_tools/gdal_tiler.py \
            --profile=tms \
            --release \
            --paletted \
            --zoom=0,1,2,3,4,5,6,7,8,9,10,11 \
            --dest-dir="$destDir" \
            $destinationRoot/warpedRasters/$chartType/$chart.tif
        
    if [ -n "$optimize_tiles_flag" ]
        then
            echo "Optimizing tiles for $chart"
            #Optimize the tiled png files
            ./pngquant_all_files_in_directory.sh $destDir/$chart.tms
        fi

    if [ -n "$create_mbtiles_flag" ]
        then
        echo "Creating mbtiles for $chart"
        #Delete any existing mbtiles file
        rm -f $destinationRoot/mbtiles/$chart.mbtiles
        
        #Package them into an .mbtiles file
        ./memoize.py -i $destDir \
            python ./mbutil/mb-util \
                --scheme=tms \
                $destDir/$chart.tms \
                $destinationRoot/mbtiles/$chart.mbtiles
        fi
            
    done

#Charts that are at 1:250,000 scale
chart_list_250000=(
    Honolulu_Inset_SEC
    Mariana_Islands_Inset_SEC
    Samoan_Islands_Inset_SEC
    )

for chart in "${chart_list_250000[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
        ./tilers_tools/gdal_tiler.py \
            --profile=tms \
            --release \
            --paletted \
            --zoom=0,1,2,3,4,5,6,7,8,9,10,11,12 \
            --dest-dir="$destDir" \
            $destinationRoot/warpedRasters/$chartType/$chart.tif
        
    if [ -n "$optimize_tiles_flag" ]
        then
            echo "Optimizing tiles for $chart"
            #Optimize the tiled png files
            ./pngquant_all_files_in_directory.sh $destDir/$chart.tms
        fi

    if [ -n "$create_mbtiles_flag" ]
        then
        echo "Creating mbtiles for $chart"
        #Delete any existing mbtiles file
        rm -f $destinationRoot/mbtiles/$chart.mbtiles
        
        #Package them into an .mbtiles file
        ./memoize.py -i $destDir \
            python ./mbutil/mb-util \
                --scheme=tms \
                $destDir/$chart.tms \
                $destinationRoot/mbtiles/$chart.mbtiles
        fi
    done





















