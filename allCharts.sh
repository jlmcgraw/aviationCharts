
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

#-------------------------------------------------------------------------------
#Things you may need to edit
#Full path to root of where aeronav site will be mirrored to via wget
chartsRoot="/media/sf_Shared_Folder/charts"

#BUG TODO This will need to be updated for every new enroute charting cycle
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/10-15-2015/"



#-------------------------------------------------------------------------------
#Shouldn't need to edit below here
if [ ! -d "$chartsRoot" ]; then
    echo "chart root folder $chartsRoot doesn't exist.  Please edit $0 to update it"
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
./updateLinks.sh  $originalWacDirectory         $destinationRoot wac

#Clip and georeference the Caribbean enroute charts and their insets
./cut_and_georeference_Caribbean.pl $destinationRoot 

# General Process:
# 	Expand charts to RGB bands as necessary (currently not needed for enroute) via a .vrt file
# 	Clip to their associated polygon
#	Reproject to EPSG:3857
# 	Convert clipped and warped image to TMS layout folders of tiles
# 	Package those tiles into a .mbtile

./processEnroute.sh     $originalEnrouteDirectory     $destinationRoot
./processGrandCanyon.sh $originalGrandCanyonDirectory $destinationRoot
./processHeli.sh        $originalHeliDirectory        $destinationRoot
./processSectionals.sh  $originalSectionalDirectory   $destinationRoot
./processTac.sh         $originalTacDirectory         $destinationRoot
./processWac.sh         $originalWacDirectory         $destinationRoot

#Create tiles and merged charts with tiler_tools
./tileEnrouteHigh.sh $destDir
./tileEnrouteLow.sh $destDir
./tileGrandCanyon.sh $destDir
./tileHeli.sh $destDir
./tileSectional.sh $destDir
./tileTac.sh $destinationRoot
./tileWac.sh $destDir
