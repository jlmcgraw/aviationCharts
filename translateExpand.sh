#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Expand this chart (if necessary, enroute charts don't currently need) to RGB bands
#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"
chartType="$3"
sourceChartName="$4"

outputFormat="VRT"
outputExtension="vrt"
# outputFormat="GTiff"
# outputExtension="tif"

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

#memoize is a neat way of only re-running when input data has changed
#see https://github.com/kgaughan/memoize.py
#add the -t parameter to compare just using time if the default MD5 is too slow

#Test if we need to expand the original file
# if [ ! -f "$expandedRastersDirectory/$sourceChartName.$outputExtension" ];
#   then
    echo --- Expand --- gdal_translate $sourceChartName

    if [ $chartType == "enroute" ];  then
	echo "Enroute chart, don't expand to RGB"
	./memoize.py \
    	gdal_translate \
	    -strict \
	    -of $outputFormat \
	    -co TILED=YES \
	    -co COMPRESS=LZW \
	    "$linkedRastersDirectory/$sourceChartName.tif" \
	    "$expandedRastersDirectory/$sourceChartName.$outputExtension"
      else
	echo "Not an enroute chart, no need to expand"
	./memoize.py \
	gdal_translate \
	    -strict \
	    -of $outputFormat \
	    -expand rgb \
	    -co TILED=YES \
	    -co COMPRESS=LZW \
	    "$linkedRastersDirectory/$sourceChartName.tif" \
	    "$expandedRastersDirectory/$sourceChartName.$outputExtension"
    fi
    #Create external overviews to make display faster in QGIS
    echo "--- Overviews for Expanded File --- gdaladdo $sourceChartName"
    ./memoize.py \
    gdaladdo \
	  -ro \
	  -r gauss \
	  --config INTERLEAVE_OVERVIEW PIXEL \
	  --config COMPRESS_OVERVIEW JPEG \
	  --config BIGTIFF_OVERVIEW IF_NEEDED \
	  "$expandedRastersDirectory/$sourceChartName.$outputExtension" \
	  2 4 8 16 32 64
# fi