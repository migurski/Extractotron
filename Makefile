all: osmosis.sh coastshapes.sh index.html previews

osmosis.sh: cities.txt
	python build-osmosis-script.py $@

coastshapes.sh: cities.txt
	python build-coastshapes-script.py $@

index.html: cities.txt
	python build-index.py $@

previews: cities.txt
	python compose-city-previews.py $@
	touch previews

clean:
	rm -f osmosis.sh
	rm -f coastshapes.sh
	rm -f previews/*.jpg
