#!/bin/sh -ex

cd /mnt

echo '# begin', `date` > log.txt

apt-get update > install.txt 2>&1

apt-get install -y \
    apache2-mpm-worker openjdk-6-jre-headless python-boto libshp-dev libxml2-dev \
    libproj-dev zlib1g-dev libbz2-dev mapnik-utils gdal-bin subversion make zip \
    postgresql-8.4-postgis postgresql-contrib-8.4 \
 >> install.txt 2>&1

PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Tree::R' >> install.txt 2>&1
PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Bit::Vector' >> install.txt 2>&1

svn co http://svn.openstreetmap.org/applications/utils/coastcheck cc >> install.txt 2>&1
cd cc
make >> install.txt 2>&1
cd ..


# Make it possible to watch on port 80
rm -rfv /var/www
ln -sfv /mnt /var/www

# Osmosis uses a lot of /tmp so put it on the EBS volume
mv -v /tmp /mnt/
ln -sv /mnt/tmp /tmp


curl -s $OSMOSIS_HREF > osmosis.sh
curl -s $COASTSHAPES_HREF > coastshapes.sh
curl -s $COASTERRORS_HREF > coastline-errors.sh

chmod u+x osmosis.sh
chmod u+x coastshapes.sh
chmod u+x coastline-errors.sh


curl -sOL http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-latest.tgz
tar -xzf osmosis-latest.tgz

curl -OL "http://planet.openstreetmap.org/planet-latest.osm.bz2" > download.txt 2>&1

echo '# extract', `date` >> log.txt
mkdir ex

(
    mkdir coast
    
    cc/osm2coast planet-latest.osm.bz2 | gzip > coast/coastline.osm.gz
    cc/merge-coastlines.pl coast/coastline.osm.gz > coast/coast-merged.txt
    cc/coast2shp coast/coast-merged.txt coast/coastline.osm.gz coast/coastline > /dev/null
    cc/closeshp coast/coastline_c coast/coastline_i coast/processed > /dev/null
    shapeindex coast/coastline_c coast/coastline_i coast/coastline_p coast/processed_p coast/processed_i
    
    # this creates /tmp/coastline-errors.json and /tmp/coastline-missing.json
    sudo -u postgres ./coastline-errors.sh > coastline-errors.txt 2>&1
    
    ogr2ogr coast/post_errors.shp /tmp/coastline-errors.json
    ogr2ogr coast/post_missing.shp /tmp/coastline-missing.json
) &

./osmosis.sh > osmosis.txt 2>&1

wait

mkdir ex/merc
mkdir ex/wgs84

for NAME in processed_p processed_i coastline_p coastline_i post_errors post_missing; do
    ogr2ogr -a_srs "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over" ex/merc/$NAME.shp coast/$NAME.shp
    tar -C ex/merc -cvf - $NAME.dbf $NAME.prj $NAME.shp $NAME.shx | bzip2 > ex/$NAME-merc.tar.bz2

    ogr2ogr -t_srs EPSG:4326 ex/wgs84/$NAME.shp ex/merc/$NAME.shp
    tar -C ex/wgs84 -cvf - $NAME.dbf $NAME.prj $NAME.shp $NAME.shx | bzip2 > ex/$NAME-latlon.tar.bz2
done

./coastshapes.sh > coastshapes.txt 2>&1


python <<SEND

from os import stat
from glob import glob
from sys import stderr
from os.path import basename

from boto.s3.connection import S3Connection
from boto.s3.bucket import Bucket

types = dict(bz2='application/x-bzip2', pbf='application/octet-stream', zip='application/zip')
bucket = Bucket(S3Connection('$KEY', '$SECRET'), '$BUCKET')
log = open('log.txt', 'a')

for file in sorted(glob('ex/*.osm.???') + glob('ex/*.shp.zip')) + sorted(glob('ex/*.tar.bz2')):
    name = basename(file)
    type = types[name[-3:]]
    key = bucket.new_key(name)
    key.set_contents_from_file(open(file), policy='public-read', headers={'Content-Type': type})

    print >> stderr, file
    print >> log, name, stat(file).st_size

log.close()
key = bucket.new_key('log.txt')
key.set_contents_from_file(open('log.txt'), policy='public-read', headers={'Content-Type': 'text/plain'})

SEND

python <<KILL

from urllib import urlopen
from boto.ec2 import EC2Connection

instance = urlopen('http://169.254.169.254/latest/meta-data/instance-id').read().strip()
EC2Connection('$KEY', '$SECRET').terminate_instances(instance)

KILL
