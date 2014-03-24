#!/usr/bin/python

import errno
import fcntl
import os
import random
import re
import signal
import socket
import sys
import threading
import time


def daemonize():
    """Performs the necessary dance to become a background daemon."""
    if os.fork():
        os._exit(0)
    os.chdir("/")
    os.umask(022)
    os.setsid()
    os.umask(0)
    if os.fork():
        os._exit(0)
    stdin = open(os.devnull)
    stdout = open(os.devnull, 'w')
    os.dup2(stdin.fileno(), 0)
    os.dup2(stdout.fileno(), 1)
    os.dup2(stdout.fileno(), 2)
    stdin.close()
    stdout.close()
    for fd in xrange(3, 1024):
        try:
            os.close(fd)
        except OSError:  # This FD wasn't opened...
            pass         # ... ignore the exception.


def _parse_args(args):
    dargs = {
        'Version':3,
        'DestHost':'localhost',
        'Community':'public',
        'Timeout':1000000,
        'Retries':3,
        'RemotePort':161,
        'LocalPort':0
        }
    keys = args.keys()
    for key in keys:
        if dargs.has_key(key):
            dargs[key] = args[key]
        else:
            print >>stderr, "ERROR: unknown key", key
    return dargs

if __name__ == '__main__':
    daemonize()
