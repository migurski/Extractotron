#!/usr/bin/env python
from os.path import join, dirname
from fcntl import lockf, LOCK_UN, LOCK_EX, LOCK_SH, LOCK_NB
from csv import reader, writer
from subprocess import Popen
from time import sleep, time
from json import load

from pika import BlockingConnection, ConnectionParameters

class LockedID:
    '''
    '''
    def __init__(self, path, id):
        self.file = None
        self.path = path
        self.id = id
    
    def __enter__(self):
        self.file = open(self.path, 'a+')
        lockf(self.file, LOCK_EX|LOCK_NB)
        self.file.truncate()
        self.file.write(self.id)
        self.file.flush()
        return self.file
    
    def __exit__(self, type, value, traceback):
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
    
    channel = setup_channel()
    
    while time() < due:
        #
        # Pop a new task from the queue, which stores only task id's.
        #
        method, properties, task_id = channel.basic_get(queue='testing-py')
        
        if task_id is None:
            sleep(1)
            continue
        
        task_name = None
        
        with open('/var/run/extractotron/tasks.csv') as tasks:
            lockf(tasks, LOCK_SH)

            #
            # Find a task that matches the task id from the queue.
            #
            for row in reader(tasks):
                if row[0] == task_id:
                    task_name = row[1]

            lockf(tasks, LOCK_UN)
        
        if task_name == 'extract':
            with LockedID('/var/run/extractotron/lock', task_id) as lock, \
                 open('/tmp/stderr.log', 'w') as stderr, \
                 open('/tmp/stdout.log', 'w') as stdout:
                #
                # Perform the actual planet extract, wait for it to finish.
                #
                extract = join(dirname(__file__), 'run-extract.py')
                extract = Popen([extract, planet, join(workdir, 'history')], stderr=stderr, stdout=stdout)
                extract.wait()
        
                lock.seek(0)
                lock.truncate()
            
            if hasattr(method, 'delivery_tag'):
                #
                # Acknowledge delivery tag to the queue so no one sees this task again.
                #
                channel.basic_ack(delivery_tag=method.delivery_tag)
        
            with open('/var/run/extractotron/tasks.csv', 'r+') as tasks:
                lockf(tasks, LOCK_EX)

                #
                # Remove all planet-wide extracts since we've just done one.
                #
                rows = [row for row in list(reader(tasks))
                        if row[0] != task_id and row[1] != 'extract']

                #
                # Rewrite tasks list with just the remaining rows.
                #
                tasks.seek(0)
                tasks.truncate()
                out = writer(tasks)
                
                for row in rows:
                    out.writerow(row)
                
                lockf(tasks, LOCK_UN)
            
        else:
            print '?', body
