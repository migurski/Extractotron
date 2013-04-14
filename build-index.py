from urllib import urlopen
from urlparse import urljoin, urlparse
from httplib import HTTPConnection
from re import compile
from csv import DictReader
from sys import argv, stderr
from math import cos, pi
import json

from dateutil import parser

from ModestMaps import mapByExtent
from ModestMaps.Core import Point
from ModestMaps.Geo import Location
from ModestMaps.OpenStreetMap import Provider

import lib

provider = Provider()
dimensions = Point(960, 600)

base_url = 'http://osm-extracted-metros.s3.amazonaws.com/log.txt'
extract_pat = compile(r'^((\S+)\.osm\.(bz2|pbf))\s+(\d+)$')
coastshape_pat = compile(r'^((\S+)\.coastline\.zip)\s+(\d+)$')
shp_imposm_pat = compile(r'^((\S+)\.imposm-shapefiles\.zip)\s+(\d+)$')
shp_osm2pgsql_pat = compile(r'^((\S+)\..*\bshapefiles\.zip)\s+(\d+)$')
coastline_pat = compile(r'^((\w+)-(latlon|merc)\.tar\.bz2)\s+(\d+)$')
months = '- Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'.split()

def nice_size(size):
    KB = 1024.
    MB = 1024. * KB
    GB = 1024. * MB
    TB = 1024. * GB

    if size < KB:
        size, suffix = size, 'B'
    elif size < MB:
        size, suffix = size/KB, 'KB'
    elif size < GB:
        size, suffix = size/MB, 'MB'
    elif size < TB:
        size, suffix = size/GB, 'GB'
    else:
        size, suffix = size/TB, 'TB'

    if size < 10:
        return '%.1f %s' % (size, suffix)
    else:
        return '%d %s' % (size, suffix)

def nice_time(time):
    if time < 15:
        return 'moments'
    if time < 90:
        return '%d seconds' % time
    if time < 60 * 60 * 1.5:
        return '%d minutes' % (time / 60.)
    if time < 24 * 60 * 60 * 1.5:
        return '%d hours' % (time / 3600.)
    if time < 7 * 24 * 60 * 60 * 1.5:
        return '%d days' % (time / 86400.)
    if time < 30 * 24 * 60 * 60 * 1.5:
        return '%d weeks' % (time / 604800.)

    return '%d months' % (time / 2592000.)

def nice_area(top, left, bottom, right):
    '''
    '''

    km2 = lib.area(left, top, right, bottom) / 1000000
    area = str(int(100 * round(km2 / 100)))
    pat = compile(r'(\d)(\d\d\d)\b')
    
    while pat.search(area):
        area = pat.sub(r'\1,\2', area)
    
    return area + ' km²'

if __name__ == '__main__':

    (index, ) = argv[1:]
    index = open(index, 'w')

    log = list(urlopen(base_url))
    start = parser.parse(log[0][len('# begin, '):])
    start = '%s %d, %s' % (months[start.month], start.day, start.year)

    files = dict()
    coast = dict()

    for line in log:
        if coastline_pat.match(line):

            match = coastline_pat.match(line)
            file, slug, prj, size = (match.group(g) for g in (1, 2, 3, 4))

            if slug not in coast:
                coast[slug] = dict()

            coast[slug][prj] = (file, int(size), urljoin(base_url, file))
            continue

        elif extract_pat.match(line):

            match = extract_pat.match(line)
            file, slug, ext, size = (match.group(g) for g in (1, 2, 3, 4))

            key, slug_file = ext, (file, int(size), urljoin(base_url, file))

        elif coastshape_pat.match(line):

            match = coastshape_pat.match(line)
            file, slug, size = (match.group(g) for g in (1, 2, 3))

            key, slug_file = 'coastline', (file, int(size), urljoin(base_url, file))

        elif shp_imposm_pat.match(line):

            match = shp_imposm_pat.match(line)
            file, slug, size = (match.group(g) for g in (1, 2, 3))

            key, slug_file = 'imposm shapefiles', (file, int(size), urljoin(base_url, file))

        elif shp_osm2pgsql_pat.match(line):

            match = shp_osm2pgsql_pat.match(line)
            file, slug, size = (match.group(g) for g in (1, 2, 3))

            key, slug_file = 'osm2pgsql shapefiles', (file, int(size), urljoin(base_url, file))

        else:
            continue

        if slug not in files:
            files[slug] = dict()

        files[slug][key] = slug_file

    coast['coastline-good'] = {}

    for prj in ('merc', 'latlon'):
        file = 'coastline-good-%s.tar.bz2' % prj
        href = urljoin(base_url, file)

        url = urlparse(href)
        conn = HTTPConnection(url.netloc)
        conn.request('HEAD', url.path)
        resp = conn.getresponse()
        size = resp.getheader('content-length')
        date = parser.parse(resp.getheader('last-modified'))
        date = '%s %d, %s' % (months[date.month], date.day, date.year)

        coast['coastline-good'][prj] = (file, int(size), href, date)

    cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))

    #

    print >> index, """<!DOCTYPE html>
<html lang="en">
<head>
	<title>Metro Extracts</title>
	<meta http-equiv="content-type" content="text/html; charset=utf-8">

    <link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet-0.5/leaflet.css" />
    <!--[if lte IE 8]>
        <link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet-0.5/leaflet.ie.css" />
    <![endif]-->
	<link rel="stylesheet" href="http://www.openstreetmap.us/~migurski/style.css" type="text/css" media="all">
    <link rel="stylesheet" href="style.css" type="text/css" media="all">

    <script src="http://cdn.leafletjs.com/leaflet-0.5/leaflet.js"></script>
    <script type="application/javascript">
    """

    map_cities = [{
                    'name': city['name'],
                    'slug': city['slug'],
                    'area': nice_area(*[float(city[k]) for k in 'top left bottom right'.split()]),
                    'bounds': '%(left)s %(bottom)s %(right)s %(top)s' % city,
                    'osm_size': nice_size(files[city['slug']]['bz2'][1]),
                    'pbf_size': nice_size(files[city['slug']]['pbf'][1])
                  }
                  for city
                  in cities
                  if city['slug'] in files]

    print >> index, 'var cities = %s;' % json.dumps(map_cities)

    print >> index, """
    </script>
    <script src="bbmap.js"></script>
</head>
<body>
    <h1>Metro Extracts</h1>
    <p>
        Parts of the <a href="http://www.openstreetmap.org/">OpenStreetMap database</a>
        for major world cities and their surrounding areas. The goal of these
        extracts is to make it easy to make maps for major world cities, even if
        they cross state or national boundaries.
    </p>
    <p>
        Each city includes:
    </p>
    <ol>
        <li>Bzip’ed OpenStreetMap <a href="http://wiki.openstreetmap.org/wiki/.osm">XML data</a> in an <tt>.osm.bz2</tt> file.</li>
        <li>Compressed OpenStreetMap <a href="http://wiki.openstreetmap.org/wiki/PBF">binary PBF data</a> in an <tt>.osm.pbf</tt> file.</li>
        <li><a href="#coastline">Coastline shapefile</a> extracts of the immediate area in a <tt>.zip</tt> file.</li>
        <li>Point, line and polygon shapefiles from <a href="http://wiki.openstreetmap.org/wiki/Osm2pgsql">Osm2pgsql</a> in a <tt>.zip</tt> file.</li>
    </ol>
    <p>
        Provided by <a href="http://mike.teczno.com">Michal Migurski</a> on an expected
        monthly basis <a href="https://github.com/migurski/Extractotron/">via extractotron</a>.
        Contact me <a href="https://github.com/migurski">via Github</a> to request new cities,
        or add them directly to
        <a href="https://github.com/migurski/Extractotron/blob/master/cities.txt">cities.txt</a>
        with a <a href="http://help.github.com/fork-a-repo/">fork</a>-and-<a href="http://help.github.com/send-pull-requests/">pull-request</a>.
        Thanks <a href="http://somebits.com/">Nelson Minar</a> for contributing the map browser,
        <a href="http://www.smartchicagocollaborative.org/">Smart Chicago</a> for EC2 funding, and all
        <a href="https://github.com/migurski/Extractotron/commits/master/cities.txt">cities.txt contributors</a>.
    </p>
    <h2>Updated From <a href="http://planet.openstreetmap.org/">Planet</a> %(start)s</h2>
    <div id="bbMap"></div>
    <ul class="links">""" % locals()

    cities.sort(key=lambda city: (city['group'], city['name']))
    last_group = None

    for city in cities:
        if city['slug'] in files:
            if city['group'] != last_group:
                print >> index, '<li class="group">%(group)s:</li>' % city
                last_group = city['group']
            print >> index, '<li class="link"><a href="#%(slug)s">%(name)s</a></li>' % city

    print >> index, '''
    </ul>
    <p id="archive-note">
        An archived copy of this collection of extracts from the
        <a href="http://archive.org/download/metro.teczno.com/planet-120314.osm.bz2">March 14th 2012 Planet file</a>
        (just before the <a href="http://lists.openstreetmap.org/pipermail/talk/2012-January/061800.html">April, 2012</a>
        <a href="http://www.osmfoundation.org/wiki/License/We_Are_Changing_The_License">license changeover</a>)
        is available at <a href="http://archive.org/download/metro.teczno.com">archive.org</a>.
        Extracts here will continue to be updated into the future.
    </p>
    <ul>
    '''

    cities.sort(key=lambda city: city['name'])

    for city in cities:
        slug = city['slug']
        name = city['name']

        try:
            ul = Location(float(city['top']), float(city['left']))
            lr = Location(float(city['bottom']), float(city['right']))
        except ValueError:
            print >> stderr, 'Failed on %(name)s (%(slug)s)' % city
            raise
        else:
            mmap = mapByExtent(provider, ul, lr, dimensions)

        if slug in files:
            bz2_file, bz2_size, bz2_href = files[slug]['bz2']
            pbf_file, pbf_size, pbf_href = files[slug]['pbf']

            list = ('<li class="file"><a href="%s">%s %s OSM data</a></li>' * 2) \
                 % (bz2_href, nice_size(bz2_size), 'bzip’ed XML',
                    pbf_href, nice_size(pbf_size), 'binary PBF')

            if 'coastline' in files[slug]:
                coast_file, coast_size, coast_href = files[slug]['coastline']
                list += '<li class="file"><a href="%s">%s coastline shapefile</a></li>' % (coast_href, nice_size(coast_size))

            if 'osm2pgsql shapefiles' in files[slug]:
                shape_file, shape_size, shape_href = files[slug]['osm2pgsql shapefiles']
                list += '<li class="file"><a href="%s">%s osm2pgsql shapefiles</a></li>' % (shape_href, nice_size(shape_size))

            if 'imposm shapefiles' in files[slug]:
                shape_file, shape_size, shape_href = files[slug]['imposm shapefiles']
                list += '<li class="file"><a href="%s">%s imposm shapefiles</a></li>' % (shape_href, nice_size(shape_size))

            center = mmap.pointLocation(Point(dimensions.x/2, dimensions.y/2))
            zoom = mmap.coordinate.zoom
            href = 'http://www.openstreetmap.org/?lat=%.3f&amp;lon=%.3f&amp;zoom=%d&amp;layers=M' % (center.lat, center.lon, zoom)

            print >> index, """
                <li class="city">
                    <a name="%(slug)s" href="%(href)s"><img src="previews/%(slug)s.jpg"></a>
                    <h3>%(name)s</h3>
                    <ul>%(list)s</ul>
                </li>""" % locals()

    print >> index, """</ul>"""

    if 'processed_p' in coast:
        print >> index, """<h2><a name="coastline">Coastline Shapefiles</a></h2>
        <p>
            <a href="http://wiki.openstreetmap.org/wiki/Coastline">Coastline</a> objects
            in OpenStreetMap are not directly usable for rendering. They must first be
            joined into continent-sized polygons by the
            <a href="http://wiki.openstreetmap.org/wiki/Coastline_error_checker">coastline error checker</a>
            and converted to shapefiles. The files available below are up-to-date,
            error-corrected versions of the worldwide coastline generated using the code available from
            <a href="http://svn.openstreetmap.org/applications/utils/coastcheck/">Subversion</a>.
        </p>
        <ul class="coast">
            <li><a href="%s">Coastline polygons</a>: automatically generated areas, divided into 100km squares.<br><a href="%s">Mercator</a> (%s) and <a href="%s">unprojected</a> (%s) shapefiles.<br>Updated from <a href="http://planet.openstreetmap.org/">Planet</a> %s.</li>
            <!--
            <li><a href="%s">Good coastline polygons</a>: coastline polygons chosen to fill gaps in new data with old data.<br><a href="%s">Mercator</a> (%s) and <a href="%s">unprojected</a> (%s) shapefiles.<br>Last manually selected %s.</li>
            -->
        </ul>
        <p>
            The coastline usually has errors in it. These files help show where
            those errors might be lurking, so that you can fix OpenStreetMap for
            the next time the coastline polygons are rendered:
        </p>
        <ul class="coast">
            <li><a href="%s">Incomplete lines</a>: incomplete coastlines, joined into linestrings.<br><a href="%s">Mercator</a> (%s) and <a href="%s">unprojected</a> (%s) shapefiles.</li>
            <li><a href="%s">Error points</a>: points where the coastline checker found errors.<br><a href="%s">Mercator</a> (%s) and <a href="%s">unprojected</a> (%s) shapefiles.</li>
            <li><a href="%s">PostGIS error points</a>: points where PostGIS found topology errors.<br><a href="%s">Mercator</a> (%s) and <a href="%s">unprojected</a> (%s) shapefiles.</li>
            <li><a href="%s">PostGIS missing tiles</a>: areas where PostGIS was unable to parse a geometry.<br><a href="%s">Mercator</a> (%s) and <a href="%s">unprojected</a> (%s) shapefiles.</li>
        </ul>""" \
        % (
            coast['processed_p']['merc'][2],
            coast['processed_p']['merc'][2], nice_size(coast['processed_p']['merc'][1]),
            coast['processed_p']['latlon'][2], nice_size(coast['processed_p']['latlon'][1]),
            start,
            coast['coastline-good']['merc'][2],
            coast['coastline-good']['merc'][2], nice_size(coast['coastline-good']['merc'][1]),
            coast['coastline-good']['latlon'][2], nice_size(coast['coastline-good']['latlon'][1]),
            coast['coastline-good']['merc'][3],
            coast['processed_i']['merc'][2],
            coast['processed_i']['merc'][2], nice_size(coast['processed_i']['merc'][1]),
            coast['processed_i']['latlon'][2], nice_size(coast['processed_i']['latlon'][1]),
            coast['coastline_p']['merc'][2],
            coast['coastline_p']['merc'][2], nice_size(coast['coastline_p']['merc'][1]),
            coast['coastline_p']['latlon'][2], nice_size(coast['coastline_p']['latlon'][1]),
            coast['post_errors']['merc'][2],
            coast['post_errors']['merc'][2], nice_size(coast['post_errors']['merc'][1]),
            coast['post_errors']['latlon'][2], nice_size(coast['post_errors']['latlon'][1]),
            coast['post_missing']['merc'][2],
            coast['post_missing']['merc'][2], nice_size(coast['post_missing']['merc'][1]),
            coast['post_missing']['latlon'][2], nice_size(coast['post_missing']['latlon'][1])
        )

    print >> index, """    <script type="text/javascript">
    makeBbMap();
    </script>""";
    print >> index, """</body></html>"""
