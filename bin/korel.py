#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

import os
import sys
import time
import traceback
import tempfile
from subprocess import Popen, PIPE, call

script_path = os.path.dirname(os.path.realpath(os.path.abspath(sys.argv[0])))
sys.path.append(os.path.abspath("%s/../lib" % script_path))

import share
from mail import send_mail

KOREL_QUEUE_PATH = "../../../var/queue"
KOREL_PID = "korel.pid"

def append_to_queue():
    user = share.job_dir2user(os.curdir)
    queue_path = tempfile.mktemp(prefix="%s_" % user, dir=KOREL_QUEUE_PATH)

    fo = open(queue_path, "w")
    fo.write("%s\n" % os.path.abspath(os.curdir))
    fo.close()

# TODO: omezit cas cekani
def wait_on_run():
    while (1):
        if (os.path.isfile("grant")):
            break
        time.sleep(0.1)

def main():
    append_to_queue()
    wait_on_run()

    korel_stdout = open("stdout.txt", "w")
    korel_stderr = open("stderr.txt", "w")

    korel_pipe = Popen([korel_bin], stdin=PIPE, stdout=korel_stdout, stderr=korel_stderr, close_fds=True)

    fd = os.open(KOREL_PID, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
    os.write(fd, "%i\n" % korel_pipe.pid)
    os.close(fd)

    fo = open(".startTime", "w")
    fo.write("%i\n" % time.time())
    fo.close()

    result = None
    while (result is None):
        result = korel_pipe.poll()
        time.sleep(1)

    fo = open(".endTime", "w")
    fo.write("%i\n" % time.time())
    fo.close()

    if (result == 0):
        if (os.path.isfile("phg.ps")):
            call("sed -i '/end/d' phg.ps", shell=True)
            call("convert phg.ps phg.png", shell=True)

        if (os.path.isfile("korel.res")):
            call(["%s/plotsp.sh" % os.path.dirname(korel_bin), "korel.res"])

    korel_result = open("returncode.txt", "w")
    korel_result.write("%s\n" % result)
    korel_result.close()

    pid = os.path.basename(korel_pwd)
    result_tgz = "../%s.tgz" % pid
    call(["tar", "zcf", result_tgz, "../%s" % pid])

    if (os.path.isfile(".mailing")):
        fo = open(".mailing", "r")
        email_to = fo.read(1024).strip()
        fo.close()

        body = "Result od job %s" % pid
        send_mail(email_to, "Korel RESTful Web Service: Result od job %s" % pid, body, attachments=[result_tgz])

if __name__ == '__main__':
    argc = len(sys.argv)

    if(argc != 2):
        print >>sys.stderr, "%s takes 2 argument (%i given)" % (sys.argv[0], argc)
        sys.exit(1)

    proc_fd = "/proc/%i/fd" % os.getpid()
    fd_list = os.listdir(proc_fd)
    for fd in fd_list:
        fd = int(fd)
        fd_path = "%s/%i" % (proc_fd, fd)
        if (os.path.islink(fd_path)):
            name = os.readlink(fd_path)
            if (name.find("socket") != -1):
                os.close(fd)

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
