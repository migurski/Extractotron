#!/usr/bin/env python
from os.path import join, dirname
from subprocess import Popen
from time import sleep, time
from json import load

from pika import BlockingConnection, ConnectionParameters

def setup_channel():
    '''
    '''
    conn = BlockingConnection(ConnectionParameters('localhost'))
    chan = conn.channel()
    
    chan.exchange_declare(exchange='exchangotron', durable=True, type='fanout')
    chan.queue_declare(queue='testing-py', durable=True)
    
    return chan

if __name__ == '__main__':

    due = time() + 55
    
    role_path = join(dirname(__file__), 'chef/role-ec2.json')
    
    with open(role_path) as role_file:
        role = load(role_file)
        planet = role['planet']
        workdir = role['workdir']
    
    print role
    print planet
    print workdir
    
    channel = setup_channel()
    
    while time() < due:
        method, properties, body = channel.basic_get(queue='testing-py')
        
        print method
        print properties
        print body
        
        if body == 'extract':
            extract = join(dirname(__file__), 'run-extract.py')
            extract = Popen([extract, planet, join(workdir, 'history')])
            extract.wait()
        
        if hasattr(method, 'delivery_tag'):
            channel.basic_ack(delivery_tag=method.delivery_tag)

        sleep(1)
