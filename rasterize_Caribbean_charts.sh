#!/bin/bash
set -eu                 # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')    # Always put this in Bourne shell scripts
shopt -s nullglob

#1. Get Caribbean charts from https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr/#caribbean
#2. Unzip the PDFs
#       unzip "*.zip"

if [ "$#" -ne 3 ] ; then
  echo "Usage: $0 <SOURCE_DIRECTORY> <destinationRoot> <chartType>" >&2
  exit 1
fi

#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"
chartType="$3"

output_raster_path="${destinationRoot}/2_normalized/"

if [ ! -d "$originalRastersDirectory" ]; then
    echo "$originalRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d "$output_raster_path" ]; then
    echo "$output_raster_path doesn't exist"
    exit 1
fi

#Get our initial directory as it is where memoize.py is located
pushd "$(dirname "$0")" > /dev/null
installedDirectory=$(pwd)
popd > /dev/null

echo "Change directory to $originalRastersDirectory"

cd "$originalRastersDirectory"

# Ignore unzipping errors
set +e
    # Unzip the Caribbean PDFs
    echo "Unzipping $chartType files for Caribbean"
    unzip -qq -u -j "delcb*.zip" "*.pdf"
    # Restore quit on error
set -e

# Convert them to .tiff
for f in ENR_C[AL]0[0-9].pdf
do
    if [ -f "$f.tif" ]
	then
            echo "Rasterized $f already exists"
            continue  
	fi
    echo "--------------------------------------------"
    echo "Converting $f to raster"
    echo "--------------------------------------------"
    
    # Needs to point to where memoize is
    "${installedDirectory}/memoize.py" -t                       \
        gs                                                      \
            -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT     \
            -sDEVICE=tiff24nc                                   \
            -sOutputFile="$output_raster_path/$f-untiled.tif"   \
            -r300                                               \
            -dTextAlphaBits=4                                   \
            -dGraphicsAlphaBits=4                               \
            "$f"

    echo "--------------------------------------------"
    echo "Tile $f"
    echo "--------------------------------------------"
    
    # Needs to point to where memoize is
    "$installedDirectory/memoize.py" -t                      \
        gdal_translate                                      \
                    -strict                                 \
                    -co TILED=YES                           \
                    -co COMPRESS=LZW                        \
                    "$output_raster_path/$f-untiled.tif"    \
                    "$output_raster_path/$f.tif"
                
    echo "--------------------------------------------"
    echo "Overviews $f"
    echo "--------------------------------------------"
    
    # Needs to point to where memoize is
    "$installedDirectory/memoize.py" -t             \
        gdaladdo                                    \
                -ro                                 \
                -r gauss                            \
                --config INTERLEAVE_OVERVIEW PIXEL  \
                --config COMPRESS_OVERVIEW JPEG     \
                --config BIGTIFF_OVERVIEW IF_NEEDED \
                "$output_raster_path/$f.tif"        \
                2 4 8 16 32 64
    
#     rm "$output_raster_path/$f-untiled.tif"
    
done

exit 0
