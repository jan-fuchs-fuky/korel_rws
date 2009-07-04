#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

import os
import sys
import time
import traceback

from subprocess import Popen, PIPE

KOREL_PID = "korel.pid"

def main():
    korel_stdout = open("stdout.txt", "w")
    korel_stderr = open("stderr.txt", "w")

    korel_pipe = Popen([korel_bin], stdin=PIPE, stdout=korel_stdout, stderr=korel_stderr, close_fds=True)

    fd = os.open(KOREL_PID, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
    os.write(fd, "%i\n" % korel_pipe.pid)
    os.close(fd)

    result = None
    while (result is None):
        result = korel_pipe.poll()
        time.sleep(1)

    korel_result = open("returncode.txt", "w")
    korel_result.write("%s\n" % result)
    korel_result.close()

if __name__ == '__main__':
    argc = len(sys.argv)

    if(argc != 2):
        print >>sys.stderr, "%s takes 2 argument (%i given)" % (sys.argv[0], argc)
        sys.exit(1)

    korel_bin = os.path.abspath("./bin/korel")
    korel_pwd = sys.argv[1]
    os.chdir(korel_pwd)

    try:
        main()
    except:
        exc_type, exc_value, exc_traceback = sys.exc_info()

        traceback_file = open("traceback", "w")
        traceback.print_tb(exc_traceback, file=traceback_file)
        traceback_file.write("%s: %s\n" % (exc_type, exc_value))
        traceback_file.close()

        sys.exit(1)
