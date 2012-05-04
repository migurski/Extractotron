#!/bin/bash -x

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

package_coast reykjavik 64.253544 -22.101746 64.028933 -21.618347
package_coast akureyri 65.7239 -18.195 65.6251 -17.986
package_coast isafjordur 66.0953 -23.237 66.0152 -23.085
package_coast hornafjordur 64.2695 -15.242 64.2391 -15.170
