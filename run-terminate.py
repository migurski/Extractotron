#!/usr/bin/env python
from boto import connect_ec2
from urllib import urlopen

if __name__ == '__main__':
    
    ec2 = connect_ec2()
    iid = urlopen('http://169.254.169.254/latest/meta-data/instance-id').read().strip()
    
    ec2.terminate_instances(iid)