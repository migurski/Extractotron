#!/bin/sh

#
# #!/bin/sh
# K=<your AWS access key>
# S=<your AWS access secret>
# B=<your bucket name>
# U=https://raw.github.com/migurski/Extractotron/master/extract.sh
# curl -s $U | KEY=$K SECRET=$S BUCKET=$B sh > /mnt/progress.txt 2>&1
#

echo '# begin', `date` > log.txt
echo 'Installing, see install.txt'

apt-get install -y \
    apache2-mpm-worker \
    openjdk-6-jre-headless \
    python-boto \
  > install.txt 2>&1

rm -rfv /var/www
ln -sfv /mnt /var/www

cd /mnt

curl -sOL http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-latest.tgz
tar -xzf osmosis-latest.tgz

echo '------------------------------------------------------------------------------'

echo 'Downloading, see download.txt'
curl -OL "http://download.geofabrik.de/osm/north-america/us/connecticut.osm.bz2" > download.txt 2>&1

echo '------------------------------------------------------------------------------'

echo '# extract', `date` >> log.txt
mkdir ex

bunzip2 -c connecticut.osm.bz2 | osmosis-*/bin/osmosis --rx file=- --log-progress interval=60 \
    --tee outputCount=2 \
    --bb left=-72.97016 top=41.33918 right=-72.88501 bottom=41.27858 \
        --tee outputCount=2 --wx ex/newhaven.osm.bz2 --wb ex/newhaven.osm.pbf \
    --bb left=-73.22181 top=41.20836 right=-73.15349 bottom=41.13677 \
        --tee outputCount=2 --wx ex/bridgeport.osm.bz2 --wb ex/bridgeport.osm.pbf

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

for file in glob('ex/*.osm.???'):
    print >> stderr, file
    print >> log, name, stat(file).st_size

    name = basename(file)
    type = types[name[-3:]]
    key = bucket.new_key(name)
    key.set_contents_from_file(open(file), policy='public-read', headers={'Content-Type': type})

log.close()
key = bucket.new_key('log.txt')
key.set_contents_from_file(open('log.txt'), policy='public-read', headers={'Content-Type': 'text/plain'})

CODE
