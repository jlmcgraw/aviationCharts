#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=heli

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
Baltimore_HEL
Boston_Downtown_HEL
Boston_HEL
Chicago_HEL
Chicago_O\'Hare_Inset_HEL
Dallas-Ft_Worth_HEL
Dallas-Love_Inset_HEL
Detroit_HEL
Downtown_Manhattan_HEL
Eastern_Long_Island_HEL
Houston_North_HEL
Houston_South_HEL
Los_Angeles_East_HEL
Los_Angeles_West_HEL
New_York_HEL
U.S._Gulf_Coast_HEL
Washington_HEL
Washington_Inset_HEL
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
# directories=$(find "$destDir" -type d -name "*_HEL*" | sort)
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