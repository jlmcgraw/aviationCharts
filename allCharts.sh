#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Root of downloaded chart info
chartsRoot="/media/sf_Shared_Folder/charts/"


#Where the original .tif files are from aeronav
originalHeliDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/heli_files/"
originalTacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/tac_files/"
originalWacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/wac_files/"
originalSectionalDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/sectional_files/"
originalGrandCanyonDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/grand_canyon_files/"
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/01-08-2015/"

#Root of directories where our processed images etc will be saved
destinationRoot="${HOME}/Documents/myPrograms/mergedCharts"


#Update local charts
# ./freshenLocalCharts.sh $chartsRoot
# ./sectionals.sh $originalSectionalDirectory $destinationRoot
./tac.sh $originalTacDirectory $destinationRoot
# ./wac.sh $originalWacDirectory $destinationRoot
# ./grandCanyon.sh $originalGrandCanyonDirectory $destinationRoot
# ./enroute.sh $originalEnrouteDirectory $destinationRoot
# ./heli.sh $originalHeliDirectory $destinationRoot