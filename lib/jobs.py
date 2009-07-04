""" Jobs """

import os
import time

from cherrypy.lib.static import serve_file
from StringIO import StringIO
from subprocess import Popen, PIPE

import template

JOBS_PATH = "./jobs"

def save_upload_file(input, output):
    file = open(output, "w")
    while (1):
        data = input.file.read(1024*8)
        if (not data):
            break
        file.write(data)
    file.close()

def get_job_dir(username, id):
    job_dir = "%s/%s/%s" % (JOBS_PATH, username, id)

    if (os.path.isdir(job_dir)):
        return job_dir

    raise Exception("Job directory '%s' does not exist" % job_dir)

def start(username, korel_dat, korel_par):
    id = 0

    # TODO: zjistit zda-li lze do adresare zapisovat

    while (1):
        job_dir = "%s/%s/%i" % (JOBS_PATH, username, id)

        if (os.path.isdir(job_dir)):
            id += 1
        else:
            # creating a directory is atomic
            try:
                os.mkdir(job_dir)
                break
            except:
                id += 1
                continue

    if (korel_dat is not None) and (korel_par is not None):
        save_upload_file(korel_dat, "%s/korel.dat" % job_dir)
        save_upload_file(korel_par, "%s/korel.par" % job_dir)

    Popen("nohup ./bin/korel.py %s &" % job_dir, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE, close_fds=True)
    
    return "%i" % id

def cancel(username, id):
    job_dir = get_job_dir(username, id)

    return "Cancel job"

def list(username):
    result = "<jobslist>\n"
    result += "<user>%s</user>\n" % username

    root, dirs, files = os.walk("%s/%s" % (JOBS_PATH, username)).next()
    for dir in dirs:
        returncode = "%s/%s/returncode.txt" % (root, dir)
        if (os.path.isfile(returncode)):
            state = "success"
        else:
            state = "running"

        result += "<job>\n"
        result += "<id>%s</id>\n" % dir
        result += "<state>%s</state>\n" % state
        result += "</job>\n"

    result += "</jobslist>\n"
    return template.xml2html(StringIO(result))

def results(username):
    return "Results"

def result_id(username, id):
    job_dir = get_job_dir(username, id)
    result = "<result>\n"
    result += "<user>%s</user>\n" % username
    result += "<id>%s</id>\n" % id

    root, dirs, files = os.walk(job_dir).next()
    for file in files:
        result += "<link>%s</link>\n" % file

    result += "</result>\n"

    return template.xml2html(StringIO(result))

def download(username, id, file):
    job_dir = get_job_dir(username, id)
    file_path = os.path.abspath("%s/%s" % (job_dir, file))

    if (os.path.isfile(file_path)):
        return serve_file(file_path)
    else:
        return "File '%s' not found" % file_path

def phase(username, id):
    job_dir = get_job_dir(username, id)

    return "Result-ID %s" % id
