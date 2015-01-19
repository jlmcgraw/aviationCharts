#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Where the original .tif files are from aeronav
originalSectionalsDirectory="/media/sf_Apricorn/charts/aeronav.faa.gov/content/aeronav/sectional_files/"

#Where we'll expand them to
sectionalsDirectory="${HOME}/Documents/myPrograms/mergedCharts/sourceRasters/sectionals/"

#Where the polygons for clipping are stored
clippingShapesDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippingShapes/"

#Where to store the clipped rasters
clippedRastersSectionalsDirectory="${HOME}/Documents/myPrograms/mergedCharts/clippedRasters/"

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


cd $originalSectionalsDirectory
#Unzip all of the sectional charts
unzip -u -j "*.zip" "*.tif"

#Remove current links if any exist
#FILTER will be empty if no .tifs
FILTER=$(find $sectionalsDirectory/ -type f \( -name "*.tif" \) )

if [ -z ${FILTER} ]; then
    echo "Deleting existing TIFFs"
    rm $sectionalsDirectory/*.tif
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
	echo "Linking $f -> $sectionalsDirectory$newName"
	ln -s -f -r "$f" $sectionalsDirectory$newName
done

sectionalCharts=(
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

cd $originalSectionalsDirectory

#Removing this one for now since it crosses the dateline
#Western_Aleutian_Islands_East

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
      
    #Test if we need to expand the original file
    if [  ! -f "$sectionalsDirectory/$expandedName.tif" ];
      then
       echo ---gdal_translate $sourceChartName
    
       gdal_translate \
		   -of GTiff \
                   -strict \
                   -expand rgb \
                   -co TILED=YES \
                   -co COMPRESS=DEFLATE \
                   -co PREDICTOR=1 \
                   -co ZLEVEL=9 \
                   "$sectionalsDirectory/$sourceChartName.tif" \
                   "$sectionalsDirectory/$expandedName.tif"
    
      echo ---gdaladdo $sourceChartName   
      
      #Create external overviews to make display faster in QGIS
      gdaladdo \
	      -ro \
	      --config INTERLEAVE_OVERVIEW PIXEL \
	      --config COMPRESS_OVERVIEW JPEG \
	      --config BIGTIFF_OVERVIEW IF_NEEDED \
	      "$sectionalsDirectory/$expandedName.tif" \
	      2 4 8 16  		    
    fi
#	     -dstnodata 0 \
# -co "COMPRESS=LZW

    #Skip if the clipped file already exists
    if [ ! -f "$clippedRastersSectionalsDirectory/$clippedName.tif" ];
      then
      
      echo ---gdalwarp $sourceChartName
      gdalwarp \
	      -cutline "$clippingShapesDirectory/sectional-$sourceChartName.shp" \
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
	      "$sectionalsDirectory/$expandedName.tif" \
	      "$clippedRastersSectionalsDirectory/$clippedName.tif"

      #Create external overviews to make display faster in QGIS
      echo ---gdaladdo $sourceChartName             
      gdaladdo \
	      -ro \
	      --config INTERLEAVE_OVERVIEW PIXEL \
	      --config COMPRESS_OVERVIEW JPEG \
	      --config BIGTIFF_OVERVIEW IF_NEEDED \
	      "$clippedRastersSectionalsDirectory/$clippedName.tif" \
	      2 4 8 16         
             
    fi
    
    echo "----------------------------------------------------------"
    done
