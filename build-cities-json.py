#!/usr/bin/env python

"""Generate a JSON database of all the metros in the extract.
Derived from cities.txt and other sources, generates a JSON file
which can be used to render a map, etc."""

import csv, json, sys

# Database we'll eventually dump as JSON
db = []

# Load all the rows in cities.txt into the database
with open("cities.txt") as fp:
    csvReader = csv.DictReader(fp, dialect='excel-tab');
    for row in csvReader:
        dbRow = {}
        dbRow["t"] = float(row["top"])
        dbRow["l"] = float(row["left"])
        dbRow["r"] = float(row["right"])
        dbRow["b"] = float(row["bottom"])
        dbRow["slug"] = row["slug"]
        dbRow["name"] = row["name"]
        db.append(dbRow)

# Write the database to named file
with open(sys.argv[1], "w") as fp:
    json.dump(db, fp, indent=2)
