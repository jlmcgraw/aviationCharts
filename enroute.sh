#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

expandedFilesDirectory="${HOME}/Documents/myPrograms/mergedCharts/sourceRasters/IFR/"
clippingShapesDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippingShapes/"
clippedRastersTacDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippedRasters/IFR/"

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
# shopt -s nullglob
# for f in *.tif
# do
# 	#Replace spaces in name with _
# 	newName=($(printf $f | sed 's/\s/_/g'))
# 
# # 	#Strip off the series number
# # 	newName=($(printf $newName | sed 's/_[0-9][0-9]//ig'))
# 
# 	#If names are sorted properly, this will link latest version
# 	echo "Linking $f -> $expandedFilesDirectory$newName"
# 	ln -s -f -r "$f" $expandedFilesDirectory$newName
# done

#These span the dateline
# ENR_AKH01
# ENR_AKH02
# ENR_P01
# ENR_AKL02W
# ENR_AKL03
# ENR_AKL04
# ENR_H01
# porc
tacCharts=(
ENR_A01_ATL
ENR_A01_DCA
ENR_A01_DET
ENR_A01_JAX
ENR_A01_MIA
ENR_A01_MSP
ENR_A01_STL
ENR_A02_DEN
ENR_A02_DFW
ENR_A02_LAX
ENR_A02_MKC
ENR_A02_ORD
ENR_A02_PHX
ENR_A02_SFO
ENR_AKH01_SEA
ENR_AKL01_JNU
ENR_AKL01
ENR_AKL01_VR
ENR_AKL02C
ENR_AKL02E
ENR_AKL03_FAI
ENR_AKL03_OME
ENR_AKL04_ANC
ENR_H02
ENR_H03
ENR_H04
ENR_H05
ENR_H06
ENR_H07
ENR_H08
ENR_H09
ENR_H10
ENR_H11
ENR_H12
ENR_L01
ENR_L02
ENR_L03
ENR_L04
ENR_L05
ENR_L06N
ENR_L06S
ENR_L07
ENR_L08
ENR_L09
ENR_L10
ENR_L11
ENR_L12
ENR_L13
ENR_L14
ENR_L15
ENR_L16
ENR_L17
ENR_L18
ENR_L19
ENR_L20
ENR_L21
ENR_L22
ENR_L23
ENR_L24
ENR_L25
ENR_L26
ENR_L27
ENR_L28
ENR_L29
ENR_L30
ENR_L31
ENR_L32
ENR_L33
ENR_L34
ENR_L35
ENR_L36
ENR_P01_GUA
ENR_P02
narc
watrs
)

#count of all items in chart array
tacChartArrayLength=${#tacCharts[*]}

#data points for each entry
let points=1

#divided by size of each entry gives number of charts
let numberOfTacCharts=$tacChartArrayLength/$points;

echo Found $numberOfTacCharts Enroute charts

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
    if [ ! -f "$expandedFilesDirectory/$expandedName.vrt" ];
      then
	echo ---gdal_translate $sourceChartName
	
	gdal_translate \
		      -of vrt \
		      -strict \
		      "$expandedFilesDirectory/$sourceChartName.tif" \
		      "$expandedFilesDirectory/$expandedName.tif"
	#Create external overviews to make display faster in QGIS
        echo ---gdaladdo $sourceChartName             
        gdaladdo \
             -ro \
             --config INTERLEAVE_OVERVIEW PIXEL \
             --config COMPRESS_OVERVIEW JPEG \
             --config BIGTIFF_OVERVIEW IF_NEEDED \
             "$expandedFilesDirectory/$expandedName.tif" \
             2 4 8 16  	      
    fi
      
    if [ ! -f "$clippingShapesDirectory/ifr-$sourceChartName.shp" ];
      then
	echo ---No clipping shape found: "$clippingShapesDirectory/ifr-$sourceChartName.shp"
    fi
#	     -dstnodata 0 \
# -co "COMPRESS=LZW

    #Warp the original file, clipping it to it's clipping shape
#              -s_srs EPSG:4326 \
#              -t_srs EPSG:3857 \
#   -cblend 15 \

    #Test if we need to clip the expanded file
    if [ ! -f  "$clippedRastersTacDirectory/$clippedName.tif" ];
      then
      
      echo ---gdalwarp $sourceChartName
      gdalwarp \
	      -cutline "$clippingShapesDirectory/ifr-$sourceChartName.shp" \
	      -crop_to_cutline \
	      -dstalpha \
	      -of GTiff \
	      -multi \
	      -wo NUM_THREADS=ALL_CPUS  \
	      -overwrite \
	      -wm 1024 \
	      --config GDAL_CACHEMAX 256 \
	      -co TILED=YES \
	      -co COMPRESS=DEFLATE \
	      -co PREDICTOR=1 \
	      -co ZLEVEL=9 \
	      "$expandedFilesDirectory/$expandedName.vrt" \
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
    fi
    
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
