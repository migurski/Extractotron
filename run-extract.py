#!/usr/bin/env python
from sys import argv
from os import mkdir
from os.path import join, exists, abspath, basename
from sh import curl

import logging

from extract import process_coastline, extract_cities, process_city_osm2pgsql
from extract.util import relative

# a small, default list of cities

cities = [
    dict(slug='west-oak', name='West Oakland', top=37.8325, left=-122.3443, bottom=37.7865, right=-122.2586),
    dict(slug='core-sf', name='Core San Francisco', top=37.8097, left=-122.4278, bottom=37.7617, right=-122.3842),
    dict(slug='berkeley', name='U.C. Berkeley', top=37.8810, left=-122.2752, bottom=37.8615, right=-122.2352),
    dict(slug='san-bruno', name='San Bruno', top=37.6457, left=-122.4666, bottom=37.6003, right=-122.2352),
    dict(slug='santa-clara', name='Santa Clara', top=37.3796, left=-121.9992, bottom=37.3215, right=-121.9110),
    dict(slug='san-jose', name='San Jose', top=37.3660, left=-121.9439, bottom=37.3125, right=-121.8485),
    ]

if __name__ == '__main__':

    logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')

    (url, dir) = argv[1:]
    dir += '/stuff'
    
    for newdir in (dir, dir + '/logs'):
        try:
            mkdir(newdir)
        except OSError:
            if not exists(newdir):
                raise
    
    #
    # Download planet.
    #
    planet_path = abspath(join(dir, 'planet.osm.pbf'))
    logging.info('Downloading %s to %s' % (url, basename(planet_path)))
    
    curl(url, o=planet_path)
    
    #
    # Process planet.
    #
    for city in cities:
        city['osm_path'] = relative(planet_path, '%(slug)s.osm.bz2' % city)
        city['pbf_path'] = relative(planet_path, '%(slug)s.osm.pbf' % city)
    
    process_coastline(planet_path)
    extract_cities(planet_path, cities)
    
    osm2pgsql_style_path = relative(__file__, 'postgis/osm2pgsql.style')
    
    for city in cities:
        process_city_osm2pgsql(city['osm_path'], city['slug'], osm2pgsql_style_path)
