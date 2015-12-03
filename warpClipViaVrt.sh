#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

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

# gdal_root="/home/jlmcgraw/Documents/github/gdal/gdal"

export GML_FETCH_ALL_GEOMETRIES=YES
export GML_SKIP_RESOLVE_ELEMS=NONE
# export GDAL_DATA="$gdal_root/data"
# export LD_LIBRARY_PATH=/usr/lib
# export PROJSO=/usr/lib/libproj.so.0

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

#memoize is a neat way of only re-running when input data has changed
#see https://github.com/kgaughan/memoize.py

#1) Clip the source file first then 
#2) warp to EPSG:3857 so that final output pixels are square
#----------------------------------------------

#Clip the file it to it's clipping shape
echo "*** Clip to vrt --- gdalwarp $sourceChartName"
#BUG TODO crop_to_cutline results in a resampled image with non-square pixels
#How to best handle this?  One fix is an additional warp to EPSG:3857
#Do I need -dstalpha here?  That adds a band, I just want to re-use the existing one
time \
nice -10 \
    ./memoize.py -t \
        gdalwarp \
                -of vrt \
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
                "$clippedRastersDirectory/$sourceChartName.vrt"

#Warp the expanded file
echo "*** Warp to vrt --- gdalwarp $sourceChartName"
time \
nice -10 \
    ./memoize.py  -t \
        gdalwarp \
                -of vrt \
                -t_srs EPSG:3857 \
                -r lanczos \
                -overwrite \
                -multi \
                -wo NUM_THREADS=ALL_CPUS  \
                -wm 1024 \
                --config GDAL_CACHEMAX 1024 \
                -co TILED=YES \
                "$clippedRastersDirectory/$sourceChartName.vrt" \
                "$warpedRastersDirectory/$sourceChartName.vrt"

echo "***  Create tif --- gdal_translate $sourceChartName"
#If you want to make the files smaller, at the expense of CPU, you can enable these options
#      -co COMPRESS=DEFLATE \
#      -co PREDICTOR=1 \
#      -co ZLEVEL=9 \
# or do just:
#       -co COMPRESS=LZW \
time \
nice -10 \
    ./memoize.py -t \
        gdal_translate \
            -strict \
            -co TILED=YES \
            -co COMPRESS=DEFLATE \
            -co PREDICTOR=1 \
            -co ZLEVEL=9 \
            --config GDAL_CACHEMAX 1024 \
            "$warpedRastersDirectory/$sourceChartName.vrt" \
            "$warpedRastersDirectory/$sourceChartName.tif"


#Create external overviews to make display faster in QGIS
echo "***  Overviews --- gdaladdo $sourceChartName"
time \
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
        