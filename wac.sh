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

chartType="wac"

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


# #Freshen the local files first
# 
# #Now unzip everything
# cd $originalRastersDirectory
# #Unzip all of the sectional charts
# unzip -u -j "*.zip" "*.tif"
# 
# #Remove current links if any exist
# #FILTER will be empty if no .tifs
# FILTER=$(find $linkedRastersDirectory/ -type l \( -name "*.tif" \) )
# 
# 
# if [[ ! -z ${FILTER} ]]; then
#     echo "Deleting TIF links"
# #     echo $FILTER
#     rm $FILTER
# fi
# 
# #Link latest revision of chart as a base name
# shopt -s nullglob	
# for f in *.tif
# do
# 	#Replace spaces in name with _
# 	newName=($(printf $f | sed 's/\s/_/g'))
# 
# 	#Strip off the series number
# 	newName=($(printf $newName | sed --regexp-extended 's/_[0-9]+\./\./ig'))
# 
# 	#If names are sorted properly, this will link latest version
# 	echo "Linking $f -> $linkedRastersDirectory/$newName"
# 	ln -s -f -r "$f" $linkedRastersDirectory/$newName
# done
#These span the anti-meridian
crossAntiMeridian=(
CC-8_WAC
CD-10_WAC 
CE-12_WAC
)

chartArray=(
CC-9_WAC  
CD-11_WAC CD-12_WAC  
CE-13_WAC CE-15_WAC 
CF-16_WAC CF-17_WAC CF-18_WAC CF-19_WAC 
CG-18_WAC CG-19_WAC CG-20_WAC CG-21_WAC 
CH-22_WAC CH-23_WAC CH-24_WAC CH-25_WAC
CJ-26_WAC CJ-27_WAC
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
   
    #Pull the info for this chart from array
    sourceChartName=${chartArray[i*$points+0]}
    
    expandedName=expanded-$sourceChartName
    clippedName=clipped-$expandedName

    #Test if we need to expand the original file
    if [ ! -f "$expandedRastersDirectory/$expandedName.tif" ];
      then
	./translateExpand.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
    fi
      
        #Test if we need to clip the expanded file
    if [ ! -f  "$clippedRastersDirectory/$clippedName.tif" ];
      then      
      ./warpClip.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
  done