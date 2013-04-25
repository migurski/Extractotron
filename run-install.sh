#!/bin/sh -ex
#
# Install the chef ruby gem if chef-solo is not in the path.
# This script is safe to run multiple times.
#
if [ ! `which chef-solo` ]; then
    apt-get install -y rubygems
    gem install chef ohai --no-rdoc --no-ri
fi

BASE=`dirname $0`

chef-solo -c $BASE/chef/solo.rb \
          -j $BASE/chef/role-ec2.json
