#!/bin/sh -ex
BASE='/usr/local/extractotron'

apt-get update -y
apt-get upgrade -y
apt-get install -y git

# git clone $BASE

ROLE="$BASE/chef/role-ec2.json"
WORKDIR=`python -c "import json; print json.load(open('$ROLE'))['workdir']"`
PLANET=`python -c "import json; print json.load(open('$ROLE'))['planet']"`

$BASE/run-install.sh

$BASE/run-extract.py $PLANET $WORKDIR/history
