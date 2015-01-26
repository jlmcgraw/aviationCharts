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

chartType="tac"
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
Anchorage_TAC Atlanta_TAC Baltimore-Washington_TAC Boston_TAC Charlotte_TAC 
Chicago_TAC Cincinnati_TAC Cleveland_TAC Colorado_Springs_TAC Dallas-Ft_Worth_TAC 
Denver_TAC Detroit_TAC Fairbanks_TAC Houston_TAC Kansas_City_TAC Las_Vegas_TAC 
Los_Angeles_TAC Memphis_TAC Miami_TAC Minneapolis-St_Paul_TAC New_Orleans_TAC 
New_York_TAC Orlando_TAC Philadelphia_TAC Phoenix_TAC Pittsburgh_TAC Puerto_Rico-VI_TAC 
Salt_Lake_City_TAC San_Diego_TAC San_Francisco_TAC Seattle_TAC St_Louis_TAC Tampa_TAC
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
    
#     expandedName=expanded-$sourceChartName
#     clippedName=clipped-$expandedName

    #Test if we need to expand the original file
    if [ ! -f "$expandedRastersDirectory/$sourceChartName.tif" ];
      then
	./translateExpand.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
    fi
      
        #Test if we need to clip the expanded file
    if [ ! -f  "$clippedRastersDirectory/$sourceChartName.tif" ];
      then      
        ./warpClip.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
    fi
    
    if [ ! -f  "$mbtilesDirectory/$sourceChartName.mbtiles" ];
      then      
    ./makeMbtiles.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName $zoomRange
    fi
    
  done