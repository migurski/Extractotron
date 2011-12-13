from sys import argv, stderr
from boto.s3.connection import S3Connection

aws_key, aws_secret, s3_bucket = argv[1:4]

s3conn = S3Connection(aws_key, aws_secret)
bucket = s3conn.get_bucket(s3_bucket)

types = dict(bz2='application/x-bzip2', pbf='application/octet-stream', zip='application/zip')

for filename in argv[4:]:
    print >> stderr, filename, '...',

    type = types[filename[-3:]]
    key = bucket.new_key(filename)
    key.set_contents_from_file(open(filename), policy='public-read', headers={'Content-Type': type})

    print >> stderr, type
