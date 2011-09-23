""" Run an extractor instance.
"""
from optparse import OptionParser
from boto.ec2 import EC2Connection

parser = OptionParser(usage="%prog [options] <aws key> <aws secret> <s3 bucket>")

defaults = dict(ami_id='ami-68ad5201', type='m1.large')

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

    user_data = open('extract.sh').read()
    user_data = user_data.replace('osmosis.sh;\n', open('osmosis.sh').read())
    user_data = user_data.replace('$KEY', aws_key)
    user_data = user_data.replace('$SECRET', aws_secret)
    user_data = user_data.replace('$BUCKET', s3_bucket)
    
    conn = EC2Connection(aws_key, aws_secret)
    print conn.run_instances(options.ami_id, instance_type=options.type, user_data=user_data)