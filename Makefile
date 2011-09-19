all: osmosis.sh previews

osmosis.sh: cities.txt
	python build-osmosis-script.py $@

previews: cities.txt
	python compose-city-previews.py $@
	touch previews

clean:
	rm -f osmosis.sh
	rm -f previews/*.png
