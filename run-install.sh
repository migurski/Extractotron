#!/bin/sh -ex
EXTRACTO_HOME=`dirname $0`

#
# Install the chef ruby gem if chef-solo is not in the path.
#
if [ ! `which chef-solo` ]; then
    apt-get install -y rubygems
    gem install chef ohai --no-rdoc --no-ri
fi

chef-solo -c $EXTRACTO_HOME/chef/solo.rb \
          -j $EXTRACTO_HOME/chef/role-ec2.json

PLANET='http://osm-extracted-metros.s3.amazonaws.com/sf-bay-area.osm.pbf'
WORKDIR=`python -c "import json; print json.load(open('${EXTRACTO_HOME}/chef/role-ec2.json'))['workdir']"`

$EXTRACTO_HOME/run-extract.py $PLANET $WORKDIR/history
