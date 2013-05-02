#!/usr/bin/env python
from os import stat
from json import load
from glob import glob
from os.path import basename, join
from mimetypes import guess_type
from StringIO import StringIO
from time import gmtime, strftime

import logging

from extract.util import relative

from boto import connect_s3

def city_file_paths(dir):
    '''
    '''
    for file_path in sorted(glob(join(dir, '*.osm.bz2'))):
        file_name = basename(file_path)
        file_slug = file_name[:-8]
        
        for file_path in glob(join(dir, file_slug + '.*')):
            yield file_path

if __name__ == '__main__':

    logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')

    role_path = relative(__file__, 'chef/role-ec2.json')
    
    with open(role_path) as role_file:
        role = load(role_file)
        bucket = role['bucket']

    s3 = connect_s3().create_bucket(bucket)
    log = StringIO()
    
    file_path = join('/usr/local/work/history/last', 'planet.osm.pbf')
    file_time = stat(file_path).st_ctime

    print >> log, '# begin,', strftime('%a %b %d %H:%M:%S %Z %Y', gmtime(file_time))
    
    uploads = []
    
    for file_path in city_file_paths('/usr/local/work/history/last'):
        file_name = basename(file_path)
        file_size = stat(file_path).st_size
        
        print >> log, file_name, file_size
        
        key = s3.new_key(file_name)
        mime_type = guess_type(file_path)[0]
        kwargs = dict(headers={'Content-Type': mime_type}, policy='public-read')
        key.set_contents_from_filename(file_path, **kwargs)
        
        logging.info('Uploaded %s' % key.name)

    key = s3.new_key('log.txt')
    kwargs = dict(headers={'Content-Type': 'text/plain'}, policy='public-read')
    key.set_contents_from_string(log.getvalue(), **kwargs)
    
    logging.info('Uploaded %s' % key.name)
