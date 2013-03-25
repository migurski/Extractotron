all: osmosis.sh osm2pgsql.sh coastshapes.sh index.html previews cities.json

osmosis.sh: build-osmosis-script.py cities.txt
	python build-osmosis-script.py $@

osm2pgsql.sh: build-osm2pgsql-script.py cities.txt
	python build-osm2pgsql-script.py $@

coastshapes.sh: build-coastshapes-script.py cities.txt
	python build-coastshapes-script.py $@

index.html: build-index.py cities.txt
	python build-index.py $@

previews: compose-city-previews.py cities.txt
	python compose-city-previews.py $@
	touch previews

cities.json: build-cities-json.py cities.txt
	python build-cities-json.py $@
