Extractotron
============

In one of my [SotM 2011](http://stateofthemap.org) talks, I suggested that OSM
should have regular extracts of metropolitan areas for major world cities and
their surrounding areas, regardless of state or country. This is a repository
for a bit of code to make that real. I’ve decided to use Amazon S3 to host files,
and EC2 to do the extracting. ```extract.sh``` is a script that performs the
actual work with [Osmosis](http://wiki.openstreetmap.org/wiki/Osmosis) and
terminates its host machine upon completion.

To use Extractotron yourself, use run-instance.py:

    python run-instance.py <your AWS access key> <your AWS secret> <your bucket name>
    
By default, run-instance.py instantiates an m1.large instance with Alestic's
Ubuntu 11.04 Natty instance-store AMI ami-68ad5201. You can change the instance
type or AMI, see ```python run-instance.py --help``` for details.

Currently, the cities list is very short. Help me expand it by modifying
```cities.txt``` and sending a pull request via Github.