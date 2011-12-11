""" Run an extractor instance.
"""
from optparse import OptionParser
from boto.ec2 import EC2Connection
from httplib import HTTPConnection
from urlparse import urljoin
from urllib import urlencode

parser = OptionParser(usage="%prog [options] <aws key> <aws secret> <s3 bucket>")

defaults = dict(ami_id='ami-c0f7c5b4', type='m2.xlarge', run=True)

parser.set_defaults(**defaults)

parser.add_option('--ami-id', dest='ami_id',
                  help='AMI ID, default %(ami_id)s' % defaults)

parser.add_option('--type', dest='type',
                  help='Instance type, default %(type)s' % defaults)

parser.add_option('--no-run', dest='run', action='store_false',
                  help="Don't actually run the instance, just output user-data.")

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
    
    if resp.status >= 400:
        print resp.getheaders()
        raise Exception('Received status %d from dpaste.com' % resp.status)
    
    href = resp.getheader('location')
    href = urljoin(href, 'plain/')
    
    return href

if __name__ == '__main__':
    
    try:
        options, (aws_key, aws_secret, s3_bucket) = parser.parse_args()
    except ValueError:
        parser.print_usage()
        exit(1)
    
    user_data = open('extract.sh').read()

    user_data = user_data.replace('$KEY', aws_key)
    user_data = user_data.replace('$SECRET', aws_secret)
    user_data = user_data.replace('$BUCKET', s3_bucket)
    user_data = user_data.replace('$OSMOSIS_HREF', post_script('osmosis.sh'))
    user_data = user_data.replace('$COASTSHAPES_HREF', post_script('coastshapes.sh'))
    user_data = user_data.replace('$COASTERRORS_HREF', post_script('coastline-errors.sh'))
    
    if options.run:
        conn = EC2Connection(aws_key, aws_secret)
        print conn.run_instances(options.ami_id, instance_type=options.type, user_data=user_data)
    
    else:
        print user_data