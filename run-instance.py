""" Run an extractor instance.
"""
from optparse import OptionParser
from boto.ec2 import EC2Connection
from httplib import HTTPConnection
from urlparse import urljoin
from urllib import urlencode

parser = OptionParser(usage="%prog [options] <s3 bucket>")

defaults = dict(ami_id='ami-bffa6fd6', type='m2.4xlarge', run=True, upload=True, kill=True)

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

def post_script(filename):
    """
    """
    form = dict(language='Bash', title=filename)
    form.update(dict(content=open(filename).read()))

    body = urlencode(form)
    head = {'Content-Length': len(body), 'Content-Type': 'application/x-www-form-urlencoded'}
    conn = HTTPConnection('dpaste.com')

    conn.request('POST', '/api/v1/', headers=head)
    conn.send(body)
    
    resp = conn.getresponse()
    
    if resp.status not in range(300, 399):
        print resp.getheaders()
        raise Exception('Received status %d from dpaste.com' % resp.status)
    
    href = resp.getheader('location')
    href = urljoin(href, 'plain/')
    
    return href

if __name__ == '__main__':
    
    try:
        options, (s3_bucket, ) = parser.parse_args()
    except ValueError:
        parser.print_usage()
        exit(1)
    
    user_data = open('extract.sh').read()
    ec2 = EC2Connection()
    
    if options.upload:
        user_data += open('upload-files.sh').read()

    if options.kill:
        user_data += open('kill-self.sh').read()

    user_data = user_data.replace('$KEY', ec2.access_key)
    user_data = user_data.replace('$SECRET', ec2.secret_key)
    user_data = user_data.replace('$BUCKET', s3_bucket)
    user_data = user_data.replace('$OSMOSIS_HREF', post_script('osmosis.sh'))
    user_data = user_data.replace('$OSM2PGSQL_HREF', post_script('osm2pgsql.sh'))
    user_data = user_data.replace('$COASTSHAPES_HREF', post_script('coastshapes.sh'))
    user_data = user_data.replace('$COASTERRORS_HREF', post_script('coastline-errors.sh'))
    user_data = user_data.replace('$OSM2STYLE_HREF', post_script('osm2pgsql.style'))
    
    if options.run:
        # bid a penny over median
        history = ec2.get_spot_price_history(instance_type=options.type)
        median = sorted([h.price for h in history])[len(history)/2]
        bid = median + .01
        
        print ec2.request_spot_instances(bid, options.ami_id, instance_type=options.type, user_data=user_data, key_name='whiteknight-id_rsa.pub', security_groups=['quicklaunch-0'])
    
    else:
        print user_data
