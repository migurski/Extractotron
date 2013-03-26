Extractotron
============

In one of my [SotM 2011](http://stateofthemap.org) talks, I suggested that OSM
should have regular extracts of metropolitan areas for major world cities and
their surrounding areas, regardless of state or country. This is a repository
for a bit of code to make that real. I’ve decided to use Amazon S3 to host files,
and EC2 to do the extracting. ```extract.sh``` is a script that performs the
actual work with [Osmosis](http://wiki.openstreetmap.org/wiki/Osmosis) and
terminates its host machine upon completion.

Adding New Cities
-----------------

Extractotron is run a few times per month, to http://metro.teczno.com. If you have
cities to add, you can add them directly to cities.txt and send me a pull request
in Github.

cities.txt is a tab-delimited file, and has eight fields:

-   **group**

    One of "Africa", "Asia", "Europe", "Middle East", "North America", "South America", or Oceania.

-   **geonameid**

    It's nice to have a link back to the [Geonames dataset](http://geonames.org).

-   **top, left, bottom, right**

    Geographic bounding box of the metropolitan area. These should be larger rather
    than smaller to surrounding countryside wherever possible. For example of coverage
    area, see [Moscow](http://metro.teczno.com/previews/moscow.jpg).

-   **slug**

    Short, lowercase version of the name with dashes for spaces that's used for files.

-   **name**

    Full name of the city.

Rolling Your Own
----------------

To use Extractotron yourself, use run-instance.py:

    python run-instance.py <your AWS access key> <your AWS secret> <your bucket name>

By default, run-instance.py instantiates an m2.4xlarge instance with Alestic's
Ubuntu 10.04 Lucid instance-store AMI ami-bffa6fd6. You can change the instance
type or AMI, see ```python run-instance.py --help``` for details.

Currently, the cities list is very short. Help me expand it by modifying
```cities.txt``` and sending a pull request via Github.

Code Documentation
------------------

The ``Makefile`` generates various derived files from the ```cities.txt``` file.
These scripts are utilities to do the extracts, generate utility scripts, JPG previews,
and an HTML index based on the regions specified in ```index.html```. Note the
result of this Makefile is checked in at github so there's no immediate need to run
make on a fresh clone of the repo.

-   **build-osmosis-script.py**

    Generate the shell script ```osmosis.sh``` which uses
    [Osmosis](http://wiki.openstreetmap.org/wiki/Osmosis) to extract subsets
    of OSM based on the bounding boxes in ```cities.txt```

-   **build-osm2pgsql-script.py**

    Generate the shell script ```osm2pgsql.sh``` which uses
    [imposm](http://imposm.org/) to import generated OSM metro subsets into
    a PostGIS database.

-   **build-coastshapes-script.py**

    Generate the shell script ```coastshapes.sh``` which uses
    [ogr2ogr](http://www.gdal.org/ogr2ogr.html) to generate coastline
    shapefiles.

-   **build-index.py**

    Generate ```index.html```, the current HTML interface to allow download
    of various extracted OSM data.

-   **compose-city-previews.py**

    Generate the JPG images in ```previews```, snapshot maps of the various
    metros being extracted.

The scripts generated above are then used by Extractotron to generate the actual
extracts. The code for doing the extracts includes

-   **run-instance.py**

    Utility script to create an EC2 instance to run the extract. See above for details.

-   **extract.sh**

    Template for the shell script to do the extraction. ```run-instance.py```
    substitutes pathnames for the scripts generated in the Makefile so that EC2 can
    then run the extraction. See also ```upload-files.sh``` and ```kill-self.sh```.

