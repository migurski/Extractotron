all: index.html

index.html: build-index.py lib.py cities.txt
	python build-index.py $@

test: lib.py
	python -m unittest lib
