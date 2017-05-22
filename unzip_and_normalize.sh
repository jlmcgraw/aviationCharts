#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace
IFS=$(printf '\n\t')   # IFS is newline or tab

main() {
    # Get the number of function parameters
    local -r NUMARGS=$#
    
    # Get the base directory of where source charts are
    local -r chartsRoot=$(readlink -f "$1")
    
    # Set our destination directories
    local -r UNZIP_DESTINATION_ABSOLUTE_PATH=$(readlink -f "${chartsRoot}/1_all_tifs/")
    local -r NORMALIZED_FILE_DESTINATION_ABSOLUTE_PATH=$(readlink -f "${chartsRoot}/2_normalized/")

    # Unzip every .tif in every .zip, overwriting older files when needed
    unzip_freshen "${chartsRoot}" "${UNZIP_DESTINATION_ABSOLUTE_PATH}"

    # copy/move/link georeferenced tifs another directory with normalized names
    normalize "${UNZIP_DESTINATION_ABSOLUTE_PATH}" "${NORMALIZED_FILE_DESTINATION_ABSOLUTE_PATH}"

    }
    
unzip_freshen() {
    # Get the number of function parameters
    local -r NUMARGS=$#

    # Validate number of function parameters
    if [ $NUMARGS -ne 2 ] ; then
        echo "Bad unzip parameters"
    fi
    local -r chartsRoot="$1"
    local -r UNZIP_DESTINATION_ABSOLUTE_PATH="$2"

    mkdir --parents "${UNZIP_DESTINATION_ABSOLUTE_PATH}"
    
    # Unzip any .tif file in any .zip file in the supplied directory
    echo "Unzipping all .zip files under ${chartsRoot} to ${UNZIP_DESTINATION_ABSOLUTE_PATH}"
    
    find ${chartsRoot}      \
        -type f             \
        -iname "*.zip"      \
        -exec unzip -uo -j -d "${UNZIP_DESTINATION_ABSOLUTE_PATH}" "{}" "*.tif" \;
    }

normalize() {
    # Get the number of function parameters
    local -r NUMARGS=$#
    
    # Validate number of function parameters
    if [ $NUMARGS -ne 2 ] ; then
        echo "Bad normalize parameters"
    fi
    
    local -r UNZIP_DESTINATION_ABSOLUTE_PATH="$1"
    local -r NORMALIZED_FILE_DESTINATION_ABSOLUTE_PATH="$2"
    
    # Where we'll put normalized files
    mkdir --parents "${NORMALIZED_FILE_DESTINATION_ABSOLUTE_PATH}"
    
    # All of the .tif files in the source directory
    local -r CHART_ARRAY=("${UNZIP_DESTINATION_ABSOLUTE_PATH}/*.tif")
    
    echo "Normalize and copy"
    for SOURCE_CHART_ABSOLUTE_NAME in ${CHART_ARRAY[@]}
    do
        # Does this file have georeference info?
        if gdalinfo "$SOURCE_CHART_ABSOLUTE_NAME" -noct | grep -q -P 'PROJCS'
            then
                # Replace non-alpha characters with _ and 
                # then strip off the series number and add .tif back on
                local SANITIZED_CHART_NAME_WITHOUT_VERSION=($(basename $SOURCE_CHART_ABSOLUTE_NAME | 
                    sed --regexp-extended 's/\W+/_/g'               |
                    sed --regexp-extended 's/_[0-9]+_tif$/\.tif/ig' |
                    sed --regexp-extended 's/_tif$/\.tif/ig'))

                # echo "Latest $SOURCE_CHART_ABSOLUTE_NAME, calling it $SANITIZED_CHART_NAME_WITHOUT_VERSION"
                # Copy/move/link this file if it's newer than what is already there
                mv \
                    --update    \
                    --verbose   \
                    "$SOURCE_CHART_ABSOLUTE_NAME"    \
                    "${NORMALIZED_FILE_DESTINATION_ABSOLUTE_PATH}/${SANITIZED_CHART_NAME_WITHOUT_VERSION}"
        fi
    done
    echo "Finished Normalize and copy"
    }
    
USAGE() {
    echo "Unzip and normalize chart names"
    echo "Usage: $PROGNAME <charts_root_directory> <normalized_directory>" >&2
    exit 1
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

#Get the number of remaining command line arguments
NUMARGS=$#

#Validate number of command line parameters
if [ $NUMARGS -ne 1 ] ; then
    USAGE
fi

# Call the main routine
main "$@"
exit 0
