from sys import argv, stderr
from csv import DictReader

cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))

try:
    (osm2pgsql, ) = argv[1:]
except ValueError:
    print >> stderr, 'Usage: build-osm2pgsql-script.py <osm2pgsql command file>'
    exit(1)

osm2pgsql = open(osm2pgsql, 'w')

print >> osm2pgsql, """#!/bin/bash -x

# 
# This script expects to be run as the postgres user.
# 

createdb -E utf8 -T template0 osm
createlang plpgsql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis.sql osm
psql -f /usr/share/postgresql/8.4/contrib/spatial_ref_sys.sql osm

function osm2pgsql_shapefiles
{
    slug=$1
    prefix=${slug//-/_}_osm

    osm2pgsql -sluc -C 1024 -d osm -S osm2pgsql.style -p ${prefix} ex/$slug.osm.bz2 > /dev/null 2>&1
    
    pgsql2shp -rk -f tmp/$slug.osm-point.shp osm ${prefix}_point
    pgsql2shp -rk -f tmp/$slug.osm-polygon.shp osm ${prefix}_polygon
    pgsql2shp -rk -f tmp/$slug.osm-line.shp osm ${prefix}_line
    zip -j tmp/$slug.osm2pgsql-shapefiles.zip tmp/$slug.osm-*.shp tmp/$slug.osm-*.prj tmp/$slug.osm-*.dbf tmp/$slug.osm-*.shx

    rm tmp/$slug.osm-*.*
    
    echo "DROP TABLE ${prefix}_line" | psql osm
    echo "DROP TABLE ${prefix}_nodes" | psql osm
    echo "DROP TABLE ${prefix}_point" | psql osm
    echo "DROP TABLE ${prefix}_polygon" | psql osm
    echo "DROP TABLE ${prefix}_rels" | psql osm
    echo "DROP TABLE ${prefix}_roads" | psql osm
    echo "DROP TABLE ${prefix}_ways" | psql osm
}

function imposm_shapefiles
{
    slug=$1
    prefix=${slug//-/_}
    
    mkdir tmp/$slug-imposm
    
    # "--connect" is an undocumented option for imposm; Olive Tonnhofer assures me it won't disappear in the future.
    imposm --read --cache-dir tmp/$slug-imposm --write --table-prefix=${prefix}_ --connect postgis://postgres:@127.0.0.1/osm ex/$slug.osm.pbf

    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-admin.shp osm ${prefix}_admin
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-aeroways.shp osm ${prefix}_aeroways
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-amenities.shp osm ${prefix}_amenities
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-buildings.shp osm ${prefix}_buildings
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-landusages.shp osm ${prefix}_landusages
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-landusages_gen0.shp osm ${prefix}_landusages_gen0
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-landusages_gen1.shp osm ${prefix}_landusages_gen1
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-mainroads.shp osm ${prefix}_mainroads
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-mainroads_gen0.shp osm ${prefix}_mainroads_gen0
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-mainroads_gen1.shp osm ${prefix}_mainroads_gen1
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-minorroads.shp osm ${prefix}_minorroads
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-motorways.shp osm ${prefix}_motorways
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-motorways_gen0.shp osm ${prefix}_motorways_gen0
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-motorways_gen1.shp osm ${prefix}_motorways_gen1
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-places.shp osm ${prefix}_places
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-railways.shp osm ${prefix}_railways
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-railways_gen0.shp osm ${prefix}_railways_gen0
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-railways_gen1.shp osm ${prefix}_railways_gen1
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-roads.shp osm ${prefix}_roads
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-roads_gen0.shp osm ${prefix}_roads_gen0
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-roads_gen1.shp osm ${prefix}_roads_gen1
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-transport_areas.shp osm ${prefix}_transport_areas
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-transport_points.shp osm ${prefix}_transport_points
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-waterareas.shp osm ${prefix}_waterareas
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-waterareas_gen0.shp osm ${prefix}_waterareas_gen0
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-waterareas_gen1.shp osm ${prefix}_waterareas_gen1
    pgsql2shp -rk -f tmp/$slug-imposm/$slug.osm-waterways.shp osm ${prefix}_waterways

    zip -j tmp/$slug.imposm-shapefiles.zip tmp/$slug-imposm/$slug.osm-*.shp tmp/$slug-imposm/$slug.osm-*.prj tmp/$slug-imposm/$slug.osm-*.dbf tmp/$slug-imposm/$slug.osm-*.shx

    rm -r tmp/$slug-imposm
    
    echo "DROP VIEW ${prefix}_roads" | psql osm
    echo "DROP VIEW ${prefix}_roads_gen0" | psql osm
    echo "DROP VIEW ${prefix}_roads_gen1" | psql osm
    echo "DROP TABLE ${prefix}_admin" | psql osm
    echo "DROP TABLE ${prefix}_aeroways" | psql osm
    echo "DROP TABLE ${prefix}_amenities" | psql osm
    echo "DROP TABLE ${prefix}_buildings" | psql osm
    echo "DROP TABLE ${prefix}_landusages" | psql osm
    echo "DROP TABLE ${prefix}_landusages_gen0" | psql osm
    echo "DROP TABLE ${prefix}_landusages_gen1" | psql osm
    echo "DROP TABLE ${prefix}_mainroads" | psql osm
    echo "DROP TABLE ${prefix}_mainroads_gen0" | psql osm
    echo "DROP TABLE ${prefix}_mainroads_gen1" | psql osm
    echo "DROP TABLE ${prefix}_minorroads" | psql osm
    echo "DROP TABLE ${prefix}_motorways" | psql osm
    echo "DROP TABLE ${prefix}_motorways_gen0" | psql osm
    echo "DROP TABLE ${prefix}_motorways_gen1" | psql osm
    echo "DROP TABLE ${prefix}_places" | psql osm
    echo "DROP TABLE ${prefix}_railways" | psql osm
    echo "DROP TABLE ${prefix}_railways_gen0" | psql osm
    echo "DROP TABLE ${prefix}_railways_gen1" | psql osm
    echo "DROP TABLE ${prefix}_transport_areas" | psql osm
    echo "DROP TABLE ${prefix}_transport_points" | psql osm
    echo "DROP TABLE ${prefix}_waterareas" | psql osm
    echo "DROP TABLE ${prefix}_waterareas_gen0" | psql osm
    echo "DROP TABLE ${prefix}_waterareas_gen1" | psql osm
    echo "DROP TABLE ${prefix}_waterways" | psql osm
}
"""

for city in cities:
    print >> osm2pgsql, 'osm2pgsql_shapefiles %(slug)s &' % city
    print >> osm2pgsql, 'imposm_shapefiles %(slug)s &' % city
    print >> osm2pgsql, 'wait'

osm2pgsql.close()
