#!/bin/sh -ex

for TABLE in processed_p processed_i coastline_p post_errors post_missing; do

    curl -sL http://osm-metro-extracts.s3.amazonaws.com/$TABLE-merc.tar.bz2 | bzcat | tar -xf -
    shp2pgsql -dID -s 900913 $TABLE.shp $TABLE | psql -U osm coastline
    rm $TABLE.???
    
    psql -c "DELETE FROM $TABLE WHERE NOT ST_IsValid(the_geom)" -U osm coastline

done

# psql -U osm coastline < update.pgsql
