#!/bin/sh

#
# #!/bin/sh
# K=<your AWS access key>
# S=<your AWS access secret>
# B=<your bucket name>
# U=https://raw.github.com/migurski/Extractotron/master/extract.sh
# curl -s $U | KEY=$K SECRET=$S BUCKET=$B sh > /mnt/progress.txt 2>&1
#

cd /mnt

echo '# begin', `date` > log.txt
echo 'Installing, see install.txt'

apt-get install -y \
    apache2-mpm-worker \
    openjdk-6-jre-headless \
    python-boto \
  > install.txt 2>&1

rm -rfv /var/www
ln -sfv /mnt /var/www

curl -sOL http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-latest.tgz
tar -xzf osmosis-latest.tgz

echo '------------------------------------------------------------------------------'

echo 'Downloading, see download.txt'
curl -OL "http://planet.openstreetmap.org/planet-latest.osm.bz2" > download.txt 2>&1

echo '------------------------------------------------------------------------------'

echo '# extract', `date` >> log.txt
mkdir ex

bunzip2 -c planet-latest.osm.bz2 | osmosis-*/bin/osmosis --rx file=- \
    --log-progress interval=60 \
    --tee outputCount=7 \
    \
    --bb top=37.955 left=-122.737 bottom=37.449 right=-122.011 \
        --tee outputCount=2 --wx file=ex/san-francisco.osm.bz2 --wb file=ex/san-francisco.osm.pbf \
    --bb top=38.719 left=-123.640 bottom=36.791 right=-121.025 \
        --tee outputCount=2 --wx file=ex/sf-bay-area.osm.bz2 --wb file=ex/sf-bay-area.osm.pbf \
    --bb top=34.583 left=-119.437 bottom=33.298 right=-116.724 \
        --tee outputCount=2 --wx file=ex/los-angeles.osm.bz2 --wb file=ex/los-angeles.osm.pbf \
    --bb top=41.097 left=-74.501 bottom=40.345 right=-73.226 \
        --tee outputCount=2 --wx file=ex/new-york.osm.bz2 --wb file=ex/new-york.osm.pbf \
    --bb top=51.984 left=-1.115 bottom=50.941 right=0.895 \
        --tee outputCount=2 --wx file=ex/london.osm.bz2 --wb file=ex/london.osm.pbf \
    --bb top=52.994 left=12.260 bottom=51.849 right=14.699 \
        --tee outputCount=2 --wx file=ex/berlin.osm.bz2 --wb file=ex/berlin.osm.pbf \
    --bb top=56.200 left=36.870 bottom=55.285 right=38.430 \
        --tee outputCount=2 --wx file=ex/moscow.osm.bz2 --wb file=ex/moscow.osm.pbf

echo '------------------------------------------------------------------------------'

python <<CODE

from os import stat
from glob import glob
from sys import stderr
from os.path import basename
from urllib import urlopen

from boto.ec2 import EC2Connection
from boto.s3.connection import S3Connection
from boto.s3.bucket import Bucket

types = dict(bz2='application/x-bzip2', pbf='application/octet-stream')
bucket = Bucket(S3Connection('$KEY', '$SECRET'), '$BUCKET')
log = open('log.txt', 'a')

for file in sorted(glob('ex/*.osm.???')):
    name = basename(file)
    type = types[name[-3:]]
    key = bucket.new_key(name)
    key.set_contents_from_file(open(file), policy='public-read', headers={'Content-Type': type})

    print >> stderr, file
    print >> log, name, stat(file).st_size

log.close()
key = bucket.new_key('log.txt')
key.set_contents_from_file(open('log.txt'), policy='public-read', headers={'Content-Type': 'text/plain'})

instance = urlopen('http://169.254.169.254/latest/meta-data/instance-id').read().strip()
EC2Connection('$KEY', '$SECRET').terminate_instances(instance)

CODE
