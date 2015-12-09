#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=tac

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
  
  ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=7,8,9,10,11,12 \
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
# directories=$(find "$destDir" -type d -name "*_TAC*" | sort)
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
