#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace
IFS=$(printf '\n\t')   # IFS is newline or tab

# TODO
#   Move towards using VRTs once clipping polygons are established
#   Look at other alternatives for clipping (pixel/line extents)
#   Anywhere we exit, exit with an error code
# Think about unzipping all .TIFFs to one directory?
# find . -type f -iname *.zip -exec sh -c 'unzip -uo -j -d ./tif {} "*.tif"' ';'
# Optimize the mbtile creation process
#	Parallel tiling (distribute amongst local cores, remote machines)
#	Lanczos for resampling
#	Optimizing size of individual tiles via pngcrush, pngquant, optipng etc
#	Linking of redundant tiles
# Automatically clean out old charts, currently they'll just accumulate

# DONE
#   Handle charts that cross anti-meridian
#   Make use of "make" to only process new charts (done via memoize)
    
create_directories() {
    #Create all the directories we need
    local -r BASE_DIRECTORY=$1
    
    local -r baseDirs=(3_expandedRasters 4_clippedRasters 5_warpedRasters 6_tiles 7_mbtiles)
    local -r chartTypes=(caribbean enroute gom grand_canyon heli planning sectional tac insets )

    #Create the tree of output directories  
    for DIR in ${baseDirs[@]};  do
        for CHART_TYPE in ${chartTypes[@]}; do
            # echo "${BASE_DIRECTORY}/${DIR}/${CHART_TYPE}"
            mkdir \
                --parents \
                "${BASE_DIRECTORY}/${DIR}/${CHART_TYPE}"
        done
    done
    
    # Other directories
    mkdir \
        --parents \
        "${BASE_DIRECTORY}/individual_tiled_charts"     \
        "${BASE_DIRECTORY}/merged_tiled_charts"
    }

main() {
    # Get command line parameters
    local -r CHARTS_BASE_DIRECTORY=$(readlink -f "$1")
    local -r ENROUTE_CYCLE="$2"

    # Make sure the destination for our charts exists
    if [ ! -d "$CHARTS_BASE_DIRECTORY" ]; then
        echo "Main: The supplied chart root directory ${CHARTS_BASE_DIRECTORY} doesn't exist"
        exit 1
    fi

    # Create folders in destination directory if they don't already exist
    create_directories "$CHARTS_BASE_DIRECTORY"

#     # Update local chart copies from Aeronav website
#     ./freshenLocalCharts.sh $CHARTS_BASE_DIRECTORY
# 
#     # Unzip all .tifs to one directory and normalize names 
#     # This handles charts that have revisions in the filename (sectional, tac etc)
#     ./unzip_and_normalize.sh $CHARTS_BASE_DIRECTORY
    
    # The process*.sh scripts each do these functions for a given chart type:
    # 	Expand charts to RGB bands as necessary (currently not needed for enroute) via a .vrt file
    # 	Clip to their associated polygon
    #	Reproject to EPSG:3857
    
    # The tile*.sh scripts each do these functions for a given chart type:
    # 	create TMS tile tree from the reprojected raster
    #       optionally (with -o) use pngquant to optimize each individual tile
    #       optionally (with -m) create an mbtile for each individual chart
    #   
    if [ -n "$should_process_caribbean" ]; then
        local -r originalEnrouteDirectory="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/enroute/$ENROUTE_CYCLE"
        
        local -r INPUT_CHART_TYPE="caribbean"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/content/aeronav/Caribbean/"

        # Extract Caribbean PDFs and convert to TIFF
        ./rasterize_Caribbean_charts.sh $originalEnrouteDirectory $CHARTS_BASE_DIRECTORY enroute

        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"

        # Cut out the insets and georeference them
        ./cut_and_georeference_Caribbean_insets.pl \
            $CHARTS_BASE_DIRECTORY    \
            $originalEnrouteDirectory
        
        if [ -n "$should_create_mbtiles" ]; then
             ./tileCaribbean.sh      -m -o $CHARTS_BASE_DIRECTORY
        fi
    fi
    
    if [ -n "$should_process_enroute" ]; then
        
        local -r INPUT_CHART_TYPE="enroute"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/enroute/${ENROUTE_CYCLE}/"

        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"
        
        if [ -n "$should_create_mbtiles" ]; then
            ./tileEnrouteHigh.sh    -m -o $CHARTS_BASE_DIRECTORY
            ./tileEnrouteLow.sh     -m -o $CHARTS_BASE_DIRECTORY
        fi

    fi
    
    if [ -n "$should_process_grand_canyon" ];then
        local -r INPUT_CHART_TYPE="grand_canyon"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/content/aeronav/Grand_Canyon_files/"

        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"
        
        if [ -n "$should_create_mbtiles" ]; then
            ./tileGrandCanyon.sh    -m -o $CHARTS_BASE_DIRECTORY
        fi

    fi

    if [ -n "$should_process_helicopter" ]; then
        local -r INPUT_CHART_TYPE="heli"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/content/aeronav/heli_files/"

        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"
        
        if [ -n "$should_create_mbtiles" ]; then
            ./tileHeli.sh           -m -o $CHARTS_BASE_DIRECTORY
        fi

    fi
        
    if [ -n "$should_process_planning" ]; then

        local -r INPUT_CHART_TYPE="planning"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/content/aeronav/Planning/"


        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"
        
        if [ -n "$should_create_mbtiles" ]; then
            echo "No tiling for planning charts yet"
            exit 1
        fi

    
    fi
    
    if [ -n "$should_process_sectional" ]; then
        local -r INPUT_CHART_TYPE="sectional"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/content/aeronav/sectional_files/"

        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"
        
        
        # Clip and georeference insets
        ./cut_and_georeference_Sectional_insets.pl \
            $CHARTS_BASE_DIRECTORY    \
            $originalEnrouteDirectory
        
        if [ -n "$should_create_mbtiles" ]; then
            ./tileSectional.sh   -m -o $CHARTS_BASE_DIRECTORY
            ./tileInsets.sh      -m -o $CHARTS_BASE_DIRECTORY
        fi

    fi
    
    if [ -n "$should_process_tac" ]; then
        local -r INPUT_CHART_TYPE="tac"
        local -r INPUT_ORIGINAL_DIRECTORY="$CHARTS_BASE_DIRECTORY/aeronav.faa.gov/content/aeronav/tac_files/"

        # Do all processing on this type of chart
        process_charts "${INPUT_CHART_TYPE}" "${INPUT_ORIGINAL_DIRECTORY}"

        # Create mbtiles if requested
        if [ -n "$should_create_mbtiles" ]; then
            ./tileTac.sh    -m -o $CHARTS_BASE_DIRECTORY
        fi

    fi
    


    # Stack the various resolutions and types of charts into combined tilesets and mbtiles
    # Use these command line options to do/not do specific types of charts and/or create mbtiles 
    #  -v  Create merged VFR
    #  -h  Create merged IFR-HIGH
    #  -l  Create merged IFR-LOW
    #  -c  Create merged HELICOPTER"
    #  -m  Create mbtiles for each chart
    #
    # ./mergeCharts.sh -v -h -l -c -m           $CHARTS_BASE_DIRECTORY   $CHARTS_BASE_DIRECTORY

    exit 0
    }

USAGE() {
    echo "Usage: $PROGNAME <options> <charts_root_directory> <latest_enroute_cycle_data_date>" >&2
    echo "    -c  Process CARIBBEAN charts"
    echo "    -e  Process ENROUTE charts"
    echo "    -g  Process GRAND_CANYON charts"
    echo "    -h  Process HELICOPTER charts"
    echo "    -p  Process PLANNING charts"
    echo "    -s  Process SECTIONAL charts"
    echo "    -t  Process TAC charts"
    echo "    -m  Create mbtiles for each chart type as well"
    exit 1
    }

# unzip_freshen() {
#     # Get the number of function parameters
#     local -r NUMARGS=$#
# 
#     # Validate number of function parameters
#     if [ $NUMARGS -ne 1 ] ; then
#         echo "Bad unzip parameters"
#     fi
#     local -r CHARTS_BASE_DIRECTORY="$1"
# 
#     # Unzip any .tif file in any .zip file in the supplied directory
#     # The code at the bottom handles the error code when unzip doesn't find
#     # any .tif files in an archive
#     # "|| true " works as well but masks all errors
#     echo "Unzipping ${CHARTS_BASE_DIRECTORY} files"
#     unzip \
#         -qq \
#         -uo \
#         -j  \
#         -d "${CHARTS_BASE_DIRECTORY}"      \
#         "${CHARTS_BASE_DIRECTORY}/*.zip"   \
#         "*.tif" || \
#             ( error_code=$? && if [ $error_code -ne 11 ]; then exit $error_code; fi )
#     }

# normalize_filename_and_copy_to_source_raster_directory() {
#     # Get the number of function parameters
#     local -r NUMARGS=$#
# 
#     # Validate number of function parameters
#     if [ $NUMARGS -ne 2 ] ; then
#         echo "Bad normalize_filename parameters"
#     fi
#     
#     local -r CHARTS_BASE_DIRECTORY="$1"
#     local -r NORMALIZED_FILE_DESTINATION="$2"
# 
#     # All of the .tif files in the source directory
#     local -r CHART_ARRAY=$(ls -1 ${CHARTS_BASE_DIRECTORY}*.tif)
#     echo "Normalize and copy"
#     for sourceChartName in ${CHART_ARRAY[@]}
#     do
#         # Does this file have georeference info?
#         if gdalinfo "$sourceChartName" -noct | grep -q -P 'PROJCS'
#             then
#                 # Replace non-alpha characters with _ and 
#                 # then strip off the series number and add .tif back on
#                 local SANITIZED_CHART_NAME_WITHOUT_VERSION=($(basename $sourceChartName | 
#                     sed --regexp-extended 's/\W+/_/g'               |
#                     sed --regexp-extended 's/_[0-9]+_tif$/\.tif/ig' |
#                     sed --regexp-extended 's/_tif$/\.tif/ig'))
# 
#                 # echo "Latest $sourceChartName, calling it $SANITIZED_CHART_NAME_WITHOUT_VERSION"
#                 # Copy this file if it's newer than what is already there
#                 cp \
#                     --update    \
#                     --verbose   \
#                     "$sourceChartName"    \
#                     "${NORMALIZED_FILE_DESTINATION}/${SANITIZED_CHART_NAME_WITHOUT_VERSION}"
#         fi
#     done
#     }
    
expand_to_rgb(){
    # Get the number of function parameters
    local -r NUMARGS=$#

    # Validate number of function parameters
    if [ $NUMARGS -ne 2 ] ; then
        echo "Bad expand_to_rgb parameters"
    fi
    
    local -r NORMALIZED_FILE_DIRECTORY="$1"
    local -r EXPANDED_FILE_DESTINATION="$2"

    local -A ALL_CHARTS
    
    # All of the .tif files in the source directory
#     local -r NORMALIZED_CHART_ARRAY=(ls -1 ${NORMALIZED_FILE_DIRECTORY}*.tif)

    caribbean_files=("${NORMALIZED_FILE_DIRECTORY}"/Caribbean*.tif)    
    enroute_files=(
                    "${NORMALIZED_FILE_DIRECTORY}"/ENR_L*.tif   \
                    "${NORMALIZED_FILE_DIRECTORY}"/ENR_H*.tif   \
                    "${NORMALIZED_FILE_DIRECTORY}"/ENR_AKL*.tif \
                    "${NORMALIZED_FILE_DIRECTORY}"/ENR_AKH*.tif \
                    "${NORMALIZED_FILE_DIRECTORY}"/ENR_A0*.tif  \
                    "${NORMALIZED_FILE_DIRECTORY}"/ENR_P0*.tif  \
                    "${NORMALIZED_FILE_DIRECTORY}"/narc.tif  \
                    "${NORMALIZED_FILE_DIRECTORY}"/porc.tif  \
                    "${NORMALIZED_FILE_DIRECTORY}"/watrs.tif  \
                    )
    gom_files=("${NORMALIZED_FILE_DIRECTORY}"/GOM_*.tif)
    grand_canyon_files=("${NORMALIZED_FILE_DIRECTORY}"/Grand_Canyon*.tif)
    heli_files=("${NORMALIZED_FILE_DIRECTORY}"/*_HEL.tif)
    planning_files=("${NORMALIZED_FILE_DIRECTORY}"/*_Planning*.tif  \
                            "${NORMALIZED_FILE_DIRECTORY}"/*_PLAN_*.tif  \
                            )
    sectional_files=("${NORMALIZED_FILE_DIRECTORY}"/*_SEC.tif)
    tac_files=("${NORMALIZED_FILE_DIRECTORY}"/*_TAC.tif)
#     insets_files=("${NORMALIZED_FILE_DIRECTORY}/*.tif")

    
#     for sourceChartName in ${NORMALIZED_CHART_ARRAY[@]}; do
for sourceChartType in caribbean_files  enroute_files   gom_files grand_canyon_files  heli_files  planning_files  sectional_files tac_files; do
    looparray="$sourceChartType[@]"
    for sourceChartName in "${!looparray}"; do
       echo "*** Expand --- gdal_translate $sourceChartName"

        local fbname=$(basename "$sourceChartName" | cut -d. -f1)
        
        if gdalinfo "${sourceChartName}" -noct | grep -q 'Color Table'
        then
            echo "***  ${sourceChartName} has color table, need to expand to RGB"
            ./memoize.py -t \
                gdal_translate \
                    -expand rgb         \
                    -strict             \
                    -of VRT             \
                    -co TILED=YES       \
                    -co COMPRESS=LZW    \
                    "${sourceChartName}" \
                     "${EXPANDED_FILE_DESTINATION}/${fbname}.vrt"
        else
            echo "***  ${sourceChartName} does not have color table, do not need to expand to RGB"
            ./memoize.py -t \
                gdal_translate      \
                -strict             \
                -of VRT             \
                -co TILED=YES       \
                -co COMPRESS=LZW    \
                "${sourceChartName}" \
                "${EXPANDED_FILE_DESTINATION}/${fbname}.vrt"
        fi

        # #Create external overviews to make display faster in QGIS
        # echo "***  Overviews for Expanded File --- gdaladdo $sourceChartName"
        # 
        # ./memoize.py -t \
        #     gdaladdo        \
        #         -ro         \
        #         -r gauss    \
        #         --config INTERLEAVE_OVERVIEW PIXEL      \
        #         --config COMPRESS_OVERVIEW JPEG         \
        #         --config BIGTIFF_OVERVIEW IF_NEEDED     \
        #         "$expandedRastersDirectory/$sourceChartName.vrt" \
        #         2 4 8 16 32 64
        done
    done
    exit
    }

test_directories(){
    # Make sure all supplied directories exist
    for directory in "$@"
    do
        if [ ! -d "$directory" ]; then
            echo "test_directories: $directory doesn't exist"
            exit 1
        fi
    done
   
  
    }
    
warp_and_clip(){
    # Get the number of function parameters
    local -r NUMARGS=$#

    # Validate number of function parameters
    if [ $NUMARGS -ne 4 ] ; then
        echo "bad warp_and_clip parameters"
    fi
    
    
    local -r EXPANDED_FILE_SOURCE="$1"
    local -r CLIPPED_FILE_DIRECTORY="$2"
    local -r WARPED_RASTERS_DIRECTORY="$3"
    local -r CLIPPING_SHAPES_DIRECTORY="$4"
    
    # All of the .tif files in the source directory
    local -r EXPANDED_CHART_ARRAY=$(ls -1 ${EXPANDED_FILE_SOURCE}*.vrt)
    
    #1) Clip the source file first then 
    #2) warp to EPSG:3857 so that final output pixels are square
    #----------------------------------------------

    for sourceChartName in ${EXPANDED_CHART_ARRAY[@]}; do        
        # Get the file name without extension
        local fbname=$(basename "$sourceChartName" | cut -d. -f1)
            
        #Clip the file it to its clipping shape
        echo "*** Clip to vrt --- gdalwarp $sourceChartName"
        
        # Make sure we have a clipping shape for this file
        if [ ! -f "$CLIPPING_SHAPES_DIRECTORY/${fbname}.shp" ]; then
            echo "No clipping shape for ${fbname}.shp"
            exit 1
        fi
        
        # BUG TODO crop_to_cutline results in a resampled image with non-square pixels
        # How to best handle this?  One fix is an additional warp to EPSG:3857
        # Do I need -dstalpha here?  That adds a band, I just want to re-use the existing one
        time \
            nice -10 \
                $PROGDIR/memoize.py -t \
                    gdalwarp \
                        -of vrt     \
                        -overwrite  \
                        -cutline "$CLIPPING_SHAPES_DIRECTORY/${fbname}.shp" \
                        -crop_to_cutline \
                        -cblend 10  \
                        -r lanczos  \
                        -dstalpha   \
                        -co ALPHA=YES \
                        -co TILED=YES \
                        -multi \
                        -wo NUM_THREADS=ALL_CPUS  \
                        -wm 1024 \
                        --config GDAL_CACHEMAX 1024 \
                        "$EXPANDED_FILE_SOURCE/${fbname}.vrt" \
                        "$CLIPPED_FILE_DIRECTORY/${fbname}.vrt"

        #Warp the expanded file
        echo "*** Warp to vrt --- gdalwarp $sourceChartName"

        time \
            nice -10 \
                $PROGDIR/memoize.py  -t \
                    gdalwarp \
                        -of vrt \
                        -t_srs EPSG:3857 \
                        -r lanczos \
                        -overwrite \
                        -multi \
                        -wo NUM_THREADS=ALL_CPUS  \
                        -wm 1024 \
                        --config GDAL_CACHEMAX 1024 \
                        -co TILED=YES \
                        "$CLIPPED_FILE_DIRECTORY/${fbname}.vrt" \
                        "$WARPED_RASTERS_DIRECTORY/${fbname}.vrt"

        echo "***  Create tif --- gdal_translate $sourceChartName"
        #If you want to make the files smaller, at the expense of CPU, you can enable these options
        #      -co COMPRESS=DEFLATE \
        #      -co PREDICTOR=1 \
        #      -co ZLEVEL=9 \
        # or do just:
        #       -co COMPRESS=LZW \
        time \
            nice -10 \
                $PROGDIR/memoize.py -t \
                    gdal_translate      \
                        -strict         \
                        -co TILED=YES   \
                        -co COMPRESS=DEFLATE    \
                        -co PREDICTOR=1         \
                        -co ZLEVEL=9            \
                        --config GDAL_CACHEMAX 1024 \
                        "$WARPED_RASTERS_DIRECTORY/${fbname}.vrt" \
                        "$WARPED_RASTERS_DIRECTORY/${fbname}.tif"


        #Create external overviews to make display faster in QGIS
        echo "***  Overviews --- gdaladdo $sourceChartName"
        time \
            nice -10 \
                $PROGDIR/memoize.py -t \
                    gdaladdo \
                        -ro \
                        -r average \
                        --config INTERLEAVE_OVERVIEW PIXEL \
                        --config COMPRESS_OVERVIEW JPEG \
                        --config BIGTIFF_OVERVIEW IF_NEEDED \
                        "$WARPED_RASTERS_DIRECTORY/${fbname}.tif" \
                        2 4 8 16 32 64
    done
    }

process_charts(){
    # Get the number of function parameters
    local -r NUMARGS=$#

    # Validate number of function parameters
    if [ $NUMARGS -ne 2 ] ; then
        echo "Bad process_charts parameters"
    fi
    # What type of chart we're processing
    local -r INPUT_CHART_TYPE="$1"
    
    # Where those charts are
    local -r ORIGINAL_DIRECTORY="$2"
    
#     local -r NORMALIZED_RASTERS_DIRECTORY="$CHARTS_BASE_DIRECTORY/sourceRasters/$INPUT_CHART_TYPE/"
    local -r NORMALIZED_RASTERS_DIRECTORY="$CHARTS_BASE_DIRECTORY/2_normalized/"
    local -r EXPANDED_RASTERS_DIRECTORY="$CHARTS_BASE_DIRECTORY/3_expandedRasters/$INPUT_CHART_TYPE/"
    local -r CLIPPED_RASTERS_DIRECTORY="$CHARTS_BASE_DIRECTORY/4_clippedRasters/$INPUT_CHART_TYPE/"
    local -r WARPED_RASTERS_DIRECTORY="$CHARTS_BASE_DIRECTORY/5_warpedRasters/$INPUT_CHART_TYPE/"
    
    local -r CLIPPING_SHAPES_DIRECTORY="${PROGDIR}/clippingShapes/$INPUT_CHART_TYPE/"
        
    # Make sure all of our directories exist
    test_directories \
        "${ORIGINAL_DIRECTORY}"             \
        "${NORMALIZED_RASTERS_DIRECTORY}"   \
        "${EXPANDED_RASTERS_DIRECTORY}"     \
        "${CLIPPED_RASTERS_DIRECTORY}"      \
        "${WARPED_RASTERS_DIRECTORY}"       \
        "${CLIPPING_SHAPES_DIRECTORY}"
    
#     # Unzip source TIFFs if needed
#     unzip_freshen   \
#         "${ORIGINAL_DIRECTORY}"
#     
#     # Remove spaces and file version from filename of georeferenced .tifs in the source directory
#     # Then copy to another directory to use as source
#     normalize_filename_and_copy_to_source_raster_directory  \
#         "${ORIGINAL_DIRECTORY}" \
#         "${NORMALIZED_RASTERS_DIRECTORY}"

    # Expand input file to RGB if needed
    expand_to_rgb   \
        "${NORMALIZED_RASTERS_DIRECTORY}"   \
        "${EXPANDED_RASTERS_DIRECTORY}"
    
    # Warp the file to 3875 SRS and clip it
    warp_and_clip   \
        "${EXPANDED_RASTERS_DIRECTORY}" \
        "${CLIPPED_RASTERS_DIRECTORY}"  \
        "${WARPED_RASTERS_DIRECTORY}"   \
        "${CLIPPING_SHAPES_DIRECTORY}"
    }

# The script begins here
# Set some basic variables
declare -r PROGNAME=$(basename $0)
declare -r PROGDIR=$(readlink -m $(dirname $0))
declare -r ARGS="$@"

# Set fonts for Help.
declare -r NORM=$(tput sgr0)
declare -r BOLD=$(tput bold)
declare -r REV=$(tput smso)

# Variables to indicate which charts to process
should_process_caribbean=''
should_process_enroute=''
should_process_grand_canyon=''
should_process_helicopter=''
should_process_planning=''
should_process_sectional=''
should_process_tac=''
should_create_mbtiles=''

# Set variables from command line options
while getopts 'ceghpstm' flag; do
  case "${flag}" in
    c) should_process_caribbean='true' ;;
    e) should_process_enroute='true' ;;
    g) should_process_grand_canyon='true' ;;
    h) should_process_helicopter='true' ;;
    p) should_process_planning='true' ;;
    s) should_process_sectional='true' ;;
    t) should_process_tac='true' ;;
    m) should_create_mbtiles='true' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

#Remove the flag operands
shift $((OPTIND-1))

#Get the number of remaining command line arguments
NUMARGS=$#

#Validate number of command line parameters
if [ $NUMARGS -ne 2 ] ; then
    USAGE
fi

# Call the main routine
main "$@"
exit 0
