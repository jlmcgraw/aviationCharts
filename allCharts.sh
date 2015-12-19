
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

# #-------------------------------------------------------------------------------
# #Things you may need to edit
# #Full path to root of where aeronav site will be mirrored to via wget
# chartsRoot="/media/sf_Shared_Folder/charts"
# 
# #BUG TODO This will need to be updated for every new enroute charting cycle
# originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/12-10-2015/"

if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 <charts_root_directory> <latest_enroute_cycle_data_date>" >&2
  echo "eg $0 ~/Downloads/charts 12-10-2015"
  exit 1
fi

#Get command line parameters
chartsRoot="$1"
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/$2"

if [ ! -d "$chartsRoot" ]; then
    echo "The supplied chart root directory $chartsRoot doesn't exist"
    exit 1
fi

if [ ! -d "$originalEnrouteDirectory" ]; then
    echo "The supplied latest enroute charts directory $originalEnrouteDirectory doesn't exist"
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
originalGrandCanyonDirectory="$chartsRoot/aeronav.faa.gov/content/aeronav/grand_canyon_files/"

#If some of these steps are commented out it's because I don't always want to 
# wait for them to run so uncomment them as necessary

#Update local chart copies from Aeronav website
./freshenLocalCharts.sh $chartsRoot

#Extract Caribbean PDFs and convert to TIFF
./rasterize_Caribbean_charts.sh $originalEnrouteDirectory $destinationRoot enroute

#Update our local links to those (possibly new) original files
#This handles charts that have revisions in the filename (sectional, tac etc)
./updateLinks.sh  $originalEnrouteDirectory     $destinationRoot enroute
./updateLinks.sh  $originalGrandCanyonDirectory $destinationRoot grand_canyon
./updateLinks.sh  $originalHeliDirectory        $destinationRoot heli
./updateLinks.sh  $originalSectionalDirectory   $destinationRoot sectional
./updateLinks.sh  $originalTacDirectory         $destinationRoot tac
# ./updateLinks.sh  $originalWacDirectory         $destinationRoot wac

#Clip and georeference insets
./cut_and_georeference_Sectional_insets.pl
./cut_and_georeference_Caribbean_insets.pl $destinationRoot 

# The process*.sh scripts each do these functions for a given chart type
# 	Expand charts to RGB bands as necessary (currently not needed for enroute) via a .vrt file
# 	Clip to their associated polygon
#	Reproject to EPSG:3857
./processEnroute.sh     $originalEnrouteDirectory     $destinationRoot
./processGrandCanyon.sh $originalGrandCanyonDirectory $destinationRoot
./processHeli.sh        $originalHeliDirectory        $destinationRoot
./processSectionals.sh  $originalSectionalDirectory   $destinationRoot
./processTac.sh         $originalTacDirectory         $destinationRoot
# ./processWac.sh         $originalWacDirectory         $destinationRoot

# The tile*.sh scripts each do these functions for a given chart type
# 	create TMS tile tree from the reprojected raster
#       optionally (with -o) use pngquant to optimize each individual tile
#       optionally (with -m) create an mbtile for each individual chart
#add/remove -o to optimize tile size with pngquant
#add/remove -m to create mbtiles
./tileEnrouteHigh.sh    -o -m $destinationRoot
./tileEnrouteLow.sh     -o -m $destinationRoot
./tileGrandCanyon.sh    -o -m $destinationRoot
./tileHeli.sh           -o -m $destinationRoot
./tileSectional.sh      -o -m $destinationRoot
./tileTac.sh            -o -m $destinationRoot
# ./tileWac.sh            -o -m $destinationRoot
./tileInsets.sh         -o -m $destinationRoot

#Stack the various resolutions and types of charts into combined tilesets and mbtiles
#Use these command line options to do/not do specific types of charts and/or create mbtiles 
# -v  Create merged VFR
# -h  Create merged IFR-HIGH
# -l  Create merged IFR-LOW
# -c  Create merged HELICOPTER"
# -m  Create mbtiles for each chart
./mergeCharts.sh -v -h -l -c -m           $destinationRoot   $destinationRoot

exit 0
