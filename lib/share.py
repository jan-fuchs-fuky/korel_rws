#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

import os
import sys
import subprocess

def job_dir2user(job_dir):
    # /opt/korel_rws/jobs/USER/PID
    curdir = os.path.abspath(job_dir)
    return os.path.basename(curdir[:curdir.rfind("/")])

def daemonize():
    pid = os.fork()
    if (pid < 0):
        sys.exit(1)
    elif (pid > 0):
        # exit the parent process
        sys.exit(0)

    os.setsid()
    os.umask(0)

    pid = os.fork()
    if (pid < 0):
        sys.exit(1)
    elif (pid > 0):
        # exit the parent process
        sys.exit(0)
    
    stdin = open("/dev/null", "r")
    stdout = open("/dev/null", "a+")
    stderr = open("/dev/null", "a+", 0)

    os.dup2(stdin.fileno(), sys.stdin.fileno())
    os.dup2(stdout.fileno(), sys.stdout.fileno())
    os.dup2(stderr.fileno(), sys.stderr.fileno())

def create_pid(filename):
    if (os.path.isfile(filename)):
        pid_fo = open(filename, "r")
        old_pid = pid_fo.readline().strip()
        pid_fo.close()

        if (subprocess.call(["ps", "--pid", old_pid, "-o", "pid="]) != 0):
            os.remove(filename)

    try:
        fd = os.open(filename, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
        os.write(fd, "%i\n" % os.getpid())
        os.close(fd)
    except:
        sys.exit(1)
