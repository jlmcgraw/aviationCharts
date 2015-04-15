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
zoomRange="0-12"

#For files that have a version in their name, this is where the links to the lastest version
#will be stored (step 1)
linkedRastersDirectory="$destinationRoot/sourceRasters/$chartType/"

#Where expanded rasters are stored (step 2)
expandedRastersDirectory="$destinationRoot/expandedRasters/$chartType/"

#Where clipped rasters are stored (step 3)
clippedRastersDirectory="$destinationRoot/clippedRasters/$chartType/"

#Where the polygons for clipping are stored
clippingShapesDirectory="$destinationRoot/clippingShapes/$chartType/"

#Where the mbtiles are stored
mbtilesDirectory="$destinationRoot/mbtiles/$chartType/"

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

if [ ! -d $clippedRastersDirectory ]; then
    echo "$clippedRastersDirectory doesn't exist"
    exit 1
fi

#These span the anti-meridian
crossAntiMeridian=()

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

    #Pull the info for this chart from array
    sourceChartName=${chartArray[i*$points+0]}

    echo --------------------------------$sourceChartName----------------------------------------------------
    ./translateExpand.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName

    #Warp and clip
    ./warpClip.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName

    #Make the tiles and mbtiles
    ./makeMbtiles.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName $zoomRange

  done