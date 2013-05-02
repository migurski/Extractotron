from os import remove
from os.path import join, exists, basename, dirname
from tempfile import mkdtemp
from shutil import rmtree
from math import sqrt
from glob import glob

import logging

from numpy import array
from scipy.cluster.vq import kmeans2

from .util import relative, open_logs, Popen

mercator = '+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs'

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
    
    log = open(relative(planet_path, 'logs/osmosis.cmd'), 'w')
    
    osmosis = [
        'osmosis', '--rb', planet_path, '--lp', 'interval=60',
        '--tee', 'outputCount=%d' % len(groups)
        ]
    
    print >> log, ' '.join(osmosis)
    
    for group in groups:
    
        osmosis += [
            '--bb', 'top=%(top).4f' % group, 'left=%(left).4f' % group,
            'bottom=%(bottom).4f' % group, 'right=%(right).4f' % group,
            '--b', '--tee', 'outputCount=%d' % len(group['cities'])
            ]
    
        print >> log, ' ', ' '.join(osmosis[-8:])
        
        for city in group['cities']:
            osmosis += [
                '--bb', 'top=%(top).4f' % city, 'left=%(left).4f' % city,
                'bottom=%(bottom).4f' % city, 'right=%(right).4f' % city,
                '--tee', 'outputCount=2',
                '--wx', city['osm_path'],
                '--wb', city['pbf_path']
                ]
        
            print >> log, '   ', ' '.join(osmosis[-11:-4])
            print >> log, '   ', ' '.join(osmosis[-4:])
    
    log.close()
    
    return osmosis

def extract_cities(planet_path, cities):
    ''' Process planet file through osmosis and output a file for each city.
    '''
    logging.info('Extracting %d cities from %s' % (len(cities), basename(planet_path)))
    logs = open_logs(relative(planet_path, 'logs/osmosis'))
    
    osmosis = Popen(osmosis_command(planet_path, cities), **logs)
    osmosis.wait()
    
    logs['stdout'].close()
    logs['stderr'].close()

def process_coastline(planet_path):
    ''' Process planet file through osmcoastline and output a zipped shapefile.
    '''
    coast_planet_path = relative(planet_path, 'coastline.osm.pbf')
    coast_sqlite_path = relative(planet_path, 'coastline.db')
    coast_shape_base = relative(planet_path, 'land-polygons')
    coast_shape_path = coast_shape_base + '.shp'
    coast_zip_path = coast_shape_base + '.zip'
    
    logging.info('Processing coastline from %s to %s' % (basename(planet_path), basename(coast_sqlite_path)))
    logs = open_logs(relative(planet_path, 'logs/process-coastline'))
    
    if exists(coast_planet_path):
        remove(coast_planet_path)
    
    if exists(coast_sqlite_path):
        remove(coast_sqlite_path)
    
    for extension in ('.zip', '.shp', '.shx', '.prj', '.dbf'):
        if exists(coast_shape_base + extension):
            remove(coast_shape_base + extension)
    
    #
    # Filter complete planet down to only natural=coastline ways.
    #
    osmcoastline_filter = Popen(['osmcoastline_filter', '-o', coast_planet_path, planet_path], **logs)
    osmcoastline_filter.wait()
    
    #
    # Generate coastline sqlite database, creating land + water polygons,
    # coastal rings, and skipping spatial index.
    #
    osmcoastline = Popen('osmcoastline -p both -r -v -i -o'.split() + [coast_sqlite_path, coast_planet_path], **logs)
    osmcoastline.wait()
    
    logging.info('Extracting shapefiles from %s to %s' % (basename(coast_sqlite_path), basename(coast_zip_path)))
    
    #
    # Extract land polygons to mercator-projected shapefiles.
    #
    ogr2ogr = Popen(['ogr2ogr', '-t_srs', mercator, '-skipfailures', coast_shape_path, coast_sqlite_path, 'land_polygons'], **logs)
    ogr2ogr.wait()
    
    #
    # Archive shapefiles from previous step into a zip file.
    #
    zip = Popen(['zip', '-j', coast_zip_path] + [coast_shape_base + ext for ext in ('.shp', '.shx', '.prj', '.dbf')], **logs)
    zip.wait()
    
    for extension in ('.shp', '.shx', '.prj', '.dbf'):
        if exists(coast_shape_base + extension):
            remove(coast_shape_base + extension)
    
    logs['stdout'].close()
    logs['stderr'].close()

def process_city_osm2pgsql(osm_path, o2p_path, slug, osm2pgsql_style_path):
    ''' Pass extracted OSM data through osm2pgsql to create shapefile archive.
    '''
    prefix = '%s_osm' % slug.replace('-', '_')
    
    logging.info('Converting from from %s to %s' % (basename(osm_path), basename(o2p_path)))
    logs = open_logs(relative(osm_path, 'logs/process-osm2pgsql-%s' % slug))
    
    if exists(o2p_path):
        remove(o2p_path)
    
    #
    # Import city extract to PostGIS, in unprojected utf-8 slim mode.
    # Clobber existing tables, if any exist.
    #
    osm2pgsql = Popen('osm2pgsql -sluc -C 1024 -i work -U osm -d osm'.split()
                      + ['-S', osm2pgsql_style_path, '-p', prefix, osm_path],
                      **logs)

    osm2pgsql.wait()
    
    filenames = []
    
    for geomtype in ('point', 'polygon', 'line'):
        table_name = '%(prefix)s_%(geomtype)s' % locals()
        shape_base = relative(osm_path, '%(slug)s.osm-%(geomtype)s' % locals())
        shape_path = shape_base + '.shp'
        
        for extension in ('.shp', '.shx', '.prj', '.dbf'):
            if exists(shape_base + extension):
                remove(shape_base + extension)

        #
        # Extract PostGIS tables to shapefiles by geometry type.
        #
        pgsql2shp = Popen('pgsql2shp -rk -u osm -f'.split() + [shape_path, 'osm', table_name], **logs)
        pgsql2shp.wait()
        
        filenames += glob(shape_base + '.???')
    
    #
    # Archive shapefiles from previous steps into a zip file.
    #
    zip = Popen(['zip', '-j', o2p_path] + filenames, **logs)
    zip.wait()
    
    for filename in filenames:
        remove(filename)
    
    #
    # Drop city tables from PostGIS.
    #
    for suffix in ('line', 'nodes', 'point', 'polygon', 'rels', 'roads', 'ways'):
        psql = Popen(['psql', '-c', 'DROP TABLE %(prefix)s_%(suffix)s' % locals(), '-U', 'osm', 'osm'], **logs)
        psql.wait()
    
    logs['stdout'].close()
    logs['stderr'].close()

def process_city_imposm(pbf_path, imp_path, slug):
    ''' Pass extracted OSM data through imposm to create shapefile archive.
    '''
    prefix = '%s' % slug.replace('-', '_')
    
    mappings = (
        'roads', 'roads_gen0', 'roads_gen1', 'admin', 'aeroways', 'amenities',
        'buildings', 'landusages', 'landusages_gen0', 'landusages_gen1', 'mainroads',
        'mainroads_gen0', 'mainroads_gen1', 'minorroads', 'motorways', 'motorways_gen0',
        'motorways_gen1', 'places', 'railways', 'railways_gen0', 'railways_gen1',
        'transport_areas', 'transport_points', 'waterareas', 'waterareas_gen0',
        'waterareas_gen1', 'waterways'
        )

    logging.info('Converting from from %s to %s' % (basename(pbf_path), basename(imp_path)))
    logs = open_logs(relative(pbf_path, 'logs/process-imposm-%s' % slug))
    
    if exists(imp_path):
        remove(imp_path)
    
    tempdir = mkdtemp(dir=dirname(imp_path), prefix='imposm-%s.' % slug)
    
    #
    # Import city extract to PostGIS tables with default imposm mapping
    # in mercator projection. Clobber existing tables, if any exist.
    #
    imposm = Popen(['imposm', '--read', '--cache-dir', tempdir,
                    '--write', '--table-prefix=%(prefix)s_' % locals(),
                    '--connect', 'postgis://osm:@127.0.0.1/osm', pbf_path],
                   **logs)

    imposm.wait()
    
    filenames = []
    
    for mapping in mappings:
        table_name = '%(prefix)s_%(mapping)s' % locals()
        shape_base = join(tempdir, '%(slug)s.osm-%(mapping)s' % locals())
        shape_path = shape_base + '.shp'
        
        for extension in ('.shp', '.shx', '.prj', '.dbf'):
            if exists(shape_base + extension):
                remove(shape_base + extension)

        #
        # Extract PostGIS tables to shapefiles by geometry type.
        #
        pgsql2shp = Popen('pgsql2shp -rk -u osm -f'.split() + [shape_path, 'osm', table_name], **logs)
        pgsql2shp.wait()
        
        filenames += glob(shape_base + '.???')
    
    #
    # Archive shapefiles from previous steps into a zip file.
    #
    zip = Popen(['zip', '-j', imp_path] + filenames, **logs)
    zip.wait()
    
    if not exists(imp_path):
        raise Exception('Failed to create %s' % imp_path)
    
    rmtree(tempdir)
    
    #
    # Drop city tables from PostGIS.
    #
    for mapping in mappings:
        object = 'TABLE' if mapping not in ('roads', 'roads_gen0', 'roads_gen1') else 'VIEW'
        psql = Popen(['psql', '-c', 'DROP %(object)s %(prefix)s_%(mapping)s' % locals(), '-U', 'osm', 'osm'], **logs)
        psql.wait()
    
    logs['stdout'].close()
    logs['stderr'].close()

def process_city_mapsforge(pbf_path, mfg_path, slug):
    ''' Pass extracted OSM data through osmosis to create mapsforge file.
    '''
    logging.info('Converting from from %s to %s' % (basename(pbf_path), basename(mfg_path)))
    logs = open_logs(relative(pbf_path, 'logs/process-mapsforge-%s' % slug))
    
    if exists(mfg_path):
        remove(mfg_path)
    
    #
    # Generate MapsForge binary map file with MapFileWriter osmosis plugin.
    #
    osmosis = Popen('osmosis -p org.mapsforge.map.writer.osmosis.MapFileWriterPluginLoader'.split()
                    + ['--rb', pbf_path, '--mw', 'file=%s' % mfg_path],
                    **logs)

    osmosis.wait()
    
    if not exists(mfg_path):
        raise Exception('Failed to create %s' % mfg_path)
    
    logs['stdout'].close()
    logs['stderr'].close()
