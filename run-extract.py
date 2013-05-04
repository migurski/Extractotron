#!/usr/bin/env python
from json import load
from time import strftime
from csv import DictReader
from tempfile import mkdtemp
from os import mkdir, chmod, symlink, remove
from os.path import join, exists, abspath, basename, dirname
from multiprocessing import Pool as _Pool
from sh import curl

import logging

from extract import process_coastline, extract_cities, process_city_imposm
from extract import process_city_osm2pgsql, process_city_mapsforge
from extract.html import build_catalog
from extract.preview import render_preview
from extract.util import relative

class Pool:
    def __init__(self):
        logging.info('Starting multiprocess Pool...')
        self._pool = _Pool()
    
    def __enter__(self):
        return self._pool.apply_async
    
    def __exit__(self, type, value, traceback):
        self._pool.close()
        self._pool.join()
        logging.info('...Pool is now closed.')

if __name__ == '__main__':

    logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')
    
    cities_path = relative(__file__, 'cities.txt')
    role_path = relative(__file__, 'chef/role-ec2.json')
    
    with open(role_path) as role_file:
        role = load(role_file)
        planet_url = role['planet']
        history_dir = join(role['workdir'], 'history')
    
    with open(cities_path) as cities_file:
        cities = [dict(slug=row['slug'], name=row['name'].decode('utf8'),
                       top=max(float(row['top']), float(row['bottom'])),
                       left=min(float(row['left']), float(row['right'])),
                       bottom=min(float(row['top']), float(row['bottom'])),
                       right=max(float(row['left']), float(row['right'])))
                  for row in DictReader(cities_file, dialect='excel-tab')]

    catalog_dir = mkdtemp(dir=history_dir, prefix=strftime('%Y-%m-%d-'))
    mkdir(join(catalog_dir, 'logs'))
    chmod(catalog_dir, 0755)
    
    #
    # Download planet.
    #
    planet_path = abspath(join(catalog_dir, 'planet.osm.pbf'))
    logging.info('Setting up in %s' % catalog_dir)
    logging.info('Downloading %s to %s' % (planet_url, basename(planet_path)))
    
    curl(planet_url, o=planet_path)
    
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
    
    with Pool() as apply:
        apply(process_coastline, (planet_path, ))
        apply(extract_cities, (planet_path, cities))
    
    osm2pgsql_style_path = relative(__file__, 'postgis/osm2pgsql.style')
    
    with Pool() as apply:
        for city in cities:
            apply(process_city_osm2pgsql, (city['osm_path'], city['o2p_path'], city['slug'], osm2pgsql_style_path))
            apply(process_city_mapsforge, (city['pbf_path'], city['mfg_path'], city['slug']))
            apply(process_city_imposm, (city['pbf_path'], city['imp_path'], city['slug']))
            apply(render_preview, (city['jpg_path'], city['top'], city['left'], city['bottom'], city['right']))
    
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
