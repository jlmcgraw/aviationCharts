#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

sectionalsDirectory="${HOME}/Documents/myPrograms/mergedCharts/sourceRasters/sectionals/"
clippingShapesDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippingShapes/"

# #ls -1 | sed -e 's/\.tif//g'
# 
# #Get all of the charts
#  wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr/
#  wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr/
# 
# #Unzip all of the sectional charts
# unzip -u "*.zip" "*.tif"
# 
# #Link latest revision of chart as a base name
# shopt -s nullglob
# for f in *.tif
# do
# 	#Replace spaces in name with _
# 	newName=($(printf $f | sed 's/\s/_/g'))
# 	#Strip off the series number
# 	newName=($(printf $newName | sed 's/_SEC_[0-9][0-9]//ig'))
# 
# 	#If names are sorted properly, this will link latest version
# 	echo "Linking $f -> $sectionalsDirectory$newName"
# 	ln -s -f -r "$f" $sectionalsDirectory$newName
# done

sectionalCharts=(
Albuquerque Anchorage Atlanta Bethel Billings Brownsville Cape_Lisburne Charlotte
Cheyenne Chicago Cincinnati Cold_Bay Dallas-Ft_Worth Dawson Denver Detroit
Dutch_Harbor El_Paso Fairbanks Great_Falls Green_Bay Halifax Hawaiian_Islands 
Honolulu_Inset Houston Jacksonville Juneau Kansas_City Ketchikan Klamath_Falls
Kodiak Lake_Huron Las_Vegas Los_Angeles Mariana_Islands_Inset McGrath
Memphis  Miami Montreal New_Orleans New_York Nome Omaha Phoenix Point_Barrow
Salt_Lake_City Samoan_Islands_Inset San_Antonio San_Francisco Seattle Seward
St_Louis Twin_Cities Washington Western_Aleutian_Islands_East 
Western_Aleutian_Islands_West Whitehorse Wichita
) 

#count of all items in chart array
sectionalChartArrayLength=${#sectionalCharts[*]}

#data points for each entry
let points=1

#divided by size of each entry gives number of charts
let numberOfSectionalCharts=$sectionalChartArrayLength/$points;

echo Found $numberOfSectionalCharts sectional charts

#Loop through all of the charts in our array and process them
for (( i=0; i<=$(( $numberOfSectionalCharts-1 )); i++ ))
  do
    #  if [-e $chartName*-warped.vrt ]
    #Pull the info for this chart from array
    sourceChartName=${sectionalCharts[i*$points+0]}

    #sourceChartName=ENR_A01_DCA
    expandedName=expanded-$sourceChartName
    clippedName=clipped-$expandedName
    
    echo gdal_translate $sourceChartName
    
    gdal_translate \
		   -of vrt \
                   -strict \
                   "$sectionalsDirectory/$sourceChartName.tif" \
                   "$sectionalsDirectory/$expandedName.vrt"

#	     -dstnodata 0 \
	     
    echo gdalwarp $sourceChartName
    gdalwarp \
             -cutline "$clippingShapesDirectory/sectional-$sourceChartName.shp" \
             -crop_to_cutline \
             -dstalpha \
             -of GTiff \
             -cblend 15 \
             -multi \
             -wm 1000 \
             -co COMPRESS=DEFLATE \
             -co TILED=YES \
             -co PREDICTOR=1 \
             -co ZLEVEL=9 \
             -overwrite \
             "$sectionalsDirectory/$expandedName.vrt" \
             "$sectionalsDirectory/$clippedName.tif"

    echo gdaladdo $sourceChartName             
    gdaladdo \
             -ro \
             --config INTERLEAVE_OVERVIEW PIXEL \
             --config COMPRESS_OVERVIEW JPEG \
             --config BIGTIFF_OVERVIEW IF_NEEDED \
             "$sectionalsDirectory/$clippedName.tif" \
             2 4 8 16         
             
    echo "----------------------------------------------------------"
    done
