#!/usr/bin/env python
from os.path import join, dirname
from fcntl import lockf, LOCK_UN, LOCK_EX, LOCK_NB
from subprocess import Popen
from time import sleep, time
from json import load

from pika import BlockingConnection, ConnectionParameters

class Locked:
    
    def __init__(self, path, id):
        self.file = None
        self.path = path
        self.id = id
    
    def __enter__(self):
        print 'opening and locking', self.path

        self.file = open(self.path, 'a+')
        lockf(self.file, LOCK_EX|LOCK_NB)
        
        self.file.truncate()
        self.file.write(self.id)
        self.file.flush()

        return self.file
    
    def __exit__(self, type, value, traceback):
        print (type, value, traceback)
        print 'unlocking and closing', self.path

        self.file.truncate()
        lockf(self.file, LOCK_UN)
        self.file.close()

        self.file = None

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
        
        if body is None:
            sleep(1)
            continue
        
        if body.endswith(' extract'):
            id, task = body.split()
        
            with Locked('/var/run/extractotron/lock', id) as lock:
                with open('/tmp/stderr.log', 'w') as stderr, open('/tmp/stdout.log', 'w') as stdout:
                    extract = join(dirname(__file__), 'run-extract.py')
                    extract = Popen([extract, planet, join(workdir, 'history')], stderr=stderr, stdout=stdout)
                    extract.wait()
            
            if hasattr(method, 'delivery_tag'):
                channel.basic_ack(delivery_tag=method.delivery_tag)
        
        else:
            print '?', body
