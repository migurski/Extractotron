Extractotron
============

In one of my [SotM 2011](http://stateofthemap.org) talks, I suggested that OSM
should have regular extracts of metropolitan areas for major world cities and
their surrounding areas, regardless of state or country. This is a repository
for a bit of code to make that real. I’ve decided to use Amazon S3 to host files,
and EC2 to do the extracting. ```extract.sh``` is a script that performs the
actual work with [Osmosis](http://wiki.openstreetmap.org/wiki/Osmosis) and
terminates its host machine upon completion.

To use Extractotron yourself, put this brief shell script in your EC2 user-data:

    #!/bin/sh
    K=<your AWS access key>
    S=<your AWS access secret>
    B=<your bucket name>
    U=https://raw.github.com/migurski/Extractotron/master/extract.sh
    curl -s $U | KEY=$K SECRET=$S BUCKET=$B sh > /mnt/progress.txt 2>&1

Currently, the cities list is very short. Help me expand it by modifying
```cities.txt``` and sending a pull request via Github.