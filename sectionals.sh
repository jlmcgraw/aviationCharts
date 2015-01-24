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
zoomRange="0-11"

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
crossAntiMeridian=(Western_Aleutian_Islands_East_SEC)

chartArray=(
Albuquerque_SEC Anchorage_SEC Atlanta_SEC Bethel_SEC Billings_SEC 
Brownsville_SEC
Cape_Lisburne_SEC Charlotte_SEC Cheyenne_SEC Chicago_SEC Cincinnati_SEC 
Cold_Bay_SEC
Dallas-Ft_Worth_SEC Dawson_SEC Denver_SEC Detroit_SEC Dutch_Harbor_SEC El_Paso_SEC
Fairbanks_SEC Great_Falls_SEC Green_Bay_SEC Halifax_SEC Hawaiian_Islands_SEC 
Honolulu_Inset_SEC Houston_SEC Jacksonville_SEC Juneau_SEC Kansas_City_SEC
Ketchikan_SEC Klamath_Falls_SEC Kodiak_SEC Lake_Huron_SEC Las_Vegas_SEC Los_Angeles_SEC
Mariana_Islands_Inset_SEC McGrath_SEC Memphis_SEC Miami_SEC Montreal_SEC New_Orleans_SEC
New_York_SEC Nome_SEC Omaha_SEC Phoenix_SEC Point_Barrow_SEC Salt_Lake_City_SEC
Samoan_Islands_Inset_SEC San_Antonio_SEC San_Francisco_SEC Seattle_SEC Seward_SEC
St_Louis_SEC Twin_Cities_SEC Washington_SEC Western_Aleutian_Islands_West_SEC 
Whitehorse_SEC Wichita_SEC
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
    fi
    
    ./makeMbtiles.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName $zoomRange
  done