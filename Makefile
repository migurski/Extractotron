all: osmosis.sh index.html previews

osmosis.sh: cities.txt
	python build-osmosis-script.py $@

index.html: cities.txt
	python build-index.py $@

previews: cities.txt
	python compose-city-previews.py $@
	touch previews

clean:
	rm -f osmosis.sh
	rm -f previews/*.png
