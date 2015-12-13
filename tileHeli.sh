#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=heli

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

#List of charts by their various scales
chart_list_1000=(
    U.S._Gulf_Coast_HEL
    )

chart_list_250=(
    Eastern_Long_Island_HEL
    )
        
chart_list_125=(
    Baltimore_HEL
    Boston_HEL
    Chicago_HEL
    Dallas-Ft_Worth_HEL
    Detroit_HEL
    Houston_North_HEL
    Houston_South_HEL
    Los_Angeles_East_HEL
    Los_Angeles_West_HEL
    New_York_HEL
    Washington_HEL
    )

chart_list_90=(
    Chicago_O\'Hare_Inset_HEL
    Dallas-Love_Inset_HEL    
    )

chart_list_62_5=(
    Washington_Inset_HEL
    )

chart_list_50=(
    Boston_Downtown_HEL
    Downtown_Manhattan_HEL
    )

for chart in "${chart_list_1000[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=0,1,2,3,4,5,6,7,8,9,10 \
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

for chart in "${chart_list_250[@]}"
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
    
    #Copy the simple viewer to our tiled directory
    cp leaflet.html $destDir/$chart.tms/
    
    done

for chart in "${chart_list_125[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=0,1,2,3,4,5,6,7,8,9,10,11,12,13 \
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

for chart in "${chart_list_90[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=0,1,2,3,4,5,6,7,8,9,10,11,12,13 \
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

for chart in "${chart_list_62_5[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14 \
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
  
for chart in "${chart_list_50[@]}"
    do
    echo $chart

    ./memoize.py -i $destDir \
    ./tilers_tools/gdal_tiler.py \
        --profile=tms \
        --release \
        --paletted \
        --zoom=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14 \
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
  