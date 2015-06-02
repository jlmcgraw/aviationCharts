The purpose of this utility is to process the freely provided FAA/Aeronav 
digital aviation charts from GeoTiffs into seamless mbtiles suitable for use in mapping 
applications.

It has only been tested under Ubuntu 14.10+

![Sectionals](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/sectional.png)
![Enroute Low](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/enroute-low.png)
![Enroute Low with oceanic](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/enroute-low with oceanic.png)
![WAC](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/wac.png)

# TODO    


# DONE
    - Handle charts which cross the anti-meridian (tilers_tools handles this)
    - Pull out insets and georeference them as necessary
    - Pursue a multithreaded gdal2tiles that can auto determine zoom levels
    - Use make to update only as necessary  (done via memoize.py)
        
# Requirements
    - gdal 
    - wget
    - pngquant 
    - graphicsmagick 
    - mbutil 
    - gdal2tiles multithreaded version 

# Getting Started
##### Install various utilities and libraries and create directories
```
./setup.sh
```
##### Edit allCharts.sh and update variables 
##### Create the corresponding directories as needed
```
#Full path to root of downloaded chart info
chartsRoot="/media/sf_Shared_Folder/charts/"
```
##### Update this information as appropriate for directory name of current enroute chart cycle under "chartsRoot" directory
```
#This will need to be updated for every cycle
originalEnrouteDirectory="$chartsRoot/aeronav.faa.gov/enroute/01-08-2015/"
```
##### Edit makeMbtiles.sh as necessary to update the location of these commands on your system
##### If you use setup.sh they will be cloned from github into this directory so no editing will be necessary
```
./parallelGdal2Tiles/gdal2tiles.py
./mbutil/mb-util
./tilers_tools/
```
##### Execute allCharts.sh
```
./allCharts.sh
```
##### Wait a very long time (assuming all went correctly)
##### Mbtiles should be in ./mbtiles directory
##### tilers_tools output will be in ./tiles2 and various merged charts with a web viewing application will be in subdirectories under project root
