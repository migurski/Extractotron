#!/usr/bin/env python
from sys import argv
from os import mkdir
from subprocess import Popen
from os.path import join, exists, dirname, abspath
from math import sqrt
from sh import curl

from numpy import array
from scipy.cluster.vq import kmeans2

def group_cities(cities):
    ''' Cluster cities into sqrt(len) groups by k-means in unprojected space.
    
        Returns a list of dictionaries, each with a 'cities' list and
        overall bounding box under 'top', 'left', bottom', 'right'.
    '''
    lats = [city['top']/2 + city['bottom']/2 for city in cities]
    lons = [city['left']/2 + city['right']/2 for city in cities]
    
    data = array(zip(lons, lats))
    k = int(round(sqrt(len(cities))))
    
    centers, labels = kmeans2(data, k, iter=100, minit='points')
    groups = [dict(cities=[], lats=[], lons=[]) for i in range(k)]
    
    for (index, label) in enumerate(labels):
        group, city = groups[label], cities[index]

        group['lats'] += (city['top'], city['bottom'])
        group['lons'] += (city['left'], city['right'])
        group['cities'].append(city)
    
    for group in groups:
        group['top'] = max(group['lats'])
        group['left'] = min(group['lons'])
        group['bottom'] = min(group['lats'])
        group['right'] = max(group['lons'])

        del group['lats'], group['lons']
    
    return groups

def osmosis_command(planet_path, cities):
    ''' Generate a complete osmosis command for use with subprocess.Popen().
    '''
    groups = group_cities(cities)

    osmosis = [
        'osmosis', '--rb', planet_path, '--lp', 'interval=60',
        '--tee', 'outputCount=%d' % len(groups)
        ]
    
    print ' '.join(osmosis)
    
    for group in groups:
    
        osmosis += [
            '--bb', 'top=%(top).4f' % group, 'left=%(left).4f' % group,
            'bottom=%(bottom).4f' % group, 'right=%(right).4f' % group,
            '--b', '--tee', 'outputCount=%d' % len(group['cities'])
            ]
    
        print ' ', ' '.join(osmosis[-8:])
        
        for city in group['cities']:
            osmosis += [
                '--bb', 'top=%(top).4f' % city, 'left=%(left).4f' % city,
                'bottom=%(bottom).4f' % city, 'right=%(right).4f' % city,
                '--tee', 'outputCount=2',
                '--wx', city['osm_path'],
                '--wb', city['pbf_path']
                ]
        
            print '   ', ' '.join(osmosis[-11:-4])
            print '   ', ' '.join(osmosis[-4:])
    
    return osmosis

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

    (url, dir) = argv[1:]
    dir += '/stuff'
    
    try:
        mkdir(dir)
    except OSError:
        if not exists(dir):
            raise
    
    #
    # Download complete planet.
    #
    planet_path = abspath(join(dir, 'planet.osm.pbf'))
    
    for city in cities:
        city['osm_path'] = join(dirname(planet_path), '%(slug)s.osm.bz2' % city)
        city['pbf_path'] = join(dirname(planet_path), '%(slug)s.osm.pbf' % city)
    
    curl(url, o=planet_path)
    
    osmosis = Popen(osmosis_command(planet_path, cities))
    osmosis.wait()
