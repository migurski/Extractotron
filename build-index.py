from urllib import urlopen
from urlparse import urljoin
from operator import itemgetter
from re import compile
from csv import DictReader
from sys import argv, stderr

from ModestMaps import mapByExtent
from ModestMaps.Core import Point
from ModestMaps.Geo import Location
from ModestMaps.OpenStreetMap import Provider

provider = Provider()
dimensions = Point(960, 600)

base_url = 'http://osm-metro-extracts.s3.amazonaws.com/log.txt'
extract_pat = compile(r'^((\S+)\.osm\.(bz2|pbf))\s+(\d+)$')

def nice_size(size):
    KB = 1024.
    MB = 1024. * KB
    GB = 1024. * MB
    TB = 1024. * GB
    
    if size < KB:
        size, suffix = size, ''
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

if __name__ == '__main__':

    (index, ) = argv[1:]
    index = open(index, 'w')
    
    log = urlopen(base_url)
    log = (line for line in log if extract_pat.match(line))
    
    files = dict()
    
    for line in log:
        match = extract_pat.match(line)
        file, slug, ext, size = (match.group(g) for g in (1, 2, 3, 4))
        
        if slug not in files:
            files[slug] = dict()
        
        href = urljoin(base_url, file)
        files[slug][ext] = (file, int(size), href)
    
    #
    
    print >> index, """<!DOCTYPE html>
<html lang="en">
<head>
	<title>Metro Extracts</title>
	<meta http-equiv="content-type" content="text/html; charset=utf-8">
    <link rel="stylesheet" href="style.css" type="text/css" media="all">
</head>
<body>
    <ul>"""

    cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))
    cities.sort(key=itemgetter('slug'))
    
    for city in cities:
        if city['slug'] in files:
            print >> index, '<li class="link"><a href="#%(slug)s">%(name)s</a></li>' % city
    
    print >> index, """</ul><ul>"""
    
    for city in cities:
        slug = city['slug']
        name = city['name']
    
        ul = Location(float(city['top']), float(city['left']))
        lr = Location(float(city['bottom']), float(city['right']))
        mmap = mapByExtent(provider, ul, lr, dimensions)
        
        if slug in files:
            list = ['<li class="file"><a href="%s">%s</a> (%s)</li>' % (href, file, nice_size(size))
                    for (ext, (file, size, href))
                    in sorted(files[slug].items())]
        
            list = ''.join(list)
            
            center = mmap.pointLocation(Point(dimensions.x/2, dimensions.y/2))
            zoom = mmap.coordinate.zoom
            href = 'http://www.openstreetmap.org/?lat=%.3f&amp;lon=%.3f&amp;zoom=%d&amp;layers=M' % (center.lat, center.lon, zoom)
            
            print >> index, """
                <li class="city">
                    <a name="%(slug)s" href="%(href)s"><img src="previews/%(slug)s.jpg"></a>
                    <h3>%(name)s</h3>
                    <ul>%(list)s</ul>
                </li>""" % locals()

    print >> index, """<ul>
</body>
</html>"""