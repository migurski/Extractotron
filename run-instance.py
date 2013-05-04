#!/usr/bin/env python
""" Run an extractor instance.
"""
from optparse import OptionParser
from boto.ec2 import EC2Connection

parser = OptionParser(usage="%prog [options] <s3 bucket>")

defaults = dict(ami_id='ami-096d0060', type='m2.4xlarge', run=True, upload=True, kill=True)

parser.set_defaults(**defaults)

parser.add_option('--ami-id', dest='ami_id',
                  help='AMI ID, default %(ami_id)s' % defaults)

parser.add_option('--type', dest='type',
                  help='Instance type, default %(type)s' % defaults)

parser.add_option('--no-run', dest='run', action='store_false',
                  help="Don't actually run the instance, just output user-data.")

parser.add_option('--no-upload', dest='upload', action='store_false',
                  help="Don't instruct the instance to upload resulting files.")

parser.add_option('--no-kill', dest='kill', action='store_false',
                  help="Don't instruct the instance to kill itself at the end.")

if __name__ == '__main__':
    
    options, args = parser.parse_args()
    
    user_data = open('bootstrap.sh').read()
    ec2 = EC2Connection()
    
    if options.upload or options.kill:
        user_data += '''
#
# Leave AWS credentials someplace useful.
#
echo '[Credentials]' > /etc/boto.cfg
echo 'aws_access_key_id = %s' >> /etc/boto.cfg
echo 'aws_secret_access_key = %s' >> /etc/boto.cfg
''' % (ec2.access_key, ec2.secret_key)

    if options.upload:
        user_data += '''
#
# Upload completed files.
#
/usr/local/extractotron/run-upload.py
'''

    if options.kill:
        user_data += '''
#
# Kill instance.
#
/usr/local/extractotron/run-terminate.py
'''

    if options.run:
        # bid a penny over median
        history = ec2.get_spot_price_history(instance_type=options.type)
        median = sorted([h.price for h in history])[len(history)/2]
        bid = median + .01
        
        print ec2.request_spot_instances(bid, options.ami_id, instance_type=options.type, user_data=user_data, key_name='whiteknight-id_rsa.pub', security_groups=['quicklaunch-0'])
    
    else:
        print user_data
