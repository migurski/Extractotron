#!/bin/bash -x

# 
# This script expects to be run as the postgres user.
# 

createdb osm
createlang plpgsql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql osm

curl -o tmp/default.style http://svn.openstreetmap.org/applications/utils/export/osm2pgsql/default.style

function osm2geodata
{
    slug=$1

    osm2pgsql -luc -C 4096 -d osm -S tmp/default.style -p ${slug}_osm ex/$slug.osm.bz2 > /dev/null 2>&1
    
    pgsql2shp -r -f tmp/$slug.osm-point.shp osm ${slug}_osm_point
    pgsql2shp -r -f tmp/$slug.osm-polygon.shp osm ${slug}_osm_polygon
    pgsql2shp -r -f tmp/$slug.osm-line.shp osm ${slug}_osm_line
    zip -j tmp/$slug.shapefiles.zip tmp/$slug.osm-*.shp tmp/$slug.osm-*.prj tmp/$slug.osm-*.dbf tmp/$slug.osm-*.shx
    
    ogr2ogr -f GeoJSON tmp/$slug.osm-point.json PG:"dbname='osm'" ${slug}_osm_point
    ogr2ogr -f GeoJSON tmp/$slug.osm-polygon.json PG:"dbname='osm'" ${slug}_osm_polygon
    ogr2ogr -f GeoJSON tmp/$slug.osm-line.json PG:"dbname='osm'" ${slug}_osm_line
    zip -j tmp/$slug.geojson.zip tmp/$slug.osm-*.json
    
    ogr2ogr -f KML tmp/$slug.osm-point.kml PG:"dbname='osm'" ${slug}_osm_point
    ogr2ogr -f KML tmp/$slug.osm-polygon.kml PG:"dbname='osm'" ${slug}_osm_polygon
    ogr2ogr -f KML tmp/$slug.osm-line.kml PG:"dbname='osm'" ${slug}_osm_line
    zip -j tmp/$slug.kml.zip tmp/$slug.osm-*.kml

    rm tmp/$slug.osm-*.*
}

osm2geodata cairo
osm2geodata johannesburg
osm2geodata lagos
