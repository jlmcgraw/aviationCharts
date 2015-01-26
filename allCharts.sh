#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#TODO
# Warp to EPSG:3857
#
# translate then warp, or warp then translate?
# 	Warp to vrt
# 	Expand with predictor 2
# 	  84.48MB
# 
# 	Warp to vrt
# 	Expand with predictor 2
# 	  real	15m43.391s
# 	  user	14m58.413s
# 	  sys	0m37.242s
# 
# 	warp to tiff
# 	expand with predictor 2
# 	real	16m25.018s
# 	user	15m22.508s
# 	sys	0m44.782s
# 
# 	translate
# 	expand
# 	      real	0m41.761s
# 	      user	0m34.678s
# 	      sys	0m4.506s
# 	      real	2m34.359s
# 	      user	1m37.086s
# 	      sys	0m45.631s
#
# Anywhere we exit, exit with an error code
# Handle charts that cross anti-meridian
# Make use of "make" to only process new charts
# Optimize the mbtile creation process
#	Parallel tiling (distribute amongst local cores, remote machines)
#	Lanczos for resampling
#	Optimizing size of individual tiles via pngcrush, pngquant, optipng etc
#	Linking of redundant tiles
# TAC max zoom 12
# SEC max zoom 11
# WAC max zoom 10

#Root of downloaded chart info
chartsRoot="/media/sf_Shared_Folder/charts/"


#Where the original .tif files are from aeronav
originalHeliDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/heli_files/"
originalTacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/tac_files/"
originalWacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/wac_files/"
originalSectionalDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/sectional_files/"
originalGrandCanyonDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/grand_canyon_files/"

#BUG TODO This will need to be updated for every cycle
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/01-08-2015/"

#Root of directories where our processed images etc will be saved
destinationRoot="${HOME}/Documents/myPrograms/mergedCharts"


# #Update local chart copies from Aeronav source
# ./freshenLocalCharts.sh $chartsRoot
# 
# #Update our local links to those (possibly new) original files
# #This handles charts that have revisions in the filename
# ./updateLinks.sh  $originalHeliDirectory        $destinationRoot heli
# ./updateLinks.sh  $originalTacDirectory         $destinationRoot tac
# ./updateLinks.sh  $originalWacDirectory         $destinationRoot wac
# ./updateLinks.sh  $originalSectionalDirectory   $destinationRoot sectional
# ./updateLinks.sh  $originalGrandCanyonDirectory $destinationRoot grand_canyon
# ./updateLinks.sh  $originalEnrouteDirectory     $destinationRoot enroute

# Expand charts to RGB bands as necessary
# clip to polygons
# Convert to a .mbtile
# ./heli.sh        $originalHeliDirectory        $destinationRoot
# ./tac.sh         $originalTacDirectory         $destinationRoot
# ./wac.sh         $originalWacDirectory         $destinationRoot
./sectionals.sh  $originalSectionalDirectory   $destinationRoot
./grandCanyon.sh $originalGrandCanyonDirectory $destinationRoot
./enroute.sh     $originalEnrouteDirectory     $destinationRoot
