#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"
chartType="$3"
sourceChartName="$4"
zoomRange="$5"

if [ "$#" -ne 5 ] ; then
  echo "Usage: $0 SOURCE_DIRECTORY destinationRoot chartType sourceChartName zoomRange" >&2
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

if [ ! -f  "$mbtilesDirectory/$sourceChartName.mbtiles" ];  then
  #BUG TODO Handle when these directories already exist
  #BUG TODO Some charts need to go to deeper layers than others

  #Create tiles from the clipped raster (various ways)
  #The multithreaded version does not currently auto-determine tiling levels
  # python ~/Documents/github/parallel-gdal2tiles/gdal2tiles.py $clippedRastersDirectory/$clippedName.tif $tilesDirectory/$sourceChartName
  # python ~/Documents/github/parallel-gdal2tiles/gdal2tiles/gdal2tiles.py $clippedRastersDirectory/$clippedName.tif $tilesDirectory/$sourceChartName
  ~/Documents/github/gdal2mbtiles/gdal2mbtiles.py -r lanczos --resume $clippedRastersDirectory/$sourceChartName.tif $tilesDirectory/$sourceChartName

  #Optimize each of those tiles using all CPUs
  # find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -execdir pngquant --ext=.png --force {} \;
  #Get the number of online CPUs
  cpus=$(getconf _NPROCESSORS_ONLN)

  echo "Sharpen PNGs, using $cpus CPUS"
#   find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus gm mogrify -unsharp 2x1.5+1.7+0
  find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus gm mogrify -sharpen 0x.5
  
  echo "Optimize PNGs, using $cpus CPUS"
  find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus pngquant -s2 -q 100 --ext=.png --force

  
  

  #Package them into an .mbtiles file
  ~/Documents/github/mbutil/mb-util --scheme=tms $tilesDirectory/$sourceChartName/ $mbtilesDirectory/$sourceChartName.mbtiles

#   #Set the date of this new mbtiles to the date of the chart used to create it
#   touch -r "$linkedRastersDirectory/$sourceChartName.tif" $mbtilesDirectory/$sourceChartName.mbtiles
fi