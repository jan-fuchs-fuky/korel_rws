""" Jobs """

import os
import time
import signal

from cherrypy.lib.static import serve_file
from StringIO import StringIO
from subprocess import Popen, PIPE, call

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

def make_id_jobdir(username):
    id = 1

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

    return [id, job_dir]

def start_korel(job_dir):
    Popen("nohup ./bin/korel.py %s &" % job_dir, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE, close_fds=True)

def start(username, korel_dat, korel_par):
    if (korel_dat.filename == "") or (korel_par.filename == ""):
        result = "<start><id>-1</id></start>"
        return template.xml2html(StringIO(result))

    id, job_dir = make_id_jobdir(username)

    result = "<start><id>%i</id></start>" % id
    save_upload_file(korel_dat, "%s/korel.dat" % job_dir)
    save_upload_file(korel_par, "%s/korel.par" % job_dir)

    start_korel(job_dir)

    return template.xml2html(StringIO(result))

def again(username, id):
    job_dir = get_job_dir(username, id)
    korel_dat = "%s/korel.dat" % job_dir
    korel_par = "%s/korel.par" % job_dir

    new_id, new_job_dir = make_id_jobdir(username)

    if (call(["cp", korel_dat, new_job_dir]) != 0):
        raise Exception("Copy korel.dat failure")

    file = open(korel_par, "r")
    korel_par_buffer = file.read()
    file.close()

    result = "<again>"
    result += "<id>%s</id>" % id
    result += "<new_id>%s</new_id>" % new_id
    result += "<korel_par><![CDATA[%s]]></korel_par>" % korel_par_buffer
    result += "</again>"

    return template.xml2html(StringIO(result))

def againstart(username, id, korel_par):
    job_dir = get_job_dir(username, id)
    result = "<start><id>%s</id></start>" % id

    file = open("%s/korel.par" % job_dir, "w")
    file.write(korel_par)
    file.close()

    start_korel(job_dir)

    return template.xml2html(StringIO(result))

def cancel(username, id):
    job_dir = get_job_dir(username, id)

    file = open("%s/korel.pid" % job_dir, "r")
    pid = int(file.read().strip())
    file.close()

    kill(pid)

    result = "<body><![CDATA["
    result += "<h2>Cancel job</h2>"
    result += "Job %s user %s canceled." % (id, username)
    result += "]]></body>"

    return template.xml2html(StringIO(result))

def kill(pid):
    try:
        os.kill(pid, signal.SIGTERM)

        i = 0
        while (call("ps -p %i -o pid=" % pid, shell=True) != 0):
            i += 1
            if (i > 5):
                os.kill(pid, signal.SIGKILL)
                break
            time.sleep(1)
    except OSError:
        pass

def remove(username, id):
    job_dir = get_job_dir(username, id)

    try:
        file = open("%s/korel.pid" % job_dir, "r")
        pid = int(file.read().strip())
        file.close()

        kill(pid)
    except:
        pass

    call(["rm", "-rf", job_dir])

    result = "<body><![CDATA["
    result += "<h2>Remove job</h2>"
    result += "Job %s user %s removed." % (id, username)
    result += "]]></body>"

    return template.xml2html(StringIO(result))

def list(username):
    result = "<jobslist>\n"
    result += "<user>%s</user>\n" % username

    root, dirs, files = os.walk("%s/%s" % (JOBS_PATH, username)).next()
    for dir in dirs:
        # skip hidden directory
        if (dir[0] == "."):
            continue

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
    returncode = "%s/returncode.txt" % job_dir

    if (os.path.isfile(returncode)):
        file = open(returncode, "r")
        rc = int(file.read().strip())
        file.close()

        if (rc == 0):
            phase = "finished"
        else:
            phase = "failure"
    else:
        phase = "working"

    result = "<result>\n"
    result += "<user>%s</user>\n" % username
    result += "<id>%s</id>\n" % id
    result += "<phase>%s</phase>\n" % phase

    if (phase != "working"):
        root, dirs, files = os.walk(job_dir).next()
        for file in files:
            # skip hidden file
            if (file[0] == "."):
                continue

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
