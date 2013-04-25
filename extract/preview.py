from os.path import basename
import logging

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

def render_preview(image_path, north, west, south, east):
    ''' Render a city preview to a file path.
    '''
    logging.info('Rendering %s' % basename(image_path))

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
    
    img.save(image_path, quality=95)
