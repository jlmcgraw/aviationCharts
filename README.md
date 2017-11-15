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

##### Dependencies
Install various utilities and libraries and create directories using
```
./setup.sh
```

##### Download the charts

The `freshenLocalCharts.sh` downloads all the .zip files containing the charts to the specified folder. 

```bash
./freshenLocalCharts.sh /home/testuser/Downloads/aeronav
```

This same folder will be the first parameter to the `make_seamless_charts.sh` script (see below

    
##### Determine the date of the most current set of enroute charts.  

This will need to be updated for every new cycle and is the 2nd paramter to `make_seamless_charts.sh` Lookup the most recent data in the [Product_Schedule.pdf](http://www.faa.gov/air_traffic/flight_info/aeronav/productcatalog/doles/media/Product_Schedule.pdf) for dates through 2029

```
eg 12-10-2015
next will be 02-04-2016
then 03-31-2016 etc etc.
```

##### Edit paths (optiomnal)
To these utilities as necessary in the *.sh scripts. If you used `setup.sh` to insatall the dependencies, they will be cloned from github into this directory so no editing is  necessary. Otherwise, make sure those paths are set correctly:

```
./parallelGdal2Tiles/gdal2tiles.py
./mbutil/mb-util
./tilers_tools/
```
##### Tile creation options

You can supply the following flags to the `Edit the make_seamless_charts.sh` script:

```
-c should_process_caribbean
-e should_process_enroute
-g should_process_grand_canyon
-h should_process_helicopter
-p should_process_planning
-s should_process_sectional
-t should_process_tac
-m should_create_mbtiles

```

- Using `-o` will optimize individual tile size using pngquant
- Using `-m` will create mbtiles for individual and merged charts
    
Note that both of these will add some significant time to the overall process, especially the tile optimization (though it does significantly reduce file sizes)

##### Execute 


```
./make_seamless_charts.sh <flags> </path/to/aeronav_charts> <date_of_enroute_set>
```

- `</path/to/aeronav_charts>` is the folder where you previously downloaded the the charts
- `12-10-2015` is the cycle 

e.g

```
./make_seamless_charts.sh -s -m /home/testuser/Downloads/aeronav 12-10-2017
```

##### Wait 

- Wait a very long time (assuming all went correctly)
- Individual charts should be in "6_tiles"
- merged charts should be in "merged_tiled_charts"
- mbtile archives should be in "7_mbtiles"
