#!/bin/bash -x

# 
# This script expects to be run as the postgres user.
# 

createdb osm
createlang plpgsql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql osm

function osm2geodata
{
    slug=$1
    prefix=${slug/-/_}_osm

    osm2pgsql -sluc -C 1024 -d osm -S osm2pgsql.style -p ${prefix} ex/$slug.osm.bz2 > /dev/null 2>&1
    
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
osm2geodata karlsruhe &
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
osm2geodata monaco &
osm2geodata moscow &
wait
osm2geodata munich &
osm2geodata paris &
wait
osm2geodata prague &
osm2geodata rome &
wait
osm2geodata rotterdam &
osm2geodata sofia &
wait
osm2geodata stockholm &
osm2geodata st-petersburg &
wait
osm2geodata toulouse &
osm2geodata warsaw &
wait
osm2geodata wroclaw &
osm2geodata baghdad &
wait
osm2geodata damascus &
osm2geodata dubai-abu-dhabi &
wait
osm2geodata kabul &
osm2geodata riyadh &
wait
osm2geodata atlanta &
osm2geodata austin &
wait
osm2geodata boston &
osm2geodata charlotte &
wait
osm2geodata chicago &
osm2geodata cleveland &
wait
osm2geodata columbus-oh &
osm2geodata dallas &
wait
osm2geodata denver &
osm2geodata detroit &
wait
osm2geodata houston &
osm2geodata humboldt-ca &
wait
osm2geodata kamloops &
osm2geodata las-vegas &
wait
osm2geodata kansas-city-lawrence-topeka &
osm2geodata los-angeles &
wait
osm2geodata macon-ga &
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
