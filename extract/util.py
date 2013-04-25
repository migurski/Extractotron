from os.path import join, dirname

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
