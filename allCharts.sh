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

if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 <charts_root_directory> <latest_enroute_cycle_data_date>" >&2
  echo "eg $0 ~/Downloads/charts 09-15-2016"
  exit 1
fi

#Get command line parameters
chartsRoot="$1"
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/$2"

if [ ! -d "$chartsRoot" ]; then
    echo "The supplied chart root directory $chartsRoot doesn't exist"
    exit 1
fi

#Determine the full path to where this script is
#Use this as the root of directories where our processed images etc will be saved
pushd $(dirname "$0") > /dev/null
destinationRoot=$(pwd)
popd > /dev/null

#Where the original .zip files are from aeronav (subject to them changing their layout)
originalHeliDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/heli_files/"
originalTacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/tac_files/"
originalWacDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/wac_files/"
originalSectionalDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/sectional_files/"
originalGrandCanyonDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/Grand_Canyon_files/"
originalCaribbeanDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/Caribbean/"

# If some of these steps are commented out it's because I don't always want to 
#  wait for them to run so uncomment them as necessary

#Update local chart copies from Aeronav website
./freshenLocalCharts.sh $chartsRoot

# Test after freshening local data
if [ ! -d "$originalEnrouteDirectory" ]; then
    echo "The supplied latest enroute charts directory $originalEnrouteDirectory doesn't exist"
    exit 1
fi

#Extract Caribbean PDFs and convert to TIFF
./rasterize_Caribbean_charts.sh $originalEnrouteDirectory $destinationRoot enroute

# Update our local links to those (possibly new) original files
# This handles charts that have revisions in the filename (sectional, tac etc)
./updateLinks.sh  $originalEnrouteDirectory     $destinationRoot enroute
./updateLinks.sh  $originalGrandCanyonDirectory $destinationRoot grand_canyon
./updateLinks.sh  $originalHeliDirectory        $destinationRoot heli
./updateLinks.sh  $originalSectionalDirectory   $destinationRoot sectional
./updateLinks.sh  $originalTacDirectory         $destinationRoot tac
./updateLinks.sh  $originalCaribbeanDirectory   $destinationRoot caribbean
# ./updateLinks.sh  $originalWacDirectory         $destinationRoot wac

# Clip and georeference insets
./cut_and_georeference_Sectional_insets.pl
./cut_and_georeference_Caribbean_insets.pl $destinationRoot 

# The process*.sh scripts each do these functions for a given chart type:
# 	Expand charts to RGB bands as necessary (currently not needed for enroute) via a .vrt file
# 	Clip to their associated polygon
#	Reproject to EPSG:3857
./processEnroute.sh     $originalEnrouteDirectory     $destinationRoot
./processGrandCanyon.sh $originalGrandCanyonDirectory $destinationRoot
./processHeli.sh        $originalHeliDirectory        $destinationRoot
./processSectionals.sh  $originalSectionalDirectory   $destinationRoot
./processTac.sh         $originalTacDirectory         $destinationRoot
./processCaribbean.sh   $originalCaribbeanDirectory   $destinationRoot
# ./processWac.sh         $originalWacDirectory         $destinationRoot

# The tile*.sh scripts each do these functions for a given chart type:
# 	create TMS tile tree from the reprojected raster
#       optionally (with -o) use pngquant to optimize each individual tile
#       optionally (with -m) create an mbtile for each individual chart
#
# add/remove -o to optimize tile size with pngquant
# add/remove -m to create mbtiles
# eg ./tileEnrouteHigh.sh    -o -m $destinationRoot
./tileEnrouteHigh.sh    -m -o $destinationRoot
./tileEnrouteLow.sh     -m -o $destinationRoot
./tileGrandCanyon.sh    -m -o $destinationRoot
./tileHeli.sh           -m -o $destinationRoot
./tileSectional.sh      -m -o $destinationRoot
./tileTac.sh            -m -o $destinationRoot
./tileInsets.sh         -m -o $destinationRoot
./tileCaribbean.sh      -m -o $destinationRoot
# ./tileWac.sh           -m -o $destinationRoot

# Stack the various resolutions and types of charts into combined tilesets and mbtiles
# Use these command line options to do/not do specific types of charts and/or create mbtiles 
#  -v  Create merged VFR
#  -h  Create merged IFR-HIGH
#  -l  Create merged IFR-LOW
#  -c  Create merged HELICOPTER"
#  -m  Create mbtiles for each chart
./mergeCharts.sh -v -h -l -c -m           $destinationRoot   $destinationRoot

exit 0