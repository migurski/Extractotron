from sys import argv, stderr
from itertools import groupby
from csv import DictReader

group = lambda city: city['group']
cities = sorted(DictReader(open('cities.txt'), dialect='excel-tab'), key=group)

try:
    (osmosis, ) = argv[1:]
except ValueError:
    print >> stderr, 'Usage: build-osmosis-script.py <osmosis command file>'
    exit(1)

osmosis = open(osmosis, 'w')

lines = []
groups = 0

for (group, cities) in groupby(cities, group):
    cities = list(cities)
    
    xs = [float(city['left']) for city in cities] + [float(city['right']) for city in cities]
    ys = [float(city['bottom']) for city in cities] + [float(city['top']) for city in cities]
    
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    assert (xmin < xmax and ymin < ymax)
    
    lines.append('  --bb top=%(ymax).3f left=%(xmin).3f bottom=%(ymin).3f right=%(xmax).3f' % locals())
    lines.append('  --b --tee outputCount=%d' % len(cities))
    
    for city in cities:
        xmin, xmax = min(float(city['left']), float(city['right'])), max(float(city['left']), float(city['right']))
        ymin, ymax = min(float(city['bottom']), float(city['top'])), max(float(city['bottom']), float(city['top']))
        assert (xmin < xmax and ymin < ymax)

        lines.append('    --bb top=%(ymax).3f left=%(xmin).3f bottom=%(ymin).3f right=%(xmax).3f' % locals())
        lines.append('    --tee outputCount=2 --wx file=ex/%(slug)s.osm.bz2 --wb file=ex/%(slug)s.osm.pbf' % city)
    
    groups += 1

lines.insert(0, 'bzcat planet-latest.osm.bz2 | bin/osmosis --rx file=-')
lines.insert(1, '--log-progress interval=60')
lines.insert(2, '--tee outputCount=%d' % groups)

osmosis.write(' \\\n'.join(lines) + ';\n')
osmosis.close()
