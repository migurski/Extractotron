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
    
By default, run-instance.py instantiates an m1.large instance with Alestic's
Ubuntu 11.04 Natty instance-store AMI ami-68ad5201. You can change the instance
type or AMI, see ```python run-instance.py --help``` for details.

Currently, the cities list is very short. Help me expand it by modifying
```cities.txt``` and sending a pull request via Github.