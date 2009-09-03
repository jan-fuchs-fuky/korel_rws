""" Jobs """

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

import os
import time
import signal
import cherrypy

from cherrypy.lib.static import serve_file
from StringIO import StringIO
from subprocess import Popen, PIPE, call

import template

JOBS_PATH = "./jobs"

def is_valid_xml_char(char):
    """ http://www.w3.org/TR/2004/REC-xml-20040204/#charsets """

    value = ord(char)

    if (value == 0x9):
        return True
    elif (value == 0xA):
        return True
    elif (value == 0xD):
        return True
    elif ((value >= 0x20) and (value <= 0xD7FF)):
        return True
    elif ((value >= 0xE000) and (value <= 0xFFFD)):
        return True
    elif ((value >= 0x10000) and (value <= 0x10FFFF)):
        return True

    return False

def remove_invalid_xml_char(buffer):
    chars = []
    for char in buffer:
        if (is_valid_xml_char(char)):
            chars.append(char)

    return "%s\n" % "".join(chars).strip()

def save_upload_file(input, output, xml=False):
    file = open(output, "w")

    while (1):
        data = input.file.read(1024*8)
        if (not data):
            break

        if (xml):
            file.write(remove_invalid_xml_char(data))
        else:
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
        result = "<body><![CDATA["
        result += "<h2>Start new job</h2>"
        result += "Failure. Must upload files korel.dat and korel.par."
        result += "]]></body>"
        return template.xml2html(StringIO(result))

    id, job_dir = make_id_jobdir(username)

    save_upload_file(korel_dat, "%s/korel.dat" % job_dir)
    save_upload_file(korel_par, "%s/korel.par" % job_dir, xml=True)

    start_korel(job_dir)

    raise cherrypy.HTTPRedirect(["/jobs/%i/phase" % id], 303)

def again(username, id):
    try:
        job_dir = get_job_dir(username, id)
        korel_dat = "%s/korel.dat" % job_dir
        korel_par = "%s/korel.par" % job_dir

        new_id, new_job_dir = make_id_jobdir(username)

        if (call(["cp", korel_dat, new_job_dir]) != 0):
            raise Exception("Copy korel.dat failure")

        file = open(korel_par, "r")
        korel_par_buffer = file.read()
        file.close()

        result = []
        result.append("<again>")
        result.append("<id>%s</id>" % id)
        result.append("<new_id>%s</new_id>" % new_id)

        result.append("<korel_par><![CDATA[")
        result.append(remove_invalid_xml_char(korel_par_buffer))
        result.append("]]></korel_par>")

        result.append("</again>")

        return template.xml2html(StringIO("".join(result)))
    except Exception, e:
        call(["rm", "-rf", new_job_dir])
        raise Exception(e)

def againstart(username, id, korel_par):
    job_dir = get_job_dir(username, id)

    file = open("%s/korel.par" % job_dir, "w")
    file.write(korel_par)
    file.close()

    start_korel(job_dir)

    raise cherrypy.HTTPRedirect(["/jobs/%s/phase" % id], 303)

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
    dirs_dict = {}

    result = "<jobslist>\n"
    result += "<user>%s</user>\n" % username

    root, dirs, files = os.walk("%s/%s" % (JOBS_PATH, username)).next()
    for dir in dirs:
        # skip hidden directory
        if (dir[0] == "."):
            continue

        mtime = os.stat("%s/%s" % (root, dir)).st_mtime
        dirs_dict.update({dir: mtime})

    # sort key dir by value mtime
    for item in sorted(dirs_dict.iteritems(), key=lambda (k,v): (v,k), reverse=True):
        dir = item[0]
        phase_value = get_pahase("%s/%s" % (root, dir))

        result += "<job>\n"
        result += "<id>%s</id>\n" % dir
        result += "<phase>%s</phase>\n" % phase_value
        result += "</job>\n"

    result += "</jobslist>\n"
    return template.xml2html(StringIO(result))

def get_pahase(job_dir):
    returncode_txt = "%s/returncode.txt" % job_dir

    if (os.path.isfile("%s/traceback" % job_dir)):
        return "ERROR"

    if (os.path.isfile(returncode_txt)):
        file = open(returncode_txt, "r")
        rc = int(file.read().strip())
        file.close()

        if (rc == 0):
            return "COMPLETED"
        else:
            return "ERROR"
    else:
        return "EXECUTING"

def results(username, id):
    job_dir = get_job_dir(username, id)
    phase_value = get_pahase(job_dir)

    result = "<result>\n"
    result += "<user>%s</user>\n" % username
    result += "<id>%s</id>\n" % id
    result += "<phase>%s</phase>\n" % phase_value

    if (phase_value != "EXECUTING"):
        root, dirs, files = os.walk(job_dir).next()
        for file in files:
            if (file.find("component") == 0):
                result += "<component>%s</component>\n" % file

            # skip hidden and other file
            if ((file[0] == ".") or (file in ["korel.pid", "returncode.txt"]) or (file[-4:] == ".png")):
                continue

            stat = os.stat("%s/%s" % (root, file))

            if (stat.st_size == 0):
                continue
            elif (stat.st_size < 1024):
                size = "%iB" % stat.st_size
            elif (stat.st_size < 1024*1024):
                size = "%.1fKB" % (stat.st_size / 1024.0)
            else:
                size = "%.1fMB" % (stat.st_size / (1024.0*1024.0))

            # TODO: posilat traceback mailem
            if (file in ["stderr.txt", "traceback"]):
                type = "error"
            else:
                type = ""

            result += '<link size="%s" type="%s">%s</link>\n' % (size, type, file)

    result += "</result>\n"

    return template.xml2html(StringIO(result))

def download(username, id, file):
    job_dir = get_job_dir(username, id)
    file_path = os.path.abspath("%s/%s" % (job_dir, file))

    # DBG
    call("echo %s >> /tmp/log" % file_path, shell=True)

    if (os.path.isfile(file_path)):
        return serve_file(file_path)
    else:
        return "File '%s' not found" % file_path

def phase(username, id):
    job_dir = get_job_dir(username, id)
    phase_value = get_pahase(job_dir)

    if (phase_value != "EXECUTING"):
        raise cherrypy.HTTPRedirect(["/jobs/%s/results" % id], 303)

    result = "<phase>\n"
    result += "<user>%s</user>\n" % username
    result += "<id>%s</id>\n" % id
    result += "<phase>%s</phase>\n" % phase_value
    result += "</phase>\n"

    return template.xml2html(StringIO(result))
