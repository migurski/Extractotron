#!/bin/sh -x

# 
# This script expects to be run as the postgres user. It looks at the coastline
# error checker's output file, coast/processed_p.shp, and pushes it through
# PostGIS to find topology errors that might lead to rendering problems.
# Results are saved to /tmp/coastline-errors.json and /tmp/coastline-missing.json.
# 

createdb coast > postgis.txt 2>&1
createlang plpgsql coast >> postgis.txt 2>&1
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql coast >> postgis.txt 2>&1
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql coast >> postgis.txt 2>&1

shp2pgsql -dID -s 900913 coast/processed_p.shp coast | psql coast >> postgis.txt 2>&1
psql -c "DELETE FROM coast WHERE ST_IsValid(the_geom)" coast >> postgis.txt 2>&1

psql -tA -F ' ' -c "SELECT gid FROM coast ORDER BY gid" coast > /tmp/gids
psql -tA -F ' ' -c "SELECT gid, tile_x, tile_y FROM coast ORDER BY gid" coast > /tmp/tiles

rm -f /tmp/reasons
touch /tmp/reasons

for GID in `cat /tmp/gids`; do
    psql -tA -F ' ' -c "SELECT gid, ST_IsValidReason(the_geom) FROM coast WHERE gid=$GID" coast >> /tmp/reasons
done

#
# Creation of GeoJSON files is done in Python using the files found above.
#

python <<COMPILE

from re import compile
from json import dump

hole_pat = compile(r'(?P<reason>Holes are nested)\[(?P<x>\S+) (?P<y>\S+)\]')
ring_pat = compile(r'(?P<reason>Ring Self-intersection)\[(?P<x>\S+) (?P<y>\S+)\]')
self_pat = compile(r'(?P<reason>Self-intersection)\[(?P<x>\S+) (?P<y>\S+)\]')

tiles = [line.split() for line in open('/tmp/tiles')]
tiles = dict( [(gid, (int(x), int(y))) for (gid, x, y) in tiles] )

reasons = [line.split(' ', 1) for line in open('/tmp/reasons')]
reasons = dict( [(gid, text.strip()) for (gid, text) in reasons] )

features = []

for (gid, reason) in reasons.items():
    if hole_pat.match(reason):
        match = hole_pat.match(reason)
    elif ring_pat.match(reason):
        match = ring_pat.match(reason)
    elif self_pat.match(reason):
        match = self_pat.match(reason)
    else:
        continue

    reason, x, y = [match.group(key) for key in ('reason', 'x', 'y')]
    geometry = dict(type='Point', coordinates=(float(x), float(y)))
    
    feature = dict(type='Feature', geometry=geometry, properties=dict(reason=reason))
    features.append(feature)

dump(dict(type='FeatureCollection', features=features), open('/tmp/coastline-errors.json', 'w'))

#
# Coastline error checker constants borrowed from:
# http://svn.openstreetmap.org/applications/utils/coastcheck/closeshp.c
#
merc_max = 20037508.34
divisions = 400
merc_block = 2 * merc_max / divisions
tile_overlap = 150

features = []

for (gid, (x, y)) in tiles.items():
    if gid in reasons:
        continue

    # Also borrowed from closeshp.c:
    left   = -merc_max + (x * merc_block) - tile_overlap
    right  = -merc_max + ((x + 1) * merc_block) + tile_overlap
    bottom = -merc_max + (y * merc_block) - tile_overlap
    top    = -merc_max + ((y + 1) * merc_block) + tile_overlap
    
    reason = 'Bad geometry'
    geometry = dict(type='Polygon', coordinates=[[(left, top), (right, top), (right, bottom), (left, bottom), (left, top)]])
    
    feature = dict(type='Feature', geometry=geometry, properties=dict(reason=reason))
    features.append(feature)

dump(dict(type='FeatureCollection', features=features), open('/tmp/coastline-missing.json', 'w'))

COMPILE
