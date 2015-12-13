#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=insets

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


chart_list=(
    Dutch_Harbor_Inset
    Jacksonville_Inset
    Juneau_Inset
    Ketchikan_Inset
    Kodiak_Inset
    Norfolk_Inset
    Pribilof_Islands_Inset
    )

for chart in "${chart_list[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
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
    
    #Copy the simple viewer to our tiled directory
    cp leaflet.html $destDir/$chart.tms/
    
    done






















