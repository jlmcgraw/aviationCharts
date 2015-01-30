#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Download latest charts from faa/aeronav

#Get command line parameters
AERONAV_ROOT_DIR="$1"

if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 AERONAV_ROOT_DIR" >&2
  exit 1
fi

if [ ! -d $AERONAV_ROOT_DIR ]; then
    echo "$AERONAV_ROOT_DIR doesn't exist"
    exit 1
fi

cd $AERONAV_ROOT_DIR

#Get all of the latest charts
set +e
wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr
echo ######################################
wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr
set -e

