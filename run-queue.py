#!/usr/bin/env python
from datetime import datetime

with open('/tmp/ran-queue', 'w') as out:
    print >> out, datetime.now()
