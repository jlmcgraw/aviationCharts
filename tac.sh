#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

tacDirectory="${HOME}/Documents/myPrograms/mergedCharts/sourceRasters/TAC/"
clippingShapesDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippingShapes/"
clippedRastersTacDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippedRasters/"

#~/Documents/myPrograms/mergedCharts/test/aeronav.faa.gov/content/aeronav/tac_files

# Get a quick listing of files without the extentions
# #ls -1 | sed -e 's/\.tif//g'
# 
# #Get all of the latest charts
#  wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr/
#  wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr/
# 
# #Unzip all of the sectional charts
# unzip -u -j "*.zip" "*.tif"
# 
# # #Link latest revision of chart as a base name
# #BUG TODO don't link NYC VFR
# shopt -s nullglob
# for f in *TAC*.tif
# do
# 	#Replace spaces in name with _
# 	newName=($(printf $f | sed 's/\s/_/g'))
# 
# 	#Strip off the series number
# 	newName=($(printf $newName | sed 's/_[0-9][0-9]//ig'))
# 
# 	#If names are sorted properly, this will link latest version
# 	echo "Linking $f -> $tacDirectory$newName"
# 	ln -s -f -r "$f" $tacDirectory$newName
# done

tacCharts=(
Anchorage_TAC
Atlanta_TAC
Baltimore-Washington_TAC
Boston_TAC
Charlotte_TAC
Chicago_TAC
Cincinnati_TAC
Cleveland_TAC
Colorado_Springs_TAC
Dallas-Ft_Worth_TAC
Denver_TAC
Detroit_TAC
Fairbanks_TAC
Houston_TAC
Kansas_City_TAC
Las_Vegas_TAC
Los_Angeles_TAC
Memphis_TAC
Miami_TAC
Minneapolis-St_Paul_TAC
New_Orleans_TAC
New_York_TAC
Orlando_TAC
Philadelphia_TAC
Phoenix_TAC
Pittsburgh_TAC
Puerto_Rico-VI_TAC
Salt_Lake_City_TAC
San_Diego_TAC
San_Francisco_TAC
Seattle_TAC
St_Louis_TAC
Tampa_TAC
) 

#count of all items in chart array
tacChartArrayLength=${#tacCharts[*]}

#data points for each entry
let points=1

#divided by size of each entry gives number of charts
let numberOfTacCharts=$tacChartArrayLength/$points;

echo Found $numberOfTacCharts TAC charts

#Loop through all of the charts in our array and process them
for (( i=0; i<=$(( $numberOfTacCharts-1 )); i++ ))
  do
    #  if [-e $chartName*-warped.vrt ]
    #Pull the info for this chart from array
    sourceChartName=${tacCharts[i*$points+0]}

    #sourceChartName=ENR_A01_DCA
    expandedName=expanded-$sourceChartName
    clippedName=clipped-$expandedName
    
    #For now, just skip if this clipped raster already exists
    if [ -f "$clippedRastersTacDirectory/$clippedName.tif" ];
      then continue;
    fi

    #Test if we need to expand the original file
    if [ ! -f "$tacDirectory/$expandedName.vrt" ];
      then
	echo ---gdal_translate $sourceChartName
	
	gdal_translate \
		      -of vrt \
		      -strict \
		      -expand rgb \
		      "$tacDirectory/$sourceChartName.tif" \
		      "$tacDirectory/$expandedName.vrt"
      fi
      
#	     -dstnodata 0 \
# -co "COMPRESS=LZW

    #Warp the original file, clipping it to it's clipping shape
    echo ---gdalwarp $sourceChartName
    gdalwarp \
             -cutline "$clippingShapesDirectory/tac-$sourceChartName.shp" \
             -crop_to_cutline \
             -dstalpha \
             -of GTiff \
             -cblend 15 \
             -multi \
             -wo NUM_THREADS=ALL_CPUS  \
             -overwrite \
             -wm 1024 \
             -co TILED=YES \
             -co COMPRESS=DEFLATE \
             -co PREDICTOR=1 \
             -co ZLEVEL=9 \
             "$tacDirectory/$expandedName.vrt" \
             "$clippedRastersTacDirectory/$clippedName.tif"
    
    #Create external overviews to make display faster in QGIS
    echo ---gdaladdo $sourceChartName             
    gdaladdo \
             -ro \
             --config INTERLEAVE_OVERVIEW PIXEL \
             --config COMPRESS_OVERVIEW JPEG \
             --config BIGTIFF_OVERVIEW IF_NEEDED \
             "$clippedRastersTacDirectory/$clippedName.tif" \
             2 4 8 16         
             
    echo "----------------------------------------------------------"
    done
