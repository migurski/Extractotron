#!/bin/sh -ex

for TABLE in processed_p processed_i coastline_p; do

    curl -sL http://osm-metro-extracts.s3.amazonaws.com/$TABLE-merc.tar.bz2 | bzcat | tar -xf -
    shp2pgsql -dID -s 900913 $TABLE.shp $TABLE | psql -U osm planet_osm
    rm $TABLE.???
    
    psql -c "DELETE FROM $TABLE WHERE NOT ST_IsValid(the_geom)" -U osm planet_osm

done

# psql -U osm planet_osm < update.pgsql
