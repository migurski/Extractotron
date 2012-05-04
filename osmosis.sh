bunzip2 -c iceland.osm.bz2 | osmosis-*/bin/osmosis --rx file=- \
    --log-progress interval=60 \
    --tee outputCount=4 \
    \
    --bb top=64.254 left=-22.102 bottom=64.029 right=-21.618 \
        --tee outputCount=2 --wx file=ex/reykjavik.osm.bz2 --wb file=ex/reykjavik.osm.pbf \
    --bb top=65.724 left=-18.195 bottom=65.625 right=-17.986 \
        --tee outputCount=2 --wx file=ex/akureyri.osm.bz2 --wb file=ex/akureyri.osm.pbf \
    --bb top=66.095 left=-23.237 bottom=66.015 right=-23.085 \
        --tee outputCount=2 --wx file=ex/isafjordur.osm.bz2 --wb file=ex/isafjordur.osm.pbf \
    --bb top=64.269 left=-15.242 bottom=64.239 right=-15.170 \
        --tee outputCount=2 --wx file=ex/hornafjordur.osm.bz2 --wb file=ex/hornafjordur.osm.pbf \
;
