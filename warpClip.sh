#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#First create a version of this chart warped to EPSG:3857
#Then clip that warped version

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

#Where warped rasters are stored (step 2a)
warpedRastersDirectory="$destinationRoot/warpedRasters/$chartType/"

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
if [ ! -d $warpedRastersDirectory ]; then
    echo "$warpedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $clippedRastersDirectory ]; then
    echo "$clippedRastersDirectory doesn't exist"
    exit 1
fi

outputFormat="VRT"
outputExtension="vrt"
# outputFormat="GTiff"
# outputExtension="tif"

#memoize is a neat way of only re-running when input data has changed
#see https://github.com/kgaughan/memoize.py
#we're using -t to compare just via modification times since these files are large
#and also so we can truncate the temporary, uncompressed files and still not rebuild


#1) Clip the source file first then 2) warp to EPSG:3857 so that final output pixels are square
#----------------------------------------------

#Clip the file it to it's clipping shape
echo "*** Clip --- gdalwarp $sourceChartName"
#BUG TODO crop_to_cutline results in a resampled image with non-square pixels
#How to best handle this?  One fix is an additional warp to EPSG:3857
#Do I need -dstalpha here?  That adds a band, I just want to re-use the existing one
nice -10 \
./memoize.py -t \
gdalwarp \
	  -overwrite \
	  -cutline "$clippingShapesDirectory/$sourceChartName.shp" \
	  -crop_to_cutline \
	  -cblend 10 \
	  -r lanczos \
	  -dstalpha \
	  -co ALPHA=YES \
	  -co TILED=YES \
	  -multi \
	  -wo NUM_THREADS=ALL_CPUS  \
	  -wm 1024 \
	  --config GDAL_CACHEMAX 1024 \
	  "$expandedRastersDirectory/$sourceChartName.vrt" \
	  "$clippedRastersDirectory/$sourceChartName-uncompressed.tif"

# 	    "$warpedRastersDirectory/$sourceChartName.tif" \
# 	    "$clippedRastersDirectory/$sourceChartName-uncompressed.tif"

#Do this gdal_translate again to compress the output file.  Apparently gdalwarp doesn't really do it properly
echo "*** Compress --- gdal_translate $sourceChartName"
#If you want to make the files smaller, at the expense of CPU, you can enable these options
#      -co COMPRESS=DEFLATE \
#      -co PREDICTOR=1 \
#      -co ZLEVEL=9 \
nice -10 \
./memoize.py -t \
gdal_translate \
	  -strict \
	  -co COMPRESS=LZW \
	  -co TILED=YES \
	  --config GDAL_CACHEMAX 1024 \
	  "$clippedRastersDirectory/$sourceChartName-uncompressed.tif" \
	  "$clippedRastersDirectory/$sourceChartName.tif"
#Remove the huge temp file
#   rm "$clippedRastersDirectory/$sourceChartName-uncompressed.tif"
touch -r "$clippedRastersDirectory/$sourceChartName-uncompressed.tif" touchtemp.txt
mv touchtemp.txt "$clippedRastersDirectory/$sourceChartName-uncompressed.tif"

#Create external overviews to make display faster in QGIS      
echo "*** Overviews --- gdaladdo $sourceChartName"
nice -10 \
./memoize.py -t \
gdaladdo \
	  -ro \
	  -r average \
	  --config INTERLEAVE_OVERVIEW PIXEL \
	  --config COMPRESS_OVERVIEW JPEG \
	  --config BIGTIFF_OVERVIEW IF_NEEDED \
	  "$clippedRastersDirectory/$sourceChartName.tif" \
	  2 4 8 16 32 64

#Warp the expanded file
echo "*** Warp --- gdalwarp $sourceChartName"
nice -10 \
./memoize.py -t \
gdalwarp \
	  -t_srs EPSG:3857 \
	  -r lanczos \
	  -overwrite \
	  -multi \
	  -wo NUM_THREADS=ALL_CPUS  \
	  -wm 1024 \
	  --config GDAL_CACHEMAX 1024 \
	  -co TILED=YES \
	  "$clippedRastersDirectory/$sourceChartName.tif" \
	  "$warpedRastersDirectory/$sourceChartName-uncompressed.tif"
# 
# 	    "$expandedRastersDirectory/$sourceChartName.tif" \
# 	    "$warpedRastersDirectory/$sourceChartName-uncompressed.tif"

#Do this gdal_translate again to compress the output file.  Apparently gdalwarp doesn't really do it properly
echo "*** Compress --- gdal_translate $sourceChartName"
#If you want to make the files smaller, at the expense of CPU, you can enable these options
#      -co COMPRESS=DEFLATE \
#      -co PREDICTOR=1 \
#      -co ZLEVEL=9 \
nice -10 \
./memoize.py -t \
gdal_translate \
  -strict \
  -co COMPRESS=LZW \
  -co TILED=YES \
  --config GDAL_CACHEMAX 1024 \
  "$warpedRastersDirectory/$sourceChartName-uncompressed.tif" \
  "$warpedRastersDirectory/$sourceChartName.tif"

#Remove the original poorly compressed file
#   rm "$warpedRastersDirectory/$sourceChartName-uncompressed.tif"
touch -r "$clippedRastersDirectory/$sourceChartName-uncompressed.tif" touchtemp.txt
mv touchtemp.txt "$clippedRastersDirectory/$sourceChartName-uncompressed.tif"

#Create external overviews to make display faster in QGIS
echo "*** Overviews --- gdaladdo $sourceChartName"
nice -10 \
./memoize.py -t \
gdaladdo \
  -ro \
  -r average \
  --config INTERLEAVE_OVERVIEW PIXEL \
  --config COMPRESS_OVERVIEW JPEG \
  --config BIGTIFF_OVERVIEW IF_NEEDED \
  "$warpedRastersDirectory/$sourceChartName.tif" \
  2 4 8 16 32 64
