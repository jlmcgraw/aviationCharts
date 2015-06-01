#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Install various utilities
sudo apt-get install gdal-bin libmodern-perl-perl pngquant graphicsmagick

#Get some utilities
git clone https://github.com/jlmcgraw/parallelGdal2tiles.git
git clone https://github.com/mapbox/mbutil.git
git clone https://github.com/jlmcgraw/tilers_tools.git

#Create directories
# ./createTree.sh