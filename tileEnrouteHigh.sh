#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=enroute

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


alaska_chart_list=()

chart_list=(
ENR_AKH01_SEA ENR_AKH01 ENR_AKH02 
ENR_H01 ENR_H02 ENR_H03 ENR_H04 ENR_H05 
ENR_H06 ENR_H07 ENR_H08 ENR_H09 ENR_H10 ENR_H11 ENR_H12 
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
        
    #Optimize the tiled png files
    ./pngquant_all_files_in_directory.sh $destDir/$chart.tms
    
    #Package them into an .mbtiles file
    ./memoize.py \
        python ./mbutil/mb-util \
            --scheme=tms \
            $destDir/$chart.tms \
            $destinationRoot/mbtiles/$chart.mbtiles
            
  done

# #Create a list of directories of this script's type
# directories=$(find "$destDir" -type d \( -name "ENR_H*" -o -name "ENR_AKH*" \) | sort)
# 
# echo $directories
# 
# #Optimize the tiled png files
# for directory in $directories
# do
#     ./pngquant_all_files_in_directory.sh $directory
# done

# #Merge all of those directory's tiles together and store in a separate directory
# ./memoize.py -i $destDir \
#     ./tilers_tools/tiles_merge.py \
#     $directories \
#     "./merged_tiles/$chartType-high"