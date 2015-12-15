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
    - gdal 1.10+
    - wget
    - pngquant 
    - graphicsmagick 
    - mbutil 
    - ~200 Gigabytes of free storage
    
# Getting Started
##### Install various utilities and libraries and create directories
```
./setup.sh
```
##### Determine the date of the latest set of enroute charts.  It will be a directory under "enroute"
##### This will need to be updated for every new cycle
```

    eg 12-10-2015
```
##### Edit paths to these utilities as necessary in the tile*.sh scripts
##### If you use setup.sh they will be cloned from github into this directory so no editing will be necessary
```
./parallelGdal2Tiles/gdal2tiles.py
./mbutil/mb-util
./tilers_tools/
```
##### Edit allCharts.sh to add/remove various options for tile creation and merging
    - Using -o will optimize individual tile size
    - Using -m will create mbtiles for individual and merged charts
    
    Note that both of these will add some significant time to the overall process

##### Execute allCharts.sh with correct parameters
```
./allCharts.sh /path/to/aeronav_charts date_of_enroute_set
    eg. ./allCharts.sh /home/test/Downloads/aeronav 12-10-2015
```
##### Wait a very long time (assuming all went correctly)
##### Individual charts should be in ./individual_tiled_charts/
##### merged charts should be in ./merged_tiled_charts/
