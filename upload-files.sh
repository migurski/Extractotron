#!/bin/sh -ex
# EC2 will tell us our own instance ID, use that to turn ourselves off.

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

for file in sorted(glob('ex/*.osm.???') + glob('ex/*.zip')) + sorted(glob('ex/*.tar.bz2')):
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
