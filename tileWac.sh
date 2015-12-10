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

chart_list=(
CC-8_WAC CC-9_WAC CD-10_WAC CD-11_WAC CD-12_WAC CE-12_WAC CE-13_WAC CE-15_WAC
CF-16_WAC CF-17_WAC CF-18_WAC CF-19_WAC CG-18_WAC CG-19_WAC CG-20_WAC CG-21_WAC
CH-22_WAC CH-23_WAC CH-24_WAC CH-25_WAC CJ-26_WAC CJ-27_WAC
)

# I'd experimented with doing the cutting here but there seems to be a bug in this process
#       --cut \
#       --cutline=/home/jlmcgraw/Documents/myPrograms/mergedCharts/clippingShapes/$chartType/$chart.shp \
#       
for chart in "${chart_list[@]}"
  do
  echo $chart
  
  ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=0,1,2,3,4,5,6,7,8,9 \
        --dest-dir="$destDir" \
        $destinationRoot/warpedRasters/$chartType/$chart.tif
        
    #Optimize the tiled png files
    ./pngquant_all_files_in_directory.sh $destDir/$chart.tms
    
    #Package them into an .mbtiles file
    ./memoize.py -i $destDir \
        python ./mbutil/mb-util \
            --scheme=tms \
            $destDir/$chart.tms \
            $destinationRoot/mbtiles/$chart.mbtiles
            
  done

# #Create a list of directories of this script's type
# directories=$(find "$destDir" -type d -name "*_WAC*" | sort)
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