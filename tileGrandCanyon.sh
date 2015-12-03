#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=grand_canyon

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

chart_list=(
Grand_Canyon_General_Aviation
Grand_Canyon_Air_Tour_Operators
U.S._VFR_Wall_Planning_Chart
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
# directories=$(find "$destDir" -type d \( -name "*Grand_Canyon*" -o -name "*_VFR_Wall_Planning_Chart*" \) | sort)
# 
# echo $directories
# 
# #Optimize the tiled png files
# for directory in $directories
# do
#     ./pngquant_all_files_in_directory.sh $directory
# done



# ./memoize.py -i $destDir \
#     ./tilers_tools/tiles_merge.py \
#         $directories \
#         ./merged_tiles/$chartType
        
        

