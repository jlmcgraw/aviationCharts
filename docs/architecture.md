# Aviation Charts Python Pipeline

This repository is transitioning from a collection of shell/Perl scripts to a
single, synchronous Python pipeline. The goal is to minimize external
dependencies while keeping the processing stages easy to understand and run.

## Pipeline steps

1. **download**: Fetch chart archives from FAA/Aeronav sources.
2. **unpack**: Unzip archives and normalize filenames.
3. **process**: Expand rasters, clip to polygons, and reproject to EPSG:3857.
4. **insets**: Extract and georeference inset charts.
5. **tiles**: Generate map tiles for each chart.
6. **mbtiles**: Package tiles into MBTiles databases.
7. **merge**: Merge tilesets across charts.
8. **overviews**: Build overviews for large rasters.

Each step is executed sequentially and will be implemented in Python as the
migration progresses.

## Configuration

Configuration is provided via CLI flags. See the README for examples.
