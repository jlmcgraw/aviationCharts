#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Get all of the latest charts
set +e
wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr
echo ######################################
wget -r -l1 -H -N -np -A.zip -erobots=off http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/ifr
set -e

# Get a quick listing of files without the extentions
# #ls -1 | sed -e 's/\.tif//g'
# 
# #Unzip all of the sectional charts
# unzip -u -j "*.zip" "*.tif"