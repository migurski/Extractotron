#!/bin/sh

KEY=$1
SECRET=$2
BUCKET=$3

mkdir -p merc
mkdir -p wgs84
mkdir -p good

pgsql2shp -f good/coastline-good.shp -u osm planet_osm coastline

ogr2ogr -a_srs "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over" merc/coastline-good.shp good/coastline-good.shp;
tar -C merc -cvf - coastline-good.dbf coastline-good.prj coastline-good.shp coastline-good.shx | bzip2 > coastline-good-merc.tar.bz2;

ogr2ogr -t_srs EPSG:4326 wgs84/coastline-good.shp merc/coastline-good.shp;
tar -C wgs84 -cvf - coastline-good.dbf coastline-good.prj coastline-good.shp coastline-good.shx | bzip2 > coastline-good-latlon.tar.bz2;

python <<PUSHIT

from sys import stderr
from boto.s3.connection import S3Connection

s3conn = S3Connection('$KEY', '$SECRET')
bucket = s3conn.get_bucket('$BUCKET')

types = dict(bz2='application/x-bzip2', pbf='application/octet-stream', zip='application/zip')

for filename in ('coastline-good-merc.tar.bz2', 'coastline-good-latlon.tar.bz2'):
    print >> stderr, filename, '...',

    type = types[filename[-3:]]
    key = bucket.new_key(filename)
    key.set_contents_from_file(open(filename), policy='public-read', headers={'Content-Type': type})

    print >> stderr, type

PUSHIT

rm -rf merc wgs84 good
