from sys import argv, stderr
from csv import DictReader

cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))

try:
    (coastshapes, ) = argv[1:]
except ValueError:
    print >> stderr, 'Usage: build-coastshapes-script.py <coastshapes command file>'
    exit(1)

coastshapes = open(coastshapes, 'w')

for city in cities:
    print >> coastshapes, 'ogr2ogr -spat %(left)s %(bottom)s %(right)s %(top)s -t_srs EPSG:900913 ex/merc/%(slug)s.shp ex/wgs84/processed_p.shp' % city
    print >> coastshapes, 'zip -j - ex/merc/%(slug)s.??? > ex/%(slug)s.shp.zip' % city
    print >> coastshapes, '' % city

coastshapes.close()
