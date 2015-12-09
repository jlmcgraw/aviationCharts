#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Download latest charts from faa/aeronav

#Get command line parameters
AERONAV_ROOT_DIR="$1"

if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 <where_to_save_charts>" >&2
  exit 1
fi

if [ ! -d $AERONAV_ROOT_DIR ]; then
    echo "$AERONAV_ROOT_DIR doesn't exist"
    exit 1
fi

#Exit if we ran this command within the last 24 hours (adjust as you see fit)
if [ -e ./lastChartRefresh ] && [ $(date +%s -r ./lastChartRefresh) -gt $(date +%s --date="24 hours ago") ]; then
 echo "Charts updated within last 24 hours, exiting"
 exit
fi 

#Update the time of this file so we can check when we ran this last
touch ./lastChartRefresh

cd $AERONAV_ROOT_DIR

#Get all of the latest charts
set +e
wget --recursive -l1 --span-hosts --domains=aeronav.faa.gov,www.faa.gov --timestamping --no-parent -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr
echo ######################################
wget --recursive -l1 --span-hosts --domains=aeronav.faa.gov,www.faa.gov --timestamping --no-parent -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr
set -e


