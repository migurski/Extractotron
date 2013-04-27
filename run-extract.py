#!/usr/bin/env python
from sys import argv
from time import strftime
from tempfile import mkdtemp
from os import mkdir, chmod, symlink, remove
from os.path import join, exists, abspath, basename, dirname
from sh import curl

import logging

from extract import process_coastline, extract_cities, process_city_imposm
from extract import process_city_osm2pgsql, process_city_mapsforge
from extract.html import build_catalog
from extract.preview import render_preview
from extract.util import relative

# a small, default list of cities

cities = [
    dict(slug='west-oak', name='West Oakland', top=37.8325, left=-122.3443, bottom=37.7865, right=-122.2586),
    dict(slug='core-sf', name='Core San Francisco', top=37.8097, left=-122.4278, bottom=37.7617, right=-122.3842),
    dict(slug='berkeley', name='U.C. Berkeley', top=37.8810, left=-122.2752, bottom=37.8615, right=-122.2352),
    dict(slug='san-bruno', name='San Bruno', top=37.6457, left=-122.4666, bottom=37.6003, right=-122.3488),
    dict(slug='santa-clara', name='Santa Clara', top=37.3796, left=-121.9992, bottom=37.3215, right=-121.9110),
    dict(slug='san-jose', name='San Jose', top=37.3660, left=-121.9439, bottom=37.3125, right=-121.8485),
    ]

if __name__ == '__main__':

    logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')

    (url, history_dir) = argv[1:]

    catalog_dir = mkdtemp(dir=history_dir, prefix=strftime('%Y-%m-%d-'))
    mkdir(join(catalog_dir, 'logs'))
    chmod(catalog_dir, 0755)
    
    #
    # Download planet.
    #
    planet_path = abspath(join(catalog_dir, 'planet.osm.pbf'))
    logging.info('Setting up in %s' % catalog_dir)
    logging.info('Downloading %s to %s' % (url, basename(planet_path)))
    
    curl(url, o=planet_path)
    
    #
    # Process planet.
    #
    for city in cities:
        city['osm_path'] = relative(planet_path, '%(slug)s.osm.bz2' % city)
        city['pbf_path'] = relative(planet_path, '%(slug)s.osm.pbf' % city)
        city['mfg_path'] = relative(planet_path, '%(slug)s.osm.map' % city)
        city['o2p_path'] = relative(planet_path, '%(slug)s.osm2pgsql-shps.zip' % city)
        city['imp_path'] = relative(planet_path, '%(slug)s.imposm-shps.zip' % city)
        city['jpg_path'] = relative(planet_path, '%(slug)s.jpg' % city)
    
    process_coastline(planet_path)
    extract_cities(planet_path, cities)
    
    osm2pgsql_style_path = relative(__file__, 'postgis/osm2pgsql.style')
    
    for city in cities:
        process_city_osm2pgsql(city['osm_path'], city['o2p_path'], city['slug'], osm2pgsql_style_path)
        process_city_mapsforge(city['pbf_path'], city['mfg_path'], city['slug'])
        process_city_imposm(city['pbf_path'], city['imp_path'], city['slug'])
        render_preview(city['jpg_path'], city['top'], city['left'], city['bottom'], city['right'])
    
    templates_dir = relative(__file__, 'templates')
    catalog_path = join(catalog_dir, 'index.html')
    
    with open(catalog_path, 'w') as catalog:
        catalog.write(build_catalog(cities, catalog_dir, templates_dir).encode('utf8'))
    
    #
    # Link in history directory.
    #
    last_path = join(history_dir, 'last')
    logging.info('Linking %s to %s' % (last_path, catalog_dir))
    
    if exists(last_path):
        remove(last_path)
    
    symlink(catalog_dir, last_path)
