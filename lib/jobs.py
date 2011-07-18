#!/usr/bin/env python
# -*- coding: utf-8 -*-

""" Jobs """

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
# $URL$
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

korel_plots = [
    [ "plot01phg.png", "phg.ps" ],
    [ "plot02map.png", "korermap.dat" ],
    [ "plot03rv.png",  "korel.rv" ],
    [ "plot04dat.png", "korel.dat" ],
    [ "plot05tmp.png", "korel.tmp" ],
    [ "plot06o-c.png", "korel.o-c" ],
]

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

def create(username, params, max_disk_space):
    error_title = "Create new job"
    input_files = False
    archive = False

    if (params["korel_archive"].filename != ""):
        input_files = True
        archive = True
    elif (params["korel_dat"].filename != "") and (params["korel_par"].filename != ""):
        input_files = True

    if (not input_files):
        error = share.make_message(error_title, "Failure. Must upload files korel.dat and korel.par.", "error", username)
        return template.xml2result(error, "message")

    if (share.disk_usage(username) > max_disk_space):
        error = share.make_message(error_title, "Failure. Disk quota exceeded.", "error", username)
        return template.xml2result(error, "message")

    if (int(cherrypy.request.headers["Content-length"]) > share.settings["max_upload_file"]):
        error = share.make_message(error_title, "Failure. Upload file is large.", "error", username)
        return template.xml2result(error, "message")

    id, job_dir = make_id_jobdir(username)

    if (archive):
        try:
            tmp_dir = os.tmpnam()
            process_archive(params, job_dir, tmp_dir)
        except Exception, e:
            error = share.make_message(error_title, \
                    "Failure. Error when processing '%s'. %s" % (params["korel_archive"].filename, e), \
                    "error", username)
            call(["rm", "-rf", job_dir, tmp_dir])
            return template.xml2result(error, "message")
    else:
        save_upload_file(params["korel_dat"], "%s/korel.dat" % job_dir)
        save_upload_file(params["korel_par"], "%s/korel.par" % job_dir, xml=True)
        save_upload_file(params["korel_tmp"], "%s/korel.tmp" % job_dir)

    save2file("%s/.project" % job_dir, params["project"])
    save2file("%s/.comment" % job_dir, params["comment"])
    save2file("%s/.phase" % job_dir, "PENDING")
    save2file("%s/.executionDuration" % job_dir, "3000")
    save2file("%s/.destruction" % job_dir, "8600")

    if (params.has_key("mailing")):
        save2file("%s/.mailing" % job_dir, params["email"])

    raise cherrypy.HTTPRedirect(["/jobs/%i" % id], 303)

def run(username, id, environ):
    job_dir = get_job_dir(username, id)
    start_korel(job_dir, environ)

    fo = open("%s/.phase" % job_dir, "w")
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

        fo = open("%s/.phase" % new_job_dir, "w")
        fo.write("PENDING\n")
        fo.close()

        os.link(korel_dat, "%s/korel.dat" % new_job_dir)

        result = []
        result.append("<again>")
        result.append("<ownerId>%s</ownerId>" % username)
        result.append("<id>%s</id>" % id)
        result.append("<project>%s</project>" % get_file(project))
        result.append("<new_id>%s</new_id>" % new_id)
        result.append("<email>%s</email>" % email)

        result.append("<korel_par><![CDATA[%s]]></korel_par>" % get_file(korel_par))
        result.append("</again>")

        return template.xml2result("\n".join(result), "again")
    except Exception, e:
        call(["rm", "-rf", new_job_dir])
        raise Exception(e)

def againstart(username, params, environ, max_disk_space):
    if (share.disk_usage(username) > max_disk_space):
        error = share.make_message("Start new job", "Failure. Disk quota exceeded.", "error", username)
        return template.xml2result(error, "message")

    job_dir = get_job_dir(username, params["id"])

    file = open("%s/korel.par" % job_dir, "w")
    file.write(params["korel_par"])
    file.close()

    save2file("%s/.project" % job_dir, params["project"])
    save2file("%s/.comment" % job_dir, params["comment"])

    if (params.has_key("mailing")):
        save2file("%s/.mailing" % job_dir, params["email"])

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

    job_tgz = "%s.tgz" % job_dir
    if (os.path.isfile(job_tgz)):
        os.remove(job_tgz)

    raise cherrypy.HTTPRedirect(["/jobs"], 303)

def human_time(seconds, spare=0):
    seconds = int(seconds)
    if (spare != 0):
        seconds -= int(spare)

    hours = seconds / 3600
    seconds = seconds % 3600
    minutes = seconds / 60
    seconds = seconds % 60

    return "%02i:%02i:%02i" % (hours, minutes, seconds)

def format_time(seconds):
    if (seconds):
        return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(int(seconds)))
    else:
        return ""

def get_info(job_dir):
    info = {
        "project": "",
        "comment": "",
        "phase": "",
        "startTime": "",
        "endTime": "",
        "executionDuration": "",
        "destruction": "",
    }

    for key in info.keys():
        try:
            # hidden file
            fo = open("%s/.%s" % (job_dir, key), "r")
            info[key] = fo.read().strip()
            fo.close()
        except:
            info[key] = ""

    return info

def get_param(id, filename):
    return "%s/jobs/%s/param/%s" % (share.settings["service_url"], id, filename)

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

    # TODO
    #result += "<disk_usage>%s</disk_usage>\n" % disk_usage
    #result += "<disk_usage_pct>%s</disk_usage_pct>\n" % disk_usage_pct
    #result += "<disk_space>%s</disk_space>\n" % disk_space
    #result += "<disk_full>%s</disk_full>\n" % disk_full

    root, dirs, files = os.walk("%s/%s" % (JOBS_PATH, username)).next()
    for dir in dirs:
        # skip hidden directory
        if (dir[0] == "."):
            continue

        mtime = os.stat("%s/%s" % (root, dir)).st_mtime
        dirs_dict.update({dir: mtime})

    result = []
    result.append("<uws:joblist %s>" % share.XMLNS)
    result.append('<uws:ownerId>%s</uws:ownerId>' % username)
    # sort key dir by value mtime
    for item in sorted(dirs_dict.iteritems(), key=lambda (k,v): (v,k), reverse=True):
        id = item[0]
        job_dir = "%s/%s" % (root, id)

        if (not os.path.isfile("%s/korel.par" % job_dir)):
            # run again not success
            call(["rm", "-rf", job_dir])
            continue

        info = get_info(job_dir)

        runningTime = ""
        if (info["endTime"] and info["startTime"]):
            runningTime = human_time(info["endTime"], info["startTime"])
        elif (info["startTime"]):
            runningTime = human_time(time.time(), info["startTime"])

        #result.append('<uws:jobref id="%s" xlink:href="%s/jobs/%s">' % (id, share.settings["service_url"], id))
        #result.append('    <uws:phase>%s</uws:phase>' % info["phase"])
        #result.append('</uws:jobref>')
        result.append('<uws:job>')
        result.append('<uws:jobId>%s</uws:jobId>"' % id)
        result.append('<uws:ownerId>%s</uws:ownerId>' % username)
        result.append('<uws:phase>%s</uws:phase>' % info["phase"])
        result.append('<uws:startTime>%s</uws:startTime>' % format_time(info["startTime"]))
        result.append('<uws:endTime>%s</uws:endTime>' % format_time(info["endTime"]))
        result.append('<uws:executionDuration>%s</uws:executionDuration>' % info["executionDuration"])
        result.append('<uws:destruction>%s</uws:destruction>' % format_time(info["destruction"]))
        result.append('<uws:parameters>')
        result.append('<uws:parameter id="image" byReference="true">jobs/jobid123/param/image</uws:parameter>')
        result.append('<uws:parameter id="korel.dat" byReference="true">%s</uws:parameter>' % get_param(id, "korel.dat"))
        result.append('<uws:parameter id="korel.par" byReference="true">%s</uws:parameter>' % get_param(id, "korel.par"))
        result.append('<uws:parameter id="korel.tmp" byReference="true">%s</uws:parameter>' % get_param(id, "korel.tmp"))
        result.append('</uws:parameters>')
        result.append('<uws:results>')
        result.append('<uws:result id="correctedImage" xlink:href="http://myserver.org/uws/jobs/jobid123/result/image"/>')
        result.append('</uws:results>')
        result.append('<uws:errorSummary type="transient">')
        result.append('<uws:message>we have problem</uws:message>')
        result.append('<uws:detail xlink:href="http://myserver.org/uws/jobs/jobid123/error"/>')
        result.append('</uws:errorSummary>')
        result.append('<uws:jobInfo>')
        result.append('<comment>%s</comment>' % info["comment"])
        result.append('<project>%s</project>' % info["project"])
        result.append('<runningTime>%s</runningTime>' % runningTime)
        result.append('</uws:jobInfo>')
        result.append('</uws:job>')

    result.append("</uws:joblist>")

    #return template.xml2result("\n".join(result), "jobs")
    return template.xml2result("\n".join(result), "joblist")

def results(username, id):
    job_dir = get_job_dir(username, id)

    fo = open("%s/.phase" % job_dir, "r")
    phase_value = fo.readline().strip()
    fo.close()

    result = []
    result.append("<result>")
    result.append('<ownerId>%s</ownerId>' % username)
    result.append("<id>%s</id>" % id)
    result.append("<phase>%s</phase>" % phase_value)

    if (phase_value != "EXECUTING"):
        root, dirs, files = os.walk(job_dir).next()
        files.sort()
        for file in files:
            if (file.find("component") == 0):
                result.append("<component>%s</component>" % file)

            if (file[-4:] == ".png"):
                for plot in korel_plots:
                    if (file.find(plot[0]) == 0):
                        result.append('<plot source="%s">%s</plot>' % (plot[1], plot[0]))

                # skip PNG file
                continue

            # skip hidden file
            if (file[0] == "."):
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

            result.append('<link size="%s" type="%s">%s</link>' % (size, type, file))

    result.append("</result>")

    return template.xml2result("\n".join(result), "results")

def download(username, id, file):
    job_dir = get_job_dir(username, id)
    file_path = os.path.abspath("%s/%s" % (job_dir, file))

    if (os.path.isfile(file_path)):
        if (file_path[-4:] == ".dat"):
            return serve_file(file_path, content_type="text/plain")
        else:
            return serve_file(file_path)
    else:
        return "File '%s' not found" % file_path

def phase(username, id):
    job_dir = get_job_dir(username, id)

    fo = open("%s/.phase" % job_dir, "r")
    phase_value = fo.readline().strip()
    fo.close()

    result = []

    #if ((cherrypy.request.wsgi_environ["HTTP_ACCEPT"]) == "application/xml"):
    #    return template.xml2result("".join(result))
    if (phase_value not in ["EXECUTING", "PENDING", "QUEUED"]):
        raise cherrypy.HTTPRedirect(["/jobs/%s/results" % id], 303)

    result.append('<phase>')
    result.append('<ownerId>%s</ownerId>' % username)
    result.append('<value>%s</value>' % phase_value)
    result.append('</phase>')

    return template.xml2result("\n".join(result), "phase")

def detail(username, id):
    job_dir = get_job_dir(username, id)

    fo = open("%s/.phase" % job_dir, "r")
    phase_value = fo.readline().strip()
    fo.close()

    if (phase_value in ["EXECUTING", "QUEUED"]):
       raise cherrypy.HTTPRedirect(["/jobs/%s/phase" % id], 303)

    info = get_info(job_dir)
    runningTime = ""
    if (info["endTime"] and info["startTime"]):
        runningTime = human_time(info["endTime"], info["startTime"])
    elif (info["startTime"]):
        runningTime = human_time(time.time(), info["startTime"])

    result = []
    result.append('<uws:job %s>' % share.XMLNS)
    result.append('<uws:jobId>%s</uws:jobId>"' % id)
    result.append('<uws:ownerId>%s</uws:ownerId>' % username)
    result.append('<uws:phase>%s</uws:phase>' % phase_value)
    result.append('<uws:startTime>%s</uws:startTime>' % format_time(info["startTime"]))
    result.append('<uws:endTime>%s</uws:endTime>' % format_time(info["endTime"]))
    result.append('<uws:executionDuration>%s</uws:executionDuration>' % info["executionDuration"])
    result.append('<uws:destruction>%s</uws:destruction>' % format_time(info["destruction"]))

    result.append('<uws:parameters>')

    for param in ["korel.dat", "korel.par", "korel.tmp"]:
        param_file = "%s/%s" % (job_dir, param)
        if (os.path.isfile(param_file) and (os.stat(param_file).st_size > 0)):
            result.append('<uws:parameter id="%s" byReference="true">%s</uws:parameter>' % \
                (param, get_param(id, param)))

    result.append('</uws:parameters>')

    result.append('<uws:errorSummary type="transient">')
    result.append('<uws:message>we have problem</uws:message>')
    result.append('<uws:detail xlink:href="http://myserver.org/uws/jobs/jobid123/error"/>')
    result.append('</uws:errorSummary>')
    result.append('<uws:jobInfo>')
    result.append('<comment>%s</comment>' % info["comment"])
    result.append('<project>%s</project>' % info["project"])
    result.append('<runningTime>%s</runningTime>' % runningTime)
    result.append('</uws:jobInfo>')
    result.append('</uws:job>')

    return template.xml2result("\n".join(result), "job")

def destruction(username, id):
    job_dir = get_job_dir(username, id)

    endTime = "%s/endTime" % job_dir
    if (os.path.isfile(endTime)):
        fo = open(endTime, "r")
        destruction_time = time.gmtime(int(fo.readline().strip()) + (3600*24*30))
        fo.close()
    else:
        destruction_time = time.gmtime(time.time() + (3600*24*30))

    result = []
    result.append('<destruction>')
    result.append('<ownerId>%s</ownerId>' % username)
    result.append('<value>%s</value>' % time.strftime("%Y-%m-%dT%H:%M:%S", destruction_time))
    result.append('</destruction>')
    return template.xml2result("\n".join(result), "destruction")

def params():
    pass
