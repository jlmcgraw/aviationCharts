The purpose of this utility is to process the freely provided FAA/Aeronav
digital aviation charts from GeoTiffs into seamless rasters, tiles, and mbtiles suitable for
direct use in mapping applications

It has only been tested under Ubuntu 14.10+

![VFR](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/VFR.png)
![Enroute Low](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/IFR_Low.png)
![Enroute High](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/IFR_High.png)
![Oceanic](https://raw.github.com/jlmcgraw/aviationCharts/master/Screenshots/Oceanic.png)

# TODO
	- Add support for FAA's new APIs for determining current chart versions
		https://soa.smext.faa.gov/apra
		curl -X GET "https://soa.smext.faa.gov/apra/vfr/sectional/chart?geoname=Albuquerque&edition=current&format=tiff" -H  "accept: application/xml"
		https://app.swaggerhub.com/apis/FAA/APRA/1.1.0
		https://www.faa.gov/got_data/
    - Only optimize tiles if the source raster has changed
    - Only create mbtiles if the source raster has changed
    
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
##### Determine where you want to save the full set of charts downloaded from the FAA
##### This will be the first parameter to make_seamless_charts.sh
    eg /home/testuser/Downloads
    
##### Download all FAA data locally
    ./freshenLocalCharts.sh /home/testuser/Downloads
    
##### Determine the date of the most current set of enroute charts.  
##### This will need to be updated for every new cycle and is the 2nd paramter to make_seamless_charts.sh
##### See http://www.faa.gov/air_traffic/flight_info/aeronav/productcatalog/doles/media/Product_Schedule.pdf for dates through 2029
```
    eg 12-10-2015
    next will be 02-04-2016
    then 03-31-2016 etc etc.
```
##### Edit paths to these utilities as necessary in the *.sh scripts
##### If you use setup.sh they will be cloned from github into this directory so no editing will be necessary
```
./parallelGdal2Tiles/gdal2tiles.py
./mbutil/mb-util
./tilers_tools/
```
##### Edit make_seamless_charts.sh to add/remove various options for tile creation and merging as desired
    - Using -o will optimize individual tile size using pngquant
    - Using -m will create mbtiles for individual and merged charts
    
    Note that both of these will add some significant time to the overall process,
    especially the tile optimization (though it does significantly reduce file sizes)

##### Execute make_seamless_charts.sh with correct parameters
```
./make_seamless_charts.sh </path/to/aeronav_charts> <date_of_enroute_set>
    eg. ./make_seamless_charts.sh /home/test/Downloads/aeronav 12-10-2015
```
##### Wait a very long time (assuming all went correctly)
##### Individual charts should be in "6_tiles"
##### merged charts should be in "merged_tiled_charts"
##### mbtile archives should be in "7_mbtiles"
