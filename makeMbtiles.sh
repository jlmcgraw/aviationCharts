#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"
chartType="$3"
sourceChartName="$4"

if [ "$#" -ne 4 ] ; then
  echo "Usage: $0 SOURCE_DIRECTORY destinationRoot chartType sourceChartName" >&2
  exit 1
fi

#Where the links to the lastest version #will be stored (step 1)
linkedRastersDirectory="$destinationRoot/sourceRasters/$chartType/"

#Where expanded rasters are stored (step 2)
expandedRastersDirectory="$destinationRoot/expandedRasters/$chartType/"

#Where clipped rasters are stored (step 3)
clippedRastersDirectory="$destinationRoot/clippedRasters/$chartType/"

#Where the polygons for clipping are stored
clippingShapesDirectory="$destinationRoot/clippingShapes/$chartType/"

#Where the tiles are stored
tilesDirectory="$destinationRoot/tiles/$chartType/"

#Where the mbtiles are stored
mbtilesDirectory="$destinationRoot/mbtiles/$chartType/"

if [ ! -d $originalRastersDirectory ]; then
    echo "$originalRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $linkedRastersDirectory ]; then
    echo "$linkedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $expandedRastersDirectory ]; then
    echo "$expandedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $clippedRastersDirectory ]; then
    echo "$clippedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $tilesDirectory ]; then
    echo "$tilesDirectory doesn't exist"
    exit 1
fi

if [ ! -d $mbtilesDirectory ]; then
    echo "$mbtilesDirectory doesn't exist"
    exit 1
fi

expandedName=expanded-$sourceChartName
clippedName=clipped-$expandedName

#BUG TODO Handle when these directories already exist
#BUG TODO Some charts need to go to deeper layers than others

#Create tiles from the clipped raster
~/Documents/github/gdal2mbtiles/gdal2mbtiles.py $clippedRastersDirectory/$clippedName.tif $tilesDirectory/$sourceChartName

#Optimize those tiles
# find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -execdir pngquant --ext=.png --force {} \;
#Get the number of online CPUs
cpus=$(getconf _NPROCESSORS_ONLN)
echo "Using $cpus CPUS"
find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus pngquant --ext=.png --force
#Package them into an .mbtiles file
~/Documents/github/mbutil/mb-util --scheme=tms $tilesDirectory/$sourceChartName/ $mbtilesDirectory/$sourceChartName.mbtiles
#Set the date of this new mbtiles to the date of the chart used to create it
touch -r "$linkedRastersDirectory/$sourceChartName.tif" $mbtilesDirectory/$sourceChartName.mbtiles