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

chartType="heli"

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


#Freshen the local files first

#Now unzip everything
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
	newName=($(printf $newName | sed --regexp-extended 's/_[0-9]+\./\./ig'))

	#If names are sorted properly, this will link latest version
	echo "Linking $f -> $linkedRastersDirectory/$newName"
	ln -s -f -r "$f" $linkedRastersDirectory/$newName
done

chartArray=(
Baltimore_HEL Boston_Downtown_HEL  Boston_HEL  Chicago_HEL 
Chicago_O\'Hare_Inset_HEL  Dallas-Ft_Worth_HEL 
Dallas-Love_Inset_HEL Detroit_HEL Downtown_Manhattan_HEL  
Eastern_Long_Island_HEL Houston_North_HEL Houston_South_HEL
Los_Angeles_East_HEL Los_Angeles_West_HEL New_York_HEL U.S._Gulf_Coast_HEL 
Washington_HEL Washington_Inset_HEL
) 

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
    #  if [-e $chartName*-warped.vrt ]
    #Pull the info for this chart from array
    sourceChartName=${chartArray[i*$points+0]}

    #sourceChartName=ENR_A01_DCA
    expandedName=expanded-$sourceChartName
    clippedName=clipped-$expandedName
    
    #For now, just skip if this clipped raster already exists
    if [ -f "$clippedRastersDirectory/$clippedName.tif" ];
      then continue;
    fi

    #Test if we need to expand the original file
    if [ ! -f "$expandedRastersDirectory/$expandedName.tif" ];
      then
	echo --- Expand --- gdal_translate $sourceChartName
	
	gdal_translate \
		      -strict \
		      -expand rgb \
		      -co TILED=YES \
                      -co COMPRESS=LZW \
		      "$linkedRastersDirectory/$sourceChartName.tif" \
		      "$expandedRastersDirectory/$expandedName.tif"
      fi
    
  if [ ! -f "$clippingShapesDirectory/$sourceChartName.shp" ];
      then
	echo ---No clipping shape found: "$clippingShapesDirectory/$sourceChartName.shp"
	exit 1
    fi
#	     -dstnodata 0 \
# -co "COMPRESS=LZW

    #Warp the original file, clipping it to it's clipping shape
    echo --- Clip --- gdalwarp $sourceChartName
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
             -t_srs EPSG:3857 \
             -r bilinear \
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
             
    echo "----------------------------------------------------------"
    done
