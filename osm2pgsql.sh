#!/bin/bash -x

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

osm2pgsql_shapefiles abuja &
imposm_shapefiles abuja &
wait
osm2pgsql_shapefiles bejaia &
imposm_shapefiles bejaia &
wait
osm2pgsql_shapefiles cairo &
imposm_shapefiles cairo &
wait
osm2pgsql_shapefiles dar-es-salaam &
imposm_shapefiles dar-es-salaam &
wait
osm2pgsql_shapefiles harare &
imposm_shapefiles harare &
wait
osm2pgsql_shapefiles johannesburg &
imposm_shapefiles johannesburg &
wait
osm2pgsql_shapefiles kampala &
imposm_shapefiles kampala &
wait
osm2pgsql_shapefiles lagos &
imposm_shapefiles lagos &
wait
osm2pgsql_shapefiles mogadishu &
imposm_shapefiles mogadishu &
wait
osm2pgsql_shapefiles nairobi &
imposm_shapefiles nairobi &
wait
osm2pgsql_shapefiles kigali &
imposm_shapefiles kigali &
wait
osm2pgsql_shapefiles almaty &
imposm_shapefiles almaty &
wait
osm2pgsql_shapefiles ankara &
imposm_shapefiles ankara &
wait
osm2pgsql_shapefiles bangkok &
imposm_shapefiles bangkok &
wait
osm2pgsql_shapefiles beijing &
imposm_shapefiles beijing &
wait
osm2pgsql_shapefiles bengaluru &
imposm_shapefiles bengaluru &
wait
osm2pgsql_shapefiles chengdu &
imposm_shapefiles chengdu &
wait
osm2pgsql_shapefiles chennai &
imposm_shapefiles chennai &
wait
osm2pgsql_shapefiles chongqing &
imposm_shapefiles chongqing &
wait
osm2pgsql_shapefiles dushanbe &
imposm_shapefiles dushanbe &
wait
osm2pgsql_shapefiles hong-kong &
imposm_shapefiles hong-kong &
wait
osm2pgsql_shapefiles islamabad &
imposm_shapefiles islamabad &
wait
osm2pgsql_shapefiles kathmandu &
imposm_shapefiles kathmandu &
wait
osm2pgsql_shapefiles karachi &
imposm_shapefiles karachi &
wait
osm2pgsql_shapefiles lahore &
imposm_shapefiles lahore &
wait
osm2pgsql_shapefiles nazareth &
imposm_shapefiles nazareth &
wait
osm2pgsql_shapefiles manila &
imposm_shapefiles manila &
wait
osm2pgsql_shapefiles mumbai &
imposm_shapefiles mumbai &
wait
osm2pgsql_shapefiles new-delhi &
imposm_shapefiles new-delhi &
wait
osm2pgsql_shapefiles osaka &
imposm_shapefiles osaka &
wait
osm2pgsql_shapefiles seoul &
imposm_shapefiles seoul &
wait
osm2pgsql_shapefiles siem-reap &
imposm_shapefiles siem-reap &
wait
osm2pgsql_shapefiles shanghai &
imposm_shapefiles shanghai &
wait
osm2pgsql_shapefiles singapore &
imposm_shapefiles singapore &
wait
osm2pgsql_shapefiles taipei &
imposm_shapefiles taipei &
wait
osm2pgsql_shapefiles tehran &
imposm_shapefiles tehran &
wait
osm2pgsql_shapefiles tokyo &
imposm_shapefiles tokyo &
wait
osm2pgsql_shapefiles amsterdam &
imposm_shapefiles amsterdam &
wait
osm2pgsql_shapefiles athens &
imposm_shapefiles athens &
wait
osm2pgsql_shapefiles barcelona &
imposm_shapefiles barcelona &
wait
osm2pgsql_shapefiles berlin &
imposm_shapefiles berlin &
wait
osm2pgsql_shapefiles birmingham &
imposm_shapefiles birmingham &
wait
osm2pgsql_shapefiles bordeaux &
imposm_shapefiles bordeaux &
wait
osm2pgsql_shapefiles brno &
imposm_shapefiles brno &
wait
osm2pgsql_shapefiles brussels &
imposm_shapefiles brussels &
wait
osm2pgsql_shapefiles budapest &
imposm_shapefiles budapest &
wait
osm2pgsql_shapefiles cantabria &
imposm_shapefiles cantabria &
wait
osm2pgsql_shapefiles copenhagen &
imposm_shapefiles copenhagen &
wait
osm2pgsql_shapefiles colchester &
imposm_shapefiles colchester &
wait
osm2pgsql_shapefiles edinburgh &
imposm_shapefiles edinburgh &
wait
osm2pgsql_shapefiles florence &
imposm_shapefiles florence &
wait
osm2pgsql_shapefiles frankfurt &
imposm_shapefiles frankfurt &
wait
osm2pgsql_shapefiles gdansk &
imposm_shapefiles gdansk &
wait
osm2pgsql_shapefiles genoa &
imposm_shapefiles genoa &
wait
osm2pgsql_shapefiles glasgow &
imposm_shapefiles glasgow &
wait
osm2pgsql_shapefiles hamburg &
imposm_shapefiles hamburg &
wait
osm2pgsql_shapefiles helsinki &
imposm_shapefiles helsinki &
wait
osm2pgsql_shapefiles istanbul &
imposm_shapefiles istanbul &
wait
osm2pgsql_shapefiles karlsruhe &
imposm_shapefiles karlsruhe &
wait
osm2pgsql_shapefiles krakow &
imposm_shapefiles krakow &
wait
osm2pgsql_shapefiles kyiv &
imposm_shapefiles kyiv &
wait
osm2pgsql_shapefiles leeds &
imposm_shapefiles leeds &
wait
osm2pgsql_shapefiles lille &
imposm_shapefiles lille &
wait
osm2pgsql_shapefiles lisbon &
imposm_shapefiles lisbon &
wait
osm2pgsql_shapefiles lyon &
imposm_shapefiles lyon &
wait
osm2pgsql_shapefiles london &
imposm_shapefiles london &
wait
osm2pgsql_shapefiles madrid &
imposm_shapefiles madrid &
wait
osm2pgsql_shapefiles manchester &
imposm_shapefiles manchester &
wait
osm2pgsql_shapefiles marseille &
imposm_shapefiles marseille &
wait
osm2pgsql_shapefiles milan &
imposm_shapefiles milan &
wait
osm2pgsql_shapefiles monaco &
imposm_shapefiles monaco &
wait
osm2pgsql_shapefiles montpellier &
imposm_shapefiles montpellier &
wait
osm2pgsql_shapefiles moscow &
imposm_shapefiles moscow &
wait
osm2pgsql_shapefiles munich &
imposm_shapefiles munich &
wait
osm2pgsql_shapefiles newcastle &
imposm_shapefiles newcastle &
wait
osm2pgsql_shapefiles nuremberg &
imposm_shapefiles nuremberg &
wait
osm2pgsql_shapefiles odessa &
imposm_shapefiles odessa &
wait
osm2pgsql_shapefiles paris &
imposm_shapefiles paris &
wait
osm2pgsql_shapefiles porto &
imposm_shapefiles porto &
wait
osm2pgsql_shapefiles prague &
imposm_shapefiles prague &
wait
osm2pgsql_shapefiles reykjavik &
imposm_shapefiles reykjavik &
wait
osm2pgsql_shapefiles riga &
imposm_shapefiles riga &
wait
osm2pgsql_shapefiles rome &
imposm_shapefiles rome &
wait
osm2pgsql_shapefiles rotterdam &
imposm_shapefiles rotterdam &
wait
osm2pgsql_shapefiles sarajevo &
imposm_shapefiles sarajevo &
wait
osm2pgsql_shapefiles sofia &
imposm_shapefiles sofia &
wait
osm2pgsql_shapefiles stockholm &
imposm_shapefiles stockholm &
wait
osm2pgsql_shapefiles strasbourg &
imposm_shapefiles strasbourg &
wait
osm2pgsql_shapefiles st-petersburg &
imposm_shapefiles st-petersburg &
wait
osm2pgsql_shapefiles toulouse &
imposm_shapefiles toulouse &
wait
osm2pgsql_shapefiles vienna &
imposm_shapefiles vienna &
wait
osm2pgsql_shapefiles vienna-bratislava &
imposm_shapefiles vienna-bratislava &
wait
osm2pgsql_shapefiles venice &
imposm_shapefiles venice &
wait
osm2pgsql_shapefiles warsaw &
imposm_shapefiles warsaw &
wait
osm2pgsql_shapefiles wroclaw &
imposm_shapefiles wroclaw &
wait
osm2pgsql_shapefiles as-suwayda &
imposm_shapefiles as-suwayda &
wait
osm2pgsql_shapefiles baghdad &
imposm_shapefiles baghdad &
wait
osm2pgsql_shapefiles damascus &
imposm_shapefiles damascus &
wait
osm2pgsql_shapefiles dubai-abu-dhabi &
imposm_shapefiles dubai-abu-dhabi &
wait
osm2pgsql_shapefiles kabul &
imposm_shapefiles kabul &
wait
osm2pgsql_shapefiles riyadh &
imposm_shapefiles riyadh &
wait
osm2pgsql_shapefiles tel-aviv &
imposm_shapefiles tel-aviv &
wait
osm2pgsql_shapefiles yerevan &
imposm_shapefiles yerevan &
wait
osm2pgsql_shapefiles atlanta &
imposm_shapefiles atlanta &
wait
osm2pgsql_shapefiles austin &
imposm_shapefiles austin &
wait
osm2pgsql_shapefiles boston &
imposm_shapefiles boston &
wait
osm2pgsql_shapefiles calgary &
imposm_shapefiles calgary &
wait
osm2pgsql_shapefiles charlotte &
imposm_shapefiles charlotte &
wait
osm2pgsql_shapefiles chattanooga &
imposm_shapefiles chattanooga &
wait
osm2pgsql_shapefiles chicago &
imposm_shapefiles chicago &
wait
osm2pgsql_shapefiles cincinnati &
imposm_shapefiles cincinnati &
wait
osm2pgsql_shapefiles cleveland &
imposm_shapefiles cleveland &
wait
osm2pgsql_shapefiles columbus-oh &
imposm_shapefiles columbus-oh &
wait
osm2pgsql_shapefiles dallas &
imposm_shapefiles dallas &
wait
osm2pgsql_shapefiles denver-boulder &
imposm_shapefiles denver-boulder &
wait
osm2pgsql_shapefiles detroit &
imposm_shapefiles detroit &
wait
osm2pgsql_shapefiles evansville &
imposm_shapefiles evansville &
wait
osm2pgsql_shapefiles grassvalley &
imposm_shapefiles grassvalley &
wait
osm2pgsql_shapefiles honolulu &
imposm_shapefiles honolulu &
wait
osm2pgsql_shapefiles houston &
imposm_shapefiles houston &
wait
osm2pgsql_shapefiles humboldt-ca &
imposm_shapefiles humboldt-ca &
wait
osm2pgsql_shapefiles indianapolis &
imposm_shapefiles indianapolis &
wait
osm2pgsql_shapefiles kamloops &
imposm_shapefiles kamloops &
wait
osm2pgsql_shapefiles las-vegas &
imposm_shapefiles las-vegas &
wait
osm2pgsql_shapefiles kansas-city-lawrence-topeka &
imposm_shapefiles kansas-city-lawrence-topeka &
wait
osm2pgsql_shapefiles lexington &
imposm_shapefiles lexington &
wait
osm2pgsql_shapefiles los-angeles &
imposm_shapefiles los-angeles &
wait
osm2pgsql_shapefiles macon-ga &
imposm_shapefiles macon-ga &
wait
osm2pgsql_shapefiles madison &
imposm_shapefiles madison &
wait
osm2pgsql_shapefiles mexico-city &
imposm_shapefiles mexico-city &
wait
osm2pgsql_shapefiles miami &
imposm_shapefiles miami &
wait
osm2pgsql_shapefiles milwaukee &
imposm_shapefiles milwaukee &
wait
osm2pgsql_shapefiles mpls-stpaul &
imposm_shapefiles mpls-stpaul &
wait
osm2pgsql_shapefiles mobile-al &
imposm_shapefiles mobile-al &
wait
osm2pgsql_shapefiles montreal &
imposm_shapefiles montreal &
wait
osm2pgsql_shapefiles new-orleans &
imposm_shapefiles new-orleans &
wait
osm2pgsql_shapefiles new-york &
imposm_shapefiles new-york &
wait
osm2pgsql_shapefiles philadelphia &
imposm_shapefiles philadelphia &
wait
osm2pgsql_shapefiles phoenix &
imposm_shapefiles phoenix &
wait
osm2pgsql_shapefiles pittsburgh &
imposm_shapefiles pittsburgh &
wait
osm2pgsql_shapefiles port-au-prince &
imposm_shapefiles port-au-prince &
wait
osm2pgsql_shapefiles portland &
imposm_shapefiles portland &
wait
osm2pgsql_shapefiles reno &
imposm_shapefiles reno &
wait
osm2pgsql_shapefiles st-louis &
imposm_shapefiles st-louis &
wait
osm2pgsql_shapefiles sacramento &
imposm_shapefiles sacramento &
wait
osm2pgsql_shapefiles san-diego-tijuana &
imposm_shapefiles san-diego-tijuana &
wait
osm2pgsql_shapefiles san-francisco &
imposm_shapefiles san-francisco &
wait
osm2pgsql_shapefiles sf-bay-area &
imposm_shapefiles sf-bay-area &
wait
osm2pgsql_shapefiles santa-barbara &
imposm_shapefiles santa-barbara &
wait
osm2pgsql_shapefiles santo-domingo &
imposm_shapefiles santo-domingo &
wait
osm2pgsql_shapefiles seattle &
imposm_shapefiles seattle &
wait
osm2pgsql_shapefiles state-college-pa &
imposm_shapefiles state-college-pa &
wait
osm2pgsql_shapefiles tampa &
imposm_shapefiles tampa &
wait
osm2pgsql_shapefiles terre-haute &
imposm_shapefiles terre-haute &
wait
osm2pgsql_shapefiles toronto &
imposm_shapefiles toronto &
wait
osm2pgsql_shapefiles tucson &
imposm_shapefiles tucson &
wait
osm2pgsql_shapefiles vancouver &
imposm_shapefiles vancouver &
wait
osm2pgsql_shapefiles victoria &
imposm_shapefiles victoria &
wait
osm2pgsql_shapefiles dc-baltimore &
imposm_shapefiles dc-baltimore &
wait
osm2pgsql_shapefiles auckland &
imposm_shapefiles auckland &
wait
osm2pgsql_shapefiles jakarta &
imposm_shapefiles jakarta &
wait
osm2pgsql_shapefiles melbourne &
imposm_shapefiles melbourne &
wait
osm2pgsql_shapefiles sydney &
imposm_shapefiles sydney &
wait
osm2pgsql_shapefiles bogota &
imposm_shapefiles bogota &
wait
osm2pgsql_shapefiles brasilia-brazil &
imposm_shapefiles brasilia-brazil &
wait
osm2pgsql_shapefiles buenos-aires &
imposm_shapefiles buenos-aires &
wait
osm2pgsql_shapefiles campo-grande &
imposm_shapefiles campo-grande &
wait
osm2pgsql_shapefiles cartagena &
imposm_shapefiles cartagena &
wait
osm2pgsql_shapefiles curitiba-brazil &
imposm_shapefiles curitiba-brazil &
wait
osm2pgsql_shapefiles lima &
imposm_shapefiles lima &
wait
osm2pgsql_shapefiles porto-alegre &
imposm_shapefiles porto-alegre &
wait
osm2pgsql_shapefiles quito-ecuador &
imposm_shapefiles quito-ecuador &
wait
osm2pgsql_shapefiles rio-de-janeiro &
imposm_shapefiles rio-de-janeiro &
wait
osm2pgsql_shapefiles sao-paulo &
imposm_shapefiles sao-paulo &
wait
osm2pgsql_shapefiles santiago &
imposm_shapefiles santiago &
wait
