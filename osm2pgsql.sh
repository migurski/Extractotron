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
    prefix=${slug/-/_}_osm

    osm2pgsql -sluc -C 1024 -d osm -S tmp/default.style -p ${prefix} ex/$slug.osm.bz2 > /dev/null 2>&1
    
    pgsql2shp -rk -f tmp/$slug.osm-point.shp osm ${prefix}_point
    pgsql2shp -rk -f tmp/$slug.osm-polygon.shp osm ${prefix}_polygon
    pgsql2shp -rk -f tmp/$slug.osm-line.shp osm ${prefix}_line
    zip -j tmp/$slug.shapefiles.zip tmp/$slug.osm-*.shp tmp/$slug.osm-*.prj tmp/$slug.osm-*.dbf tmp/$slug.osm-*.shx

    rm tmp/$slug.osm-*.*
    
    echo "DROP TABLE ${prefix}_line" | psql osm
    echo "DROP TABLE ${prefix}_nodes" | psql osm
    echo "DROP TABLE ${prefix}_point" | psql osm
    echo "DROP TABLE ${prefix}_polygon" | psql osm
    echo "DROP TABLE ${prefix}_rels" | psql osm
    echo "DROP TABLE ${prefix}_roads" | psql osm
    echo "DROP TABLE ${prefix}_ways" | psql osm
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
osm2geodata taipei &
osm2geodata tehran &
wait
osm2geodata tokyo &
osm2geodata amsterdam &
wait
osm2geodata athens &
osm2geodata barcelona &
wait
osm2geodata berlin &
osm2geodata birmingham &
wait
osm2geodata bordeaux &
osm2geodata brno &
wait
osm2geodata brussels &
osm2geodata budapest &
wait
osm2geodata copenhagen &
osm2geodata edinburgh &
wait
osm2geodata florence &
osm2geodata frankfurt &
wait
osm2geodata gdansk &
osm2geodata glasgow &
wait
osm2geodata hamburg &
osm2geodata istanbul &
wait
osm2geodata krakow &
osm2geodata leeds &
wait
osm2geodata lille &
osm2geodata lisbon &
wait
osm2geodata lyon &
osm2geodata london &
wait
osm2geodata madrid &
osm2geodata manchester &
wait
osm2geodata marseille &
osm2geodata monaco &
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
osm2geodata damascus &
wait
osm2geodata dubai-abu-dhabi &
osm2geodata kabul &
wait
osm2geodata riyadh &
osm2geodata atlanta &
wait
osm2geodata austin &
osm2geodata boston &
wait
osm2geodata charlotte &
osm2geodata chicago &
wait
osm2geodata cleveland &
osm2geodata columbus-oh &
wait
osm2geodata dallas &
osm2geodata denver &
wait
osm2geodata detroit &
osm2geodata houston &
wait
osm2geodata humboldt-ca &
osm2geodata kamloops &
wait
osm2geodata las-vegas &
osm2geodata kansas-city-lawrence-topeka &
wait
osm2geodata los-angeles &
osm2geodata madison &
wait
osm2geodata mexico-city &
osm2geodata miami &
wait
osm2geodata milwaukee &
osm2geodata mpls-stpaul &
wait
osm2geodata montreal &
osm2geodata new-orleans &
wait
osm2geodata new-york &
osm2geodata philadelphia &
wait
osm2geodata phoenix &
osm2geodata pittsburgh &
wait
osm2geodata portland &
osm2geodata reno &
wait
osm2geodata st-louis &
osm2geodata sacramento &
wait
osm2geodata san-diego-tijuana &
osm2geodata san-francisco &
wait
osm2geodata sf-bay-area &
osm2geodata seattle &
wait
osm2geodata state-college-pa &
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
