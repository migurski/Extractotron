#!/bin/sh

cd /mnt

echo '# begin', `date` > log.txt

apt-get install -y \
    apache2-mpm-worker \
    openjdk-6-jre-headless \
    python-boto \
  > install.txt 2>&1

rm -rfv /var/www
ln -sfv /mnt /var/www

curl -sOL http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-latest.tgz
tar -xzf osmosis-latest.tgz

curl -OL "http://planet.openstreetmap.org/planet-latest.osm.bz2" > download.txt 2>&1

echo '# extract', `date` >> log.txt
mkdir ex

osmosis.sh;

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
