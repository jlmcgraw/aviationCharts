
#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

#TODO
# Move towards using VRTs once clipping polygons are established
# Look at other alternatives for clipping (pixel/line extents)
# Anywhere we exit, exit with an error code

# Optimize the mbtile creation process
#	Parallel tiling (distribute amongst local cores, remote machines)
#	Lanczos for resampling
#	Optimizing size of individual tiles via pngcrush, pngquant, optipng etc
#	Linking of redundant tiles
# Automatically clean out old charts, currently they'll just accumulate
#DONE
# Handle charts that cross anti-meridian
# Make use of "make" to only process new charts (done via memoize)

#Full path to root of where aeronav site will be mirrored to via wget
chartsRoot="/media/sf_Shared_Folder/charts/"

#Determine the full path to where this script is
#Use this as the root of directories where our processed images etc will be saved
pushd $(dirname "$0") > /dev/null
destinationRoot=$(pwd)
popd > /dev/null
# destinationRoot="${HOME}/Documents/myPrograms/mergedCharts"

#BUG TODO This will need to be updated for every new enroute charting cycle
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/04-30-2015/"

#Where the original .zip files are from aeronav (subject to them changing their layout)
originalHeliDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/heli_files/"
originalTacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/tac_files/"
originalWacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/wac_files/"
originalSectionalDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/sectional_files/"
originalGrandCanyonDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/grand_canyon_files/"

#If some of these steps are commented out it's because I don't always want to wait for them to run
#so uncomment them as necessary

#Update local chart copies from Aeronav website
./freshenLocalCharts.sh $chartsRoot

#Update our local links to those (possibly new) original files
#This handles charts that have revisions in the filename (sectional, tac etc)
./updateLinks.sh  $originalHeliDirectory        $destinationRoot heli
./updateLinks.sh  $originalTacDirectory         $destinationRoot tac
./updateLinks.sh  $originalWacDirectory         $destinationRoot wac
./updateLinks.sh  $originalSectionalDirectory   $destinationRoot sectional
./updateLinks.sh  $originalGrandCanyonDirectory $destinationRoot grand_canyon
./updateLinks.sh  $originalEnrouteDirectory     $destinationRoot enroute

# General Process:
# 	Expand charts to RGB bands as necessary (currently not needed for enroute) via a .vrt file
# 	Clip to their associated polygon
#	Reproject to EPSG:3857
# 	Convert clipped and warped image to TMS layout folders of tiles
# 	Package those tiles into a .mbtile
./processHeli.sh        $originalHeliDirectory        $destinationRoot
./processTac.sh         $originalTacDirectory         $destinationRoot
./processSectionals.sh  $originalSectionalDirectory   $destinationRoot
./processGrandCanyon.sh $originalGrandCanyonDirectory $destinationRoot
./processEnroute.sh     $originalEnrouteDirectory     $destinationRoot
./processWac.sh         $originalWacDirectory         $destinationRoot

#Create tiles and merged charts with tiler_tools
./tileAll.sh
