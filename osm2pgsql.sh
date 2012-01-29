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

    osm2pgsql -sluc -C 1024 -d osm -S tmp/default.style -p ${slug}_osm ex/$slug.osm.bz2 > /dev/null 2>&1
    
    pgsql2shp -rk -f tmp/$slug.osm-point.shp osm ${slug}_osm_point
    pgsql2shp -rk -f tmp/$slug.osm-polygon.shp osm ${slug}_osm_polygon
    pgsql2shp -rk -f tmp/$slug.osm-line.shp osm ${slug}_osm_line
    zip -j tmp/$slug.shapefiles.zip tmp/$slug.osm-*.shp tmp/$slug.osm-*.prj tmp/$slug.osm-*.dbf tmp/$slug.osm-*.shx

    rm tmp/$slug.osm-*.*
    
    echo "DROP TABLE ${slug}_osm_line" | psql osm
    echo "DROP TABLE ${slug}_osm_nodes" | psql osm
    echo "DROP TABLE ${slug}_osm_point" | psql osm
    echo "DROP TABLE ${slug}_osm_polygon" | psql osm
    echo "DROP TABLE ${slug}_osm_rels" | psql osm
    echo "DROP TABLE ${slug}_osm_roads" | psql osm
    echo "DROP TABLE ${slug}_osm_ways" | psql osm
}

osm2geodata cairo &
osm2geodata johannesburg &
wait
osm2geodata lagos &
osm2geodata ankara &
wait
osm2geodata bangkok &
osm2geodata beijing &
wait
osm2geodata bengaluru &
osm2geodata chennai &
wait
osm2geodata hong-kong &
osm2geodata manila &
wait
osm2geodata mumbai &
osm2geodata new-delhi &
wait
osm2geodata osaka &
osm2geodata seoul &
wait
osm2geodata shanghai &
osm2geodata singapore &
wait
osm2geodata tehran &
osm2geodata tokyo &
wait
osm2geodata amsterdam &
osm2geodata athens &
wait
osm2geodata barcelona &
osm2geodata berlin &
wait
osm2geodata birmingham &
osm2geodata bordeaux &
wait
osm2geodata brno &
osm2geodata brussels &
wait
osm2geodata budapest &
osm2geodata copenhagen &
wait
osm2geodata edinburgh &
osm2geodata florence &
wait
osm2geodata frankfurt &
osm2geodata gdansk &
wait
osm2geodata glasgow &
osm2geodata hamburg &
wait
osm2geodata istanbul &
osm2geodata krakow &
wait
osm2geodata leeds &
osm2geodata lille &
wait
osm2geodata lisbon &
osm2geodata lyon &
wait
osm2geodata london &
osm2geodata madrid &
wait
osm2geodata manchester &
osm2geodata marseille &
wait
osm2geodata moscow &
osm2geodata munich &
wait
osm2geodata paris &
osm2geodata prague &
wait
osm2geodata rome &
osm2geodata rotterdam &
wait
osm2geodata sofia &
osm2geodata stockholm &
wait
osm2geodata st-petersburg &
osm2geodata toulouse &
wait
osm2geodata warsaw &
osm2geodata wroclaw &
wait
osm2geodata baghdad &
osm2geodata riyadh &
wait
osm2geodata kabul &
osm2geodata atlanta &
wait
osm2geodata austin &
osm2geodata boston &
wait
osm2geodata chicago &
osm2geodata cleveland &
wait
osm2geodata dallas &
osm2geodata denver &
wait
osm2geodata detroit &
osm2geodata houston &
wait
osm2geodata kamloops &
osm2geodata las-vegas &
wait
osm2geodata los-angeles &
osm2geodata madison &
wait
osm2geodata mexico-city &
osm2geodata miami &
wait
osm2geodata mpls-stpaul &
osm2geodata montreal &
wait
osm2geodata new-orleans &
osm2geodata new-york &
wait
osm2geodata philadelphia &
osm2geodata phoenix &
wait
osm2geodata pittsburgh &
osm2geodata portland &
wait
osm2geodata st-louis &
osm2geodata san-diego-tijuana &
wait
osm2geodata san-francisco &
osm2geodata sf-bay-area &
wait
osm2geodata seattle &
osm2geodata tampa &
wait
osm2geodata toronto &
osm2geodata vancouver &
wait
osm2geodata victoria &
osm2geodata dc-baltimore &
wait
osm2geodata auckland &
osm2geodata jakarta &
wait
osm2geodata melbourne &
osm2geodata sydney &
wait
osm2geodata bogota &
osm2geodata cartagena &
wait
osm2geodata buenos-aires &
osm2geodata lima &
wait
osm2geodata rio-de-janeiro &
osm2geodata sao-paulo &
wait
osm2geodata santiago &
wait
