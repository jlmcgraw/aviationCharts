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

 
    expandedName=expanded-$sourceChartName
    clippedName=clipped-$expandedName
  
    if [ ! -f "$clippingShapesDirectory/$sourceChartName.shp" ];
      then
	echo ---No clipping shape found: "$clippingShapesDirectory/$sourceChartName.shp"
	exit 1
    fi
    
    #Warp the original file, clipping it to it's clipping shape
    echo --- Clip --- gdalwarp $sourceChartName
    gdalwarp \
             -cutline "$clippingShapesDirectory/$sourceChartName.shp" \
             -crop_to_cutline \
             -dstalpha \
             -of GTiff \
             -cblend 15 \
             -t_srs EPSG:3857 \
             -multi \
             -wo NUM_THREADS=ALL_CPUS  \
             -overwrite \
             -wm 1024 \
             -co TILED=YES \
             -co COMPRESS=LZW \
             "$expandedRastersDirectory/$expandedName.tif" \
             "$clippedRastersDirectory/$clippedName.tif"
    
    #Create external overviews to make display faster in QGIS
    echo --- Add overviews --- gdaladdo $sourceChartName             
    gdaladdo \
             -ro \
             --config INTERLEAVE_OVERVIEW PIXEL \
             --config COMPRESS_OVERVIEW JPEG \
             --config BIGTIFF_OVERVIEW IF_NEEDED \
             "$clippedRastersDirectory/$clippedName.tif" \
             2 4 8 16