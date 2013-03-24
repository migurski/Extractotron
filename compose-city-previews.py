from sys import argv, stderr
from csv import DictReader

try:
    from PIL import Image
    from PIL.ImageDraw import ImageDraw
except ImportError:
    import Image
    from ImageDraw import ImageDraw

from ModestMaps import mapByExtent
from ModestMaps.Providers import TemplatedMercatorProvider
from ModestMaps.Geo import Location
from ModestMaps.Core import Point

provider = TemplatedMercatorProvider('http://otile1.mqcdn.com/tiles/1.0.0/osm/{Z}/{X}/{Y}.jpg')
dimensions = Point(310, 200)

cities = list(DictReader(open('cities.txt'), dialect='excel-tab'))

try:
    previews, wanted = argv[1], argv[2:]
except ValueError:
    print >> stderr, 'Usage: compose-city-previews.py <previews directory>'
    exit(1)

for city in cities:
    if not city['name']:
        raise Exception('Need a name for ' + str(city))

    if wanted and city['slug'] not in wanted:
        continue

    print >> stderr, city['name'], '...',

    north, west = float(city['top']), float(city['left'])
    south, east = float(city['bottom']), float(city['right'])

    mmap = mapByExtent(provider, Location(north, west), Location(south, east), dimensions)
    
    ul = mmap.locationPoint(Location(north, west))
    lr = mmap.locationPoint(Location(south, east))
    bbox = [(p.x, p.y) for p in (ul, lr)]

    img = mmap.draw()

    mask = Image.new('L', img.size, 0x99)
    ImageDraw(mask).rectangle(bbox, fill=0x00)
    img.paste((0xFF, 0xFF, 0xFF), (0, 0), mask)
    
    frame = Image.new('L', img.size, 0x00)
    ImageDraw(frame).rectangle(bbox, outline=0x33)
    img.paste((0x00, 0x00, 0x00), (0, 0), frame)
    
    img.save('%s/%s.jpg' % (previews, city['slug']), quality=95)

    print >> stderr, '%s/%s.jpg' % (previews, city['slug'])
