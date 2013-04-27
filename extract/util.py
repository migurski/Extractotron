from os.path import join, dirname
from subprocess import Popen as _Popen

def relative(absolute_path, filename):
    ''' Return a new absolute path for a file in the same directory as another.
    
        E.g. relative('/etc/foo', 'bar') --> '/etc/bar'
    '''
    return join(dirname(absolute_path), filename)

def open_logs(name_base):
    ''' Open a pair of logfiles and return a dictionary for subprocess.Popen().
    '''
    return dict(stdout = open(name_base + '.out', 'w'), 
                stderr = open(name_base + '.err', 'w'))

def Popen(command, stderr=None, **kwargs):
    ''' Run subprocess.Popen(), after writing a copy of the command to stderr.
    '''
    if stderr is not None:
        print >> stderr, '####', ' '.join(command)

    return _Popen(command, stderr=stderr, **kwargs)
