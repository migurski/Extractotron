#!/bin/sh -ex
#
# Bootstrap.sh installs Extractotron on an unconfigured system, and includes
# a fresh git checkout step. This script is intended to be run exactly once,
# and will fail at the next step if run repeatedly.
#
apt-get update -y
apt-get upgrade -y
apt-get install -y git

#
# Clone Extractotron from Github, then run Chef to complete install.
#
git clone -b lmco-2013 git://github.com/migurski/Extractotron.git /usr/local/extractotron

/usr/local/extractotron/run-install.sh

#
# Actually run the actual thing.
#
/usr/local/extractotron/run-extract.py
