#!/bin/sh
EXTRACTO_HOME=`dirname $0`

#
# Install the chef rub gem if chef-solo is not in the path.
#
if [ ! `which chef-solo` ]; then
    apt-get install -y rubygems
    gem install chef ohai --no-rdoc --no-ri
fi

chef-solo -c $EXTRACTO_HOME/chef/chefsoloconfig.rb \
          -j $EXTRACTO_HOME/chef/role-ec2.json
