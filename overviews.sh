#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

for chart in sectional wac;
do
  echo $chart

  gdalbuildvrt \
    -resolution highest \
    $chart-overview.vrt \
    -srcnodata b4 \
    -hidenodata \
    -overwrite \
    ./clippedRasters/$chart/*.tif

  gdal_translate \
    -strict \
    -co TILED=YES \
    -co COMPRESS=LZW \
    -outsize 1024 768 \
    $chart-overview.vrt \
    $chart-translate.tif \

  #-te -120 37 -77 38 \
  gdalwarp \
    --debug on \
    -r lanczos \
    -ts 1024 768 \
    -co TWF=YES \
    $chart-overview.vrt \
    ./$chart-warp.tif \

done

for chart in enroute;
do
  echo $chart
  
  gdalbuildvrt \
    -resolution highest \
    $chart-low-overview.vrt \
    -srcnodata b4 \
    -hidenodata \
    -overwrite \
    ./clippedRasters/$chart/ENR_L*.tif

  gdal_translate \
    -strict \
    -co TILED=YES \
    -co COMPRESS=LZW \
    -outsize 1024 768 \
    $chart-low-overview.vrt \
    $chart-low-translate.tif \

  #-te -120 37 -77 38 \
  gdalwarp \
    --debug on \
    -r lanczos \
    -ts 1024 768 \
    -co TWF=YES \
    $chart-low-overview.vrt \
    ./$chart-low-warp.tif \

done

for chart in enroute;
do
  echo $chart
  
  gdalbuildvrt \
    -resolution highest \
    $chart-high-overview.vrt \
    -srcnodata b4 \
    -hidenodata \
    -overwrite \
    ./clippedRasters/$chart/ENR_H*.tif

  gdal_translate \
    -strict \
    -co TILED=YES \
    -co COMPRESS=LZW \
    -outsize 1024 768 \
    $chart-high-overview.vrt \
    $chart-high-translate.tif \

  #-te -120 37 -77 38 \
  gdalwarp \
    --debug on \
    -r lanczos \
    -ts 1024 768 \
    -co TWF=YES \
    $chart-high-overview.vrt \
    $chart-high-warp.tif \

done
# #-----------------------------------------------
# gdalwarp \
#   -of VRT \
#   -co TILED=YES \
#   -r lanczos \
#   ../clippedRasters/wac/CF-17_WAC.tif \
#   ./CF-17_WAC.vrt \
# 
# gdalwarp \
#   -of VRT \
#   -co TILED=YES \
#   -r lanczos \
#   ../clippedRasters/wac/CF-18_WAC.tif \
#   ./CF-18_WAC.vrt \
# 
# gdalwarp \
#   -of VRT \
#   -co TILED=YES \
#   -r lanczos \
#   ../clippedRasters/wac/CF-19_WAC.tif \
#   ./CF-19_WAC.vrt \
# 
# gdalbuildvrt \
# -resolution highest \
# -srcnodata b4 \
# -overwrite \
# wac_overview.vrt \
# ./*.vrt
# 
# gdal_translate \
# -strict \
# -co TILED=YES \
# -co COMPRESS=LZW \
# -outsize 1024 768 \
# wac_overview.vrt \
# wac.tif \
#-----------------------------------------------

  
# gdal_merge.py \
#   -o wac2.tif \
#   -co TILED=YES \
#   -co COMPRESS=LZW \
#   -ps 1024 768\
#   ./clippedRasters/wac/*.tif

