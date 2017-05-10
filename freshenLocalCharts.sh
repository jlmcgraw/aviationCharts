#!/bin/bash
set -eu                 # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')    # Always put this in Bourne shell scripts

# Download latest charts from faa/aeronav

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
    echo "Usage: $PROGNAME <where_to_save_charts>" >&2
    exit 1
fi

# Get command line parameter
AERONAV_ROOT_DIR=$(readlink -f "$1")

if [ ! -d $AERONAV_ROOT_DIR ]; then
    echo "$AERONAV_ROOT_DIR doesn't exist"
    exit 1
fi

# Exit if we ran this command within the last 24 hours (adjust as you see fit)
if [ -e "${PROGDIR}/lastChartRefresh" ] && [ $(date +%s -r "${PROGDIR}/lastChartRefresh") -gt $(date +%s --date="24 hours ago") ]; then
 echo "Charts updated within last 24 hours, exiting"
 exit 0
fi 

# Update the time of this file so we can check when we ran this last
touch "${PROGDIR}/lastChartRefresh"

# Test local .zips in the $CHARTS_BASE_DIRECTORY tree and delete any bad ones so
# we can get fresh ones from FAA
find    \
    "$AERONAV_ROOT_DIR"         \
    -iname '*.zip'              \
    -type f                     \
    -readable !                 \
    -exec unzip -q -t {} \;     \
    -exec rm -i {} \;
    
    
# Get all of the latest charts
# Skip the compilations
set +e
wget \
    --directory-prefix=$AERONAV_ROOT_DIR    \
    --recursive     \
    -l1             \
    --span-hosts    \
    --domains=aeronav.faa.gov,www.faa.gov   \
    --timestamping  \
    --no-parent     \
    -A.zip          \
    -R"DD?C*"       \
    -erobots=off    \
    http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr

wget \
    --directory-prefix=$AERONAV_ROOT_DIR    \
    --recursive     \
    -l1             \
    --span-hosts    \
    --domains=aeronav.faa.gov,www.faa.gov   \
    --timestamping  \
    --no-parent     \
    -A.zip          \
    -R"DD?C*"       \
    -erobots=off    \
    http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr
set -e
