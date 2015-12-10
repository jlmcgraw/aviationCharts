#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=enroute

#Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 <DESTINATION_BASE_DIRECTORY>" >&2
  echo "    -o  Optimize tiles"
  echo "    -m  Create mbtiles file"
  exit 1
fi

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

#Get command line parameters
destinationRoot="$1"

#Where to put tiled charts (each in its own directory)
destDir="$destinationRoot/individual_tiled_charts"

#Check that the destination directory exists
if [ ! -d $destDir ]; then
    echo "$destDir doesn't exist"
    exit 1
fi



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