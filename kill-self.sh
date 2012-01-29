#!/bin/sh -ex
# EC2 will tell us our own instance ID, use that to turn ourselves off.

python <<KILL

from urllib import urlopen
from boto.ec2 import EC2Connection

instance = urlopen('http://169.254.169.254/latest/meta-data/instance-id').read().strip()
EC2Connection('$KEY', '$SECRET').terminate_instances(instance)

KILL
