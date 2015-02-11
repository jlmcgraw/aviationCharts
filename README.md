The purpose of this utility is to process the freely provided FAA/Aeronav 
digital aviation charts from GeoTiffs into seamless mbtiles suitable for use in mapping 
applications.

It has only been tested under Ubuntu 14.10

![Sectionals](https://raw.github.com/jlmcgraw/aviationCharts/master/sectional.png)
![Enroute Low](https://raw.github.com/jlmcgraw/aviationCharts/master/enroute-low.png)
![Enroute Low with oceanic](https://raw.github.com/jlmcgraw/aviationCharts/master/enroute-low with oceanic.png)
![WAC](https://raw.github.com/jlmcgraw/aviationCharts/master/wac.png)

# TODO
    - Handle charts which cross the anti-meridian
    - Pull out insets and georeference them as necessary
    - Pursue a multithreaded gdal2tiles that can auto determine zoom levels
    - Use make to update only as necessary 

# Requirements
    - gdal (sudo apt-get install gdal-bin)
    - wget
    - pngquant (sudo apt-get install pngquant)
    - graphicsmagick (sudo apt-get install graphicsmagick)
    - mbutil (git clone https://github.com/mapbox/mbutil.git)
    - gdal2tiles multithreaded version (git clone https://github.com/jlmcgraw/parallelGdal2tiles.git)

# Getting Started
##### Edit allCharts.sh and update variables and create the corresponding directories as needed
```
#Full path to root of downloaded chart info
chartsRoot="/media/sf_Shared_Folder/charts/"
```
##### Update this information as appropriate for dirname of current enroute chart cycle
```
#This will need to be updated for every cycle
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/01-08-2015/"
```
##### Edit makeMbtiles.sh to update the location of these commands on your system
```
~/Documents/myPrograms/parallelGdal2Tiles/gdal2tiles.py
~/Documents/github/mbutil/mb-util
```
##### Create the directory tree	
```
./createTree.sh
```
##### Execute allCharts.sh	
```
./allCharts.sh
```
##### Wait a very long time (assuming all went correctly)
##### Mbtiles should be in ./mbtiles directory
