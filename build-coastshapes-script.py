from sys import argv, stderr
from csv import DictReader

cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))

try:
    (coastshapes, ) = argv[1:]
except ValueError:
    print >> stderr, 'Usage: build-coastshapes-script.py <coastshapes command file>'
    exit(1)

coastshapes = open(coastshapes, 'w')

print >> coastshapes, """#!/bin/bash -x

function package_coast
{
    slug=$1
    top=$2
    left=$3
    bottom=$4
    right=$5
    
    ogr2ogr -spat $left $bottom $right $top -t_srs EPSG:900913 ex/merc/$slug.shp ex/wgs84/processed_p.shp
    zip -j - ex/merc/$slug.??? > ex/$slug.shp.zip
    cp ex/$slug.shp.zip ex/$slug.coastline.zip
}
"""

for city in cities:
    print >> coastshapes, 'package_coast %(slug)s %(top)s %(left)s %(bottom)s %(right)s' % city

coastshapes.close()
