""" Run an extractor instance.
"""
from optparse import OptionParser
from boto.ec2 import EC2Connection

parser = OptionParser(usage="%prog [options] <aws key> <aws secret> <s3 bucket>")

defaults = dict(ami_id='ami-e2af508b', type='m1.small')

parser.set_defaults(**defaults)

parser.add_option('--ami-id', dest='ami_id',
                  help='AMI ID, default %(ami_id)s' % defaults)

parser.add_option('--type', dest='type',
                  help='Instance type, default %(type)s' % defaults)

if __name__ == '__main__':
    
    try:
        options, (aws_key, aws_secret, s3_bucket) = parser.parse_args()
    except ValueError:
        parser.print_usage()
        exit(1)

    conn = EC2Connection(aws_key, aws_secret)
    
    user_data = """#!/bin/sh
K=%(aws_key)s
S=%(aws_secret)s
B=%(s3_bucket)s
U=https://raw.github.com/migurski/Extractotron/master/extract.sh
curl -s $U | KEY=$K SECRET=$S BUCKET=$B sh > /mnt/progress.txt 2>&1
""" % locals()
    
    print conn.run_instances(options.ami_id, instance_type=options.type, user_data=user_data)