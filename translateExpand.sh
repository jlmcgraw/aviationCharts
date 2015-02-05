#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Expand this chart (if necessary, enroute charts don't currently need) to RGB bands
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

#Test if we need to expand the original file
if [ ! -f "$expandedRastersDirectory/$sourceChartName.tif" ];
  then
    echo --- Expand --- gdal_translate $sourceChartName

    if [ $chartType == "enroute" ];  then
	echo "Enroute chart"
    	gdal_translate \
	    -strict \
	    -co TILED=YES \
	    -co COMPRESS=LZW \
	    "$linkedRastersDirectory/$sourceChartName.tif" \
	    "$expandedRastersDirectory/$sourceChartName.tif"
      else
	echo "Not an enroute chart"
	gdal_translate \
	    -strict \
	    -expand rgb \
	    -co TILED=YES \
	    -co COMPRESS=LZW \
	    "$linkedRastersDirectory/$sourceChartName.tif" \
	    "$expandedRastersDirectory/$sourceChartName.tif"
    fi
    #Create external overviews to make display faster in QGIS
    echo --- Overviews for Expanded File --- gdaladdo $sourceChartName             
    gdaladdo \
	  -ro \
	  -r average \
	  --config INTERLEAVE_OVERVIEW PIXEL \
	  --config COMPRESS_OVERVIEW JPEG \
	  --config BIGTIFF_OVERVIEW IF_NEEDED \
	  "$expandedRastersDirectory/$sourceChartName.tif" \
	  2 4 8 16 32 64
fi