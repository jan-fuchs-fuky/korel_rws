#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

import os
import sys
from subprocess import Popen, call, PIPE
from lxml import etree
 
KOREL_USERS_PATH = "./etc/users"
KOREL_JOBS_PATH = "./jobs"
XMLNS = """
    xsi:schemaLocation="http://www.ivoa.net/xml/UWS/UWS-v1.0.xsd"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
"""

parser = etree.XMLParser(remove_blank_text=True)
settings = {}

def bytes2human(size):
    size = int(size)
    if (size < 1024):
        return "%iB" % size
    elif (size < 1024*1024):
        return "%.1fKB" % (size / 1024.0)
    else:
        return "%.1fMB" % (size / (1024.0*1024.0))

def disk_usage(user):
    dir = "%s/%s" % (KOREL_JOBS_PATH, user)
    pipe = Popen(["du", "-s", "-b", dir], stdin=PIPE, stdout=PIPE, stderr=PIPE, close_fds=True)
    return int(pipe.stdout.readline().strip().split()[0])

def get_user_settings(user_xml_path):
    user_elts = etree.parse(user_xml_path, parser).xpath('/user')[0]
    settings = {"attrib": user_elts.attrib}

    for element in user_elts.getchildren():
        value = element.text.strip()
        # TODO: datovy typ ukladat jako atribut primo v XML
        if (element.tag[:4] == "max_"):
            value = int(value)
        settings.update({element.tag: value})

    return settings

def load_user_settings():
    user_settings = {}
    for user_xml in os.listdir(KOREL_USERS_PATH):
        user_xml_path = "%s/%s" % (KOREL_USERS_PATH, user_xml)
        if (user_xml[-4:] != ".xml") or (not os.path.isfile(user_xml_path)):
            continue

        user = user_xml[:-4]
        user_settings.update({user: get_user_settings(user_xml_path)})

def refresh_user_settings(user, user_settings_mtime):
    user_xml_path = "%s/%s.xml" % (KOREL_USERS_PATH, user)

    if (os.stat(user_xml_path).st_mtime > user_settings_mtime):
        return get_user_settings(user_xml_path)

    return {}

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

        if (call(["ps", "--pid", old_pid, "-o", "pid="]) != 0):
            os.remove(filename)

    try:
        fd = os.open(filename, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
        os.write(fd, "%i\n" % os.getpid())
        os.close(fd)
    except:
        sys.exit(1)

def make_message(title, text, type="", username=""):
    error = []
    error.append("<message>")
    error.append("<ownerId>%s</ownerId>" % username)
    error.append("<title>%s</title>" % title)
    error.append("<text>%s</text>" % text)
    error.append("<type>%s</type>" % type)
    error.append("</message>")

    return "\n".join(error)
