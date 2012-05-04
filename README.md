Extractotron - Iceland
============

Fork from [extractotron](https://github.com/migurski/Extractotron) that provides shapefile extracts from OSM. Downloads available here:

Adding New Cities
-----------------

Extractotron is run once a month. If you have
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
