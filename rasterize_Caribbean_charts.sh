#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts
shopt -s nullglob

#1. Get Caribbean charts from https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr/#caribbean
#2. Unzip the PDFs
#       unzip "*.zip"

if [ "$#" -ne 3 ] ; then
  echo "Usage: $0 SOURCE_DIRECTORY destinationRoot chartType" >&2
  exit 1
fi

#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"
chartType="$3"

#For files that have a version in their name, this is where the links to the lastest version
#will be stored (step 1)
linkedRastersDirectory="$destinationRoot/sourceRasters/$chartType/"

#Where expanded rasters are stored (step 2)
expandedRastersDirectory="$destinationRoot/expandedRasters/$chartType/"

#Where clipped rasters are stored (step 3)
clippedRastersDirectory="$destinationRoot/clippedRasters/$chartType/"

# #Where the polygons for clipping are stored
# clippingShapesDirectory="$destinationRoot/clippingShapes/$chartType/"



if [ ! -d "$originalRastersDirectory" ]; then
    echo "$originalRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d "$linkedRastersDirectory" ]; then
    echo "$linkedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d "$expandedRastersDirectory" ]; then
    echo "$expandedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d "$clippedRastersDirectory" ]; then
    echo "$clippedRastersDirectory doesn't exist"
    exit 1
fi

#Get our initial directory as it is where memoize.py is located
pushd $(dirname "$0") > /dev/null
installedDirectory=$(pwd)
popd > /dev/null

cd "$originalRastersDirectory"
#Ignore unzipping errors
set +e
#Unzip the Caribbean PDFs
echo "Unzipping $chartType files for Caribbean"
unzip -qq -u -j "delcb*.zip" "*.pdf"
#Restore quit on error
set -e

#Convert them to .tiff
for f in ENR_C[AL]0[0-9].pdf
do
    if [ -f "$f.tif" ]
	then
		echo "Rasterized $f already exists"
		continue  
	fi
	
    echo "Converting $f to raster"
    #Needs to point to where memoize is
    $installedDirectory/memoize.py -t \
    gs \
        -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT \
        -sDEVICE=tiff24nc                               \
        -sOutputFile="$f-untiled.tif"                             \
        -r300 \
        -dTextAlphaBits=4 \
        -dGraphicsAlphaBits=4 \
         "$f"
#     
# #     #The -dMaxBitmap=2147483647 is to work around transparency bug
# #     #See http://stackoverflow.com/questions/977540/convert-a-pdf-to-a-transparent-png-with-ghostscript
# #     gs \
# #         -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT \
# #         -sDEVICE=pngalpha                               \
# #         -sOutputFile="$f.png"                           \
# #         -r300 \
# #         -dTextAlphaBits=4 \
# #         -dGraphicsAlphaBits=4 \
# #         -dMaxBitmap=2147483647 \
# #         "$f"
#     
    echo "Tile $f"
    #Needs to point to where memoize is
    $installedDirectory/memoize.py -t \
    gdal_translate \
                -strict \
                -co TILED=YES \
                -co COMPRESS=LZW \
                "$f-untiled.tif" \
                "$f.tif"

    echo "Overviews $f"
    #Needs to point to where memoize is
    $installedDirectory/memoize.py -t \
    gdaladdo \
            -ro \
            -r gauss \
            --config INTERLEAVE_OVERVIEW PIXEL \
            --config COMPRESS_OVERVIEW JPEG \
            --config BIGTIFF_OVERVIEW IF_NEEDED \
            "$f.tif" \
            2 4 8 16 32 64
    
    rm "$f-untiled.tif"
    
done

exit
# 
# #Remove current links if any exist
# #FILTER will be empty if no .tifs
# FILTER=$(find $linkedRastersDirectory/ -type l \( -name "*.tif" \) )
# 
# if [[ ! -z ${FILTER} ]]; then
#     echo "Deleting $chartType  links"
# #     echo $FILTER
#     rm $FILTER
# fi
# 
# #Link latest revision of chart as a base name
# echo Linking $chartType files
# shopt -s nullglob	
# for f in *.tif
# do
# 	#Santize $f into $newName
# 	
# 	newName=$f
# 	# 	#Replace non-word in name with _
# 	# 	newName=($(printf $newName | sed --regexp-extended 's/\W+/_/g'))
# 	# 	
# 	# 	#Fix the extension munged by above
# 	# 	newName=($(printf $newName | sed --regexp-extended 's/_tif/\.tif/ig'))
# 	
#  	#Replace spaces in name with _
# 	newName=($(printf $newName | sed --regexp-extended 's/\s+/_/g'))
# 
# 	#Strip off the series number
# 	newName=($(printf $newName | sed --regexp-extended 's/_[0-9]+\./\./ig'))
# 
# 	#Link $newName to $f only if $f is newer
# 	if [ "$f" -nt "$linkedRastersDirectory/$newName" ]; then
# 	   echo "$f is newer than $linkedRastersDirectory/$newName"
# 	   ln -s -f -r "$f" "$linkedRastersDirectory/$newName"
# 	   touch -h -r "$f" "$linkedRastersDirectory$newName"
# 	fi
# 	
# done





