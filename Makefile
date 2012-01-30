all: osmosis.sh osm2pgsql.sh coastshapes.sh index.html previews

osmosis.sh: cities.txt
	python build-osmosis-script.py $@

osm2pgsql.sh: cities.txt
	python build-osm2pgsql-script.py $@

coastshapes.sh: cities.txt
	python build-coastshapes-script.py $@

index.html: cities.txt
	python build-index.py $@

previews: cities.txt
	python compose-city-previews.py $@
	touch previews
