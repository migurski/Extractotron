from sys import argv, stderr
from csv import DictReader

cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))

try:
    (osmosis, ) = argv[1:]
except ValueError:
    print >> stderr, 'Usage: build-osmosis-script.py <osmosis command file>'
    exit(1)

osmosis = open(osmosis, 'w')

print >> osmosis, 'bunzip2 -c planet-latest.osm.bz2 | osmosis-*/bin/osmosis --rx file=- \\'
print >> osmosis, '    --log-progress interval=60 \\'
#print >> osmosis, '    --tee outputCount=2 \\'
#print >> osmosis, '    --tag-filter accept-ways natural=coastline --used-node \\'
#print >> osmosis, '    --wx coastline.osm.bz2 \\'
print >> osmosis, '    --tee outputCount=%d \\' % len(cities)
print >> osmosis, '    \\'

for city in cities:
    xmin, xmax = min(float(city['left']), float(city['right'])), max(float(city['left']), float(city['right']))
    ymin, ymax = min(float(city['bottom']), float(city['top'])), max(float(city['bottom']), float(city['top']))
    print >> osmosis, '    --bb top=%(ymax).3f left=%(xmin).3f bottom=%(ymin).3f right=%(xmax).3f \\' % locals()
    print >> osmosis, '        --tee outputCount=2 --wx file=ex/%(slug)s.osm.bz2 --wb file=ex/%(slug)s.osm.pbf \\' % city

print >> osmosis, ';'

osmosis.close()
