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
curl -OL "http://download.geofabrik.de/osm/north-america/us/california.osm.bz2" > download.txt 2>&1

echo '------------------------------------------------------------------------------'

echo '# extract', `date` >> log.txt
mkdir ex

bunzip2 -c california.osm.bz2 | osmosis-*/bin/osmosis --rx file=- \
    --log-progress interval=60 \
    --tee outputCount=2 \
    \
    --bb top=37.9203 left=-122.8244 bottom=37.5489 right=-121.7752 \
        --tee outputCount=2 --wx file=ex/san-francisco.osm.bz2 --wb file=ex/san-francisco.osm.pbf \
    --bb top=34.14477 left=-118.5438 bottom=33.9262 right=-118.1346 \
        --tee outputCount=2 --wx file=ex/los-angeles.osm.bz2 --wb file=ex/los-angeles.osm.pbf

echo '------------------------------------------------------------------------------'

python <<CODE

from os import stat
from glob import glob
from sys import stderr
from os.path import basename

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

CODE
