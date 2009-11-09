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
import share

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
    fo = open(output, "w")

    while (1):
        data = input.file.read(1024*8)
        if (not data):
            break

        if (xml):
            data = remove_invalid_xml_char(data)

        fo.write(data)

    fo.close()

def save2file(filename, buffer, xml=True):
    if (xml):
        buffer = remove_invalid_xml_char(buffer)

    fo = open(filename, "w")
    fo.write(buffer)
    fo.close()

def get_file(filename):
    try:
        fo = open(filename, "r")
        buffer = fo.read()
        fo.close()
    except:
        return ""

    return buffer.strip()

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

def start_korel(job_dir, environ):
    Popen("nohup ./bin/korel.py %s &" % job_dir,\
          shell=True, env=environ, stdin=PIPE, stdout=PIPE, stderr=PIPE, close_fds=True)

def call_process(argv):
    pipe = Popen(argv, stderr=PIPE)
    retcode = pipe.wait()

    if (retcode == 0):
        return [True, ""]
    else:
        return [False, pipe.stderr.read()]

def process_archive(params, job_dir, tmp_dir):
    suffix = params["korel_archive"].filename
    suffix = suffix[suffix.find("."):]

    file_archive = "%s/korel%s" % (tmp_dir, suffix)
    os.mkdir(tmp_dir)
    save_upload_file(params["korel_archive"], file_archive)

    if (suffix in [".tgz", ".tar.gz"]):
        result = call_process(["tar", "-C", tmp_dir, "-z", "-x", "-f", file_archive])
    elif (suffix in [".tbz2", ".tar.bz2"]):
        result = call_process(["tar", "-C", tmp_dir, "-j", "-x", "-f", file_archive])
    elif (suffix == ".zip"):
        result = call_process(["unzip", "-d", tmp_dir, "-x", file_archive])
    else:
        raise Exception("Unsupported archive '%s'." % suffix)

    if (not result[0]):
        raise Exception("Corrupted archive.\n<br/><br/>%s" % result[1].replace("\n", "\n<br/>"))

    if (call(["mv", "%s/korel/korel.dat" % tmp_dir, job_dir]) != 0):
        raise Exception("File 'korel.dat' not found.")
    if (call(["mv", "%s/korel/korel.par" % tmp_dir, job_dir]) != 0):
        raise Exception("File 'korel.par' not found.")

    call(["mv", "%s/korel/korel.tmp" % tmp_dir, job_dir])
    call(["rm", "-rf", tmp_dir])

def start(username, params, max_disk_space):
    errmsg = "<body><![CDATA[<h2>Start new job</h2>%s]]></body>"

    input_files = False
    archive = False

    if (params["korel_archive"].filename != ""):
        input_files = True
        archive = True
    elif (params["korel_dat"].filename != "") and (params["korel_par"].filename != ""):
        input_files = True

    if (not input_files):
        errmsg = errmsg %  "Failure. Must upload files korel.dat and korel.par."
        return template.xml2result(errmsg, username)

    if (share.disk_usage(username) > max_disk_space):
        errmsg = errmsg % "Failure. Disk quota exceeded."
        return template.xml2result(errmsg, username)

    if (int(cherrypy.request.headers["Content-length"]) > share.settings["max_upload_file"]):
        errmsg = errmsg % "Failure. Upload file is large."
        return template.xml2result(errmsg, username)

    id, job_dir = make_id_jobdir(username)

    if (archive):
        try:
            tmp_dir = os.tmpnam()
            process_archive(params, job_dir, tmp_dir)
        except Exception, e:
            errmsg = errmsg % ("Failure. Error when processing '%s'. %s" % (params["korel_archive"].filename, e))
            call(["rm", "-rf", job_dir, tmp_dir])
            return template.xml2result(errmsg, username)
    else:
        save_upload_file(params["korel_dat"], "%s/korel.dat" % job_dir)
        save_upload_file(params["korel_par"], "%s/korel.par" % job_dir, xml=True)
        save_upload_file(params["korel_tmp"], "%s/korel.tmp" % job_dir)

    save2file("%s/project" % job_dir, params["project"])
    save2file("%s/comment" % job_dir, params["comment"])

    if (params.has_key("mailing")):
        save2file("%s/mailing" % job_dir, params["email"])

    raise cherrypy.HTTPRedirect(["/jobs/%i" % id], 303)

def run(username, id, environ):
    job_dir = get_job_dir(username, id)
    start_korel(job_dir, environ)

    fo = open("%s/phase" % job_dir, "w")
    fo.write("QUEUED\n")
    fo.close()

    raise cherrypy.HTTPRedirect(["/jobs/%s" % id], 303)

def again(username, email, id):
    try:
        job_dir = get_job_dir(username, id)
        korel_dat = "%s/korel.dat" % job_dir
        korel_par = "%s/korel.par" % job_dir
        project = "%s/project" % job_dir

        new_id, new_job_dir = make_id_jobdir(username)

        #if (call(["cp", korel_dat, new_job_dir]) != 0):
        #    raise Exception("Copy korel.dat failure")

        os.link(korel_dat, "%s/korel.dat" % new_job_dir)

        result = []
        result.append("<again>")
        result.append("<id>%s</id>" % id)
        result.append("<project>%s</project>" % get_file(project))
        result.append("<new_id>%s</new_id>" % new_id)
        result.append("<email>%s</email>" % email)

        result.append("<korel_par><![CDATA[")
        result.append(get_file(korel_par))
        result.append("]]></korel_par>")

        result.append("</again>")

        return template.xml2result("".join(result), username)
    except Exception, e:
        call(["rm", "-rf", new_job_dir])
        raise Exception(e)

def againstart(username, params, environ, max_disk_space):
    if (share.disk_usage(username) > max_disk_space):
        errmsg = "<body><![CDATA[<h2>Start new job</h2>Failure. Disk quota exceeded.]]></body>"
        return template.xml2result(errmsg, username)

    job_dir = get_job_dir(username, params["id"])

    file = open("%s/korel.par" % job_dir, "w")
    file.write(params["korel_par"])
    file.close()

    save2file("%s/project" % job_dir, params["project"])
    save2file("%s/comment" % job_dir, params["comment"])

    if (params.has_key("mailing")):
        save2file("%s/mailing" % job_dir, params["email"])

    start_korel(job_dir, environ)

    raise cherrypy.HTTPRedirect(["/jobs/%s/phase" % params["id"]], 303)

def abort(username, id):
    job_dir = get_job_dir(username, id)

    file = open("%s/korel.pid" % job_dir, "r")
    pid = int(file.read().strip())
    file.close()

    kill(pid)

    fo = open("%s/phase" % job_dir, "w")
    fo.write("ABORTED")
    fo.close()

    raise cherrypy.HTTPRedirect(["/jobs/%s" % id], 303)

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

def delete(username, id):
    job_dir = get_job_dir(username, id)

    try:
        file = open("%s/korel.pid" % job_dir, "r")
        pid = int(file.read().strip())
        file.close()

        kill(pid)
    except:
        pass

    call(["rm", "-rf", job_dir])

    raise cherrypy.HTTPRedirect(["/jobs"], 303)

def human_time(seconds):
    hours = seconds / 3600
    seconds = seconds % 3600
    minutes = seconds / 60
    seconds = seconds % 60

    return "%02i:%02i:%02i" % (hours, minutes, seconds)

def list(username, max_disk_space):
    dirs_dict = {}

    disk_usage = share.disk_usage(username)
    if (disk_usage > max_disk_space):
        disk_full = True
    else:
        disk_full = False

    disk_usage_pct = "%.0f" % (disk_usage / (max_disk_space * 0.01))
    disk_usage = share.bytes2human(disk_usage)
    disk_space = share.bytes2human(max_disk_space)

    result = "<jobslist>\n"
    result += "<disk_usage>%s</disk_usage>\n" % disk_usage
    result += "<disk_usage_pct>%s</disk_usage_pct>\n" % disk_usage_pct
    result += "<disk_space>%s</disk_space>\n" % disk_space
    result += "<disk_full>%s</disk_full>\n" % disk_full

    root, dirs, files = os.walk("%s/%s" % (JOBS_PATH, username)).next()
    for dir in dirs:
        # skip hidden directory
        if (dir[0] == "."):
            continue

        mtime = os.stat("%s/%s" % (root, dir)).st_mtime
        dirs_dict.update({dir: mtime})

    # sort key dir by value mtime
    for item in sorted(dirs_dict.iteritems(), key=lambda (k,v): (v,k), reverse=True):
        id = item[0]
        job_dir = "%s/%s" % (root, id)

        phase_value = get_phase("%s" % job_dir)
        project = get_file("%s/project" % job_dir)
        comment = get_file("%s/comment" % job_dir)
        time_begin = get_file("%s/time_begin" % job_dir)
        time_end = get_file("%s/time_end" % job_dir)

        human_time_begin = ""
        human_time_run = ""
        if (time_begin):
            time_begin = int(time_begin)
            human_time_begin = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(time_begin))

            if (time_end):
                time_end = int(time_end)
                human_time_run = human_time(time_end - time_begin)
            else:
                human_time_run = human_time(time.time() - time_begin)

        result += "<job>\n"
        result += "<id>%s</id>\n" % id
        result += "<phase>%s</phase>\n" % phase_value
        result += "<project>%s</project>\n" % project
        result += "<comment>%s</comment>\n" % comment
        result += "<time_begin>%s</time_begin>\n" % human_time_begin
        result += "<time_run>%s</time_run>\n" % human_time_run
        result += "</job>\n"

    result += "</jobslist>\n"
    return template.xml2result(result, username)

def get_phase(job_dir):
    returncode_txt = "%s/returncode.txt" % job_dir
    time_begin = "%s/time_begin" % job_dir
    phase_path = "%s/phase" % job_dir

    phase = ""
    if (os.path.isfile(phase_path)):
        fo = open(phase_path, "r")
        phase = fo.readline().strip()
        fo.close()

    if (phase == "ABORTED"):
        return phase
    elif (os.path.isfile("%s/traceback" % job_dir)):
        return "ERROR"
    elif (os.path.isfile(returncode_txt)):
        file = open(returncode_txt, "r")
        rc = int(file.read().strip())
        file.close()

        if (rc == 0):
            return "COMPLETED"
        else:
            return "ERROR"
    elif (os.path.isfile(time_begin)):
        return "EXECUTING"
    elif (phase):
        return phase
    else:
        return "PENDING"

def results(username, id):
    job_dir = get_job_dir(username, id)
    phase_value = get_phase(job_dir)
    hidden_files = ["korel.pid", "returncode.txt", "comment", "project", "time_begin", "time_end", "grant", "phase"]

    result = "<result>\n"
    result += "<id>%s</id>\n" % id
    result += "<phase>%s</phase>\n" % phase_value

    if (phase_value != "EXECUTING"):
        root, dirs, files = os.walk(job_dir).next()
        for file in files:
            if (file.find("component") == 0):
                result += "<component>%s</component>\n" % file

            # skip hidden and other file
            if ((file[0] == ".") or (file in hidden_files) or (file[-4:] == ".png")):
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

    return template.xml2result(result, username)

def download(username, id, file):
    job_dir = get_job_dir(username, id)
    file_path = os.path.abspath("%s/%s" % (job_dir, file))

    if (os.path.isfile(file_path)):
        return serve_file(file_path)
    else:
        return "File '%s' not found" % file_path

def phase(username, id):
    job_dir = get_job_dir(username, id)
    phase_value = get_phase(job_dir)
    result = []

    if ((cherrypy.request.wsgi_environ["HTTP_ACCEPT"]) == "application/xml"):
        result.append('<uws:phase xmlns:uws="http://www.ivoa.net/xml/UWS/v0.9.2">')
        result.append(phase_value)
        result.append('</uws:phase>')
        return template.xml2result("".join(result))
    elif (phase_value not in ["EXECUTING", "PREPARING"]):
        raise cherrypy.HTTPRedirect(["/jobs/%s/results" % id], 303)

    result.append("<phase>\n")
    result.append("<id>%s</id>\n" % id)
    result.append("<phase>%s</phase>\n" % phase_value)
    result.append("</phase>\n")
    return template.xml2result("".join(result), username)

def detail(username, id):
    job_dir = get_job_dir(username, id)

    result = []
    result.append("<detail>\n")
    result.append("<id>%s</id>\n" % id)
    result.append("<phase>%s</phase>\n" % get_phase(job_dir))
    result.append("</detail>\n")

    return template.xml2result("".join(result), username)

def destruction(username, id):
    job_dir = get_job_dir(username, id)

    time_end = "%s/time_end" % job_dir
    if (os.path.isfile(time_end)):
        fo = open(time_end, "r")
        destruction_time = time.gmtime(int(fo.readline().strip()) + (3600*24*30))
        fo.close()
    else:
        destruction_time = time.gmtime(time.time() + (3600*24*30))

    result = []
    result.append('<uws:destruction xmlns:uws="http://www.ivoa.net/xml/UWS/v0.9.2">')
    result.append(time.strftime("%Y-%m-%dT%H:%M:%S", destruction_time))
    result.append('</uws:destruction>')
    return template.xml2result("".join(result))

def params():
    pass
