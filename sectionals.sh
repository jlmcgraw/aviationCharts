#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"

if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 SOURCE_DIRECTORY destinationRoot" >&2
  exit 1
fi

chartType="sectional"

#For files that have a version in their name, this is where the links to the lastest version
#will be stored (step 1)
linkedRastersDirectory="$destinationRoot/sourceRasters/$chartType/"

#Where expanded rasters are stored (step 2)
expandedRastersDirectory="$destinationRoot/expandedRasters/$chartType/"

#Where clipped rasters are stored (step 3)
clippedRastersDirectory="$destinationRoot/clippedRasters/$chartType/"

#Where the polygons for clipping are stored
clippingShapesDirectory="$destinationRoot/clippingShapes/$chartType/"




if [ ! -d $originalRastersDirectory ]; then
    echo "$originalRastersDirectory doesn't exist"
    exit
fi

if [ ! -d $linkedRastersDirectory ]; then
    echo "$linkedRastersDirectory doesn't exist"
    exit
fi

if [ ! -d $expandedRastersDirectory ]; then
    echo "$expandedRastersDirectory doesn't exist"
    exit
fi

if [ ! -d $clippedRastersDirectory ]; then
    echo "$clippedRastersDirectory doesn't exist"
    exit
fi


cd $originalRastersDirectory
#Unzip all of the sectional charts
unzip -u -j "*.zip" "*.tif"

#Remove current links if any exist
#FILTER will be empty if no .tifs
FILTER=$(find $linkedRastersDirectory/ -type l \( -name "*.tif" \) )


if [[ ! -z ${FILTER} ]]; then
    echo "Deleting TIF links"
#     echo $FILTER
    rm $FILTER
fi


#Link latest revision of chart as a base name
shopt -s nullglob	
for f in *.tif
do
	#Replace spaces in name with _
	newName=($(printf $f | sed 's/\s/_/g'))

	#Strip off the series number
	newName=($(printf $newName | sed 's/_SEC_[0-9][0-9]//ig'))

	#If names are sorted properly, this will link latest version
	echo "Linking $f -> $linkedRastersDirectory$newName"
	ln -s -f -r "$f" $linkedRastersDirectory$newName
	#Give the link the same date as the source raster
	touch -r "$f" $linkedRastersDirectory$newName
done

chartArray=(
Albuquerque Anchorage Atlanta Bethel Billings Brownsville Cape_Lisburne Charlotte
Cheyenne Chicago Cincinnati Cold_Bay Dallas-Ft_Worth Dawson Denver Detroit
Dutch_Harbor El_Paso Fairbanks Great_Falls Green_Bay Halifax Hawaiian_Islands 
Honolulu_Inset Houston Jacksonville Juneau Kansas_City Ketchikan Klamath_Falls
Kodiak Lake_Huron Las_Vegas Los_Angeles Mariana_Islands_Inset McGrath
Memphis  Miami Montreal New_Orleans New_York Nome Omaha Phoenix Point_Barrow
Salt_Lake_City Samoan_Islands_Inset San_Antonio San_Francisco Seattle Seward
St_Louis Twin_Cities Washington  
Western_Aleutian_Islands_West Whitehorse Wichita
) 

cd $linkedRastersDirectory

#These span the anti-meridian
#Western_Aleutian_Islands_East

#count of all items in chart array
chartArrayLength=${#chartArray[*]}

#data points for each entry
let points=1

#divided by size of each entry gives number of charts
let numberOfCharts=$chartArrayLength/$points;

echo Found $numberOfCharts $chartType charts

#Loop through all of the charts in our array and process them
for (( i=0; i<=$(( $numberOfCharts-1 )); i++ ))
  do
   
    #Pull the info for this chart from array
    sourceChartName=${chartArray[i*$points+0]}

    expandedName=expanded-$sourceChartName
    clippedName=clipped-$expandedName
      
    #Test if we need to expand the original file
    if [  ! -f "$expandedRastersDirectory/$expandedName.tif" ];
      then
       echo ---gdal_translate $sourceChartName
    
       gdal_translate \
		   -of GTiff \
                   -strict \
                   -expand rgb \
                   -co TILED=YES \
                   -co COMPRESS=LZW \
                   "$linkedRastersDirectory/$sourceChartName.tif" \
                   "$expandedRastersDirectory/$expandedName.tif"
    
      echo ---gdaladdo $sourceChartName   
      
      #Create external overviews to make display faster in QGIS
      gdaladdo \
	      -ro \
	      --config INTERLEAVE_OVERVIEW PIXEL \
	      --config COMPRESS_OVERVIEW JPEG \
	      --config BIGTIFF_OVERVIEW IF_NEEDED \
	      "$expandedRastersDirectory/$expandedName.tif" \
	      2 4 8 16  		    
    fi
#	     -dstnodata 0 \
# -co "COMPRESS=LZW
  if [ ! -f "$clippingShapesDirectory/$sourceChartName.shp" ];
      then
	echo ---No clipping shape found: "$clippingShapesDirectory/$sourceChartName.shp"
	exit 1
    fi
    
    #Skip if the clipped file already exists
    if [ ! -f "$clippedRastersDirectory/$clippedName.tif" ];
      then
      
      echo ---gdalwarp $sourceChartName
      gdalwarp \
	      -cutline "$clippingShapesDirectory/$sourceChartName.shp" \
	      -crop_to_cutline \
	      -dstalpha \
	      -of GTiff \
	      -cblend 15 \
	      -multi \
	      -wo NUM_THREADS=ALL_CPUS  \
	      -overwrite \
	      -wm 1024 \
	      -co TILED=YES \
              -co COMPRESS=LZW \
	      "$expandedRastersDirectory/$expandedName.tif" \
	      "$clippedRastersDirectory/$clippedName.tif"

      #Create external overviews to make display faster in QGIS
      echo ---gdaladdo $sourceChartName             
      gdaladdo \
	      -ro \
	      --config INTERLEAVE_OVERVIEW PIXEL \
	      --config COMPRESS_OVERVIEW JPEG \
	      --config BIGTIFF_OVERVIEW IF_NEEDED \
	      "$clippedRastersDirectory/$clippedName.tif" \
	      2 4 8 16         
             
    fi
    
    echo "----------------------------------------------------------"
    done
