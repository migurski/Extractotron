#!/usr/bin/env python

import math

# reference http://mathforum.org/library/drmath/view/63767.html
# this calculation assumes a spherical earth; PostGIS actually computes to a geoid
def area(lon1, lat1, lon2, lat2):
    "Spherical surface area of a rectangle on the earth defined by two lon/lat"
    R = 6371009   # http://en.wikipedia.org/wiki/Earth_radius#Mean_radii
    pi180 = math.pi / 180
    return math.fabs(
        pi180 * R * R *
        (math.sin(lat1 * pi180) - math.sin(lat2 * pi180)) *
        (lon1 - lon2))

import unittest

class AreaTest(unittest.TestCase):
    def test_area(self):
        "Test that our area function is within 1% of PostGIS calculated data"
        # Test data generated from PostGIS via genTestData() function
        regions = (
            [39.32, -121.3, 39.08, -120.88, 966677486.764507],
            [38.719, -123.64, 36.791, -121.025, 49309815560.8189],
            [21.781, -158.35, 21.192, -157.592, 5122832568.11863],
            [32.217, 105.283, 28.167, 110.183, 211840838842.826],
            [64.297, -22.826, 63.771, -21.14, 4831125559.89793],
            [36.41, 174.223, -37.348, 175.314, 927653084360.464],
            [1.823, 103.062, 0.807, 104.545, 18541433392.8946])
        for lat1, lon1, lat2, lon2, correctArea in regions:
            m2 = area(lon1, lat1, lon2, lat2)
            self.assertAlmostEqual(correctArea, m2, delta=correctArea/100);

# This function is only needed to regenerate test data
def genTestData():
    "Generate some test cases from PostGIS, to test our area function"
    import psycopg2
    conn = psycopg2.connect('dbname=nelson')
    cur = conn.cursor()

    def areaFromPostGis(lon1, lat1, lon2, lat2):
        cur.execute("""
          select ST_Area(
                   ST_GeographyFromText('POLYGON ((%(lon1)s %(lat1)s,
                                                   %(lon2)s %(lat1)s,
                                                   %(lon2)s %(lat2)s,
                                                   %(lon1)s %(lat2)s,
                                                   %(lon1)s %(lat1)s))'
                 ));
        """, locals())
        return cur.fetchone()[0]

    # Various regions taken from cities.txt
    regions = (
        [39.32, -121.30, 39.08, -120.88],
        [38.719, -123.640, 36.791, -121.025],
        [21.781, -158.35, 21.192, -157.592],
        [32.217, 105.283, 28.167, 110.183],
        [64.297, -22.826, 63.771, -21.140],
        [36.410, 174.223, -37.348, 175.314],
        [1.823, 103.062, 0.807, 104.545],
    )
    for region in regions:
        (lat1, lon1, lat2, lon2) = region
        m2 = areaFromPostGis(lon1, lat1, lon2, lat2)
        region.append(m2)
        print "%r," % (region,)
