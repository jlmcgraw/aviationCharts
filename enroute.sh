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

chartType="enroute"

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
crossAntiMeridian=(
ENR_AKH01 ENR_AKH02
ENR_P01
ENR_AKL02W ENR_AKL03 ENR_AKL04
ENR_H01
porc
)

chartArray=(
ENR_A01_ATL ENR_A01_DCA ENR_A01_DET ENR_A01_JAX ENR_A01_MIA ENR_A01_MSP 
ENR_A01_STL ENR_A02_DEN ENR_A02_DFW ENR_A02_LAX ENR_A02_MKC ENR_A02_ORD 
ENR_A02_PHX ENR_A02_SFO 
ENR_AKH01_SEA 
ENR_AKL01_JNU ENR_AKL01 ENR_AKL01_VR ENR_AKL02C ENR_AKL02E 
ENR_AKL03_FAI ENR_AKL03_OME ENR_AKL04_ANC
ENR_H02 ENR_H03 ENR_H04 ENR_H05 ENR_H06 ENR_H07 ENR_H08 ENR_H09 ENR_H10 
ENR_H11 ENR_H12 
ENR_L01 ENR_L02 ENR_L03 ENR_L04 ENR_L05 ENR_L06N ENR_L06S ENR_L07 
ENR_L08 ENR_L09 ENR_L10 ENR_L11 ENR_L12 ENR_L13 ENR_L14 ENR_L15 ENR_L16 
ENR_L17 ENR_L18 ENR_L19 ENR_L20 ENR_L21 ENR_L22 ENR_L23 ENR_L24 ENR_L25 
ENR_L26 ENR_L27 ENR_L28 ENR_L29 ENR_L30 ENR_L31 ENR_L32 ENR_L33 ENR_L34 
ENR_L35 ENR_L36
ENR_P01_GUA ENR_P02 
narc 
watrs
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
	./translateNoExpand.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
    fi
      
    #Test if we need to clip the expanded file
    if [ ! -f  "$clippedRastersDirectory/$clippedName.tif" ];
      then      
        ./warpClip.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
    fi 
    
    ./makeMbtiles.sh $originalRastersDirectory $destinationRoot $chartType $sourceChartName
  done
