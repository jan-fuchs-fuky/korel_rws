#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

""" Korel RESTful Web Services """

__version__ = "0.8"

import os
import sys
import re
import uuid
import tempfile
import subprocess
import cherrypy
import urllib
import random
import bcrypt
import time
import smtplib
import email
import logging
import Image
import ImageDraw
import ImageFont

from lxml import etree
from cherrypy import _cperror
from cherrypy.lib import httpauth
from cherrypy.lib.static import serve_file
from StringIO import StringIO
from email.MIMEText import MIMEText

import jobs
import template

font = ImageFont.load("./share/fonts/ter-u24n_unicode.pil")
parser = etree.XMLParser(remove_blank_text=True)

patterns = {}
patterns.update({"login": re.compile("^[a-zA-Z][a-zA-Z._]*$")})

SMTP_SERVER = {
    "ip": "mail.fuky.org",
    "port": 25,
    "user": "test@fuky.org",
    "password": "1heslicko!",
}

MAIL_CONTENT_TYPE = "plain"
MAIL_CHARSET = "utf-8"
MAIL_FROM = "korel@sunstel.asu.cas.cz"
MAIL_USER_AGENT = "KorelRWS/%s" % __version__

USERS_PATH = "./etc/users"
TMP_PATH = "./var/tmp"
VAR_RUN_PATH = "./var/run"
VAR_LOG_PATH = "./var/log"
KOREL_RWS_PID = "./var/run/korel_rws.pid"
EXPIRED_MATHPROBLEM = 600
MATHPROBLEMS_ON_ONEIP = 100

def send_mail(to, subject, body):
    mime_text = MIMEText(body.decode("utf-8").encode(MAIL_CHARSET), MAIL_CONTENT_TYPE, MAIL_CHARSET)

    mime_text["Date"] = time.strftime("%a, %d %b %Y %H:%M:%S -0000", time.gmtime())
    mime_text["From"] = MAIL_FROM
    mime_text["To"] = to
    mime_text["Subject"] = subject
    mime_text["User-Agent"] = MAIL_USER_AGENT
    
    s = smtplib.SMTP(SMTP_SERVER["ip"], SMTP_SERVER["port"])
    
    #s.set_debuglevel(1)
    s.starttls()
    s.login(SMTP_SERVER["user"], SMTP_SERVER["password"])
    s.sendmail(MAIL_FROM, to, mime_text.as_string())
    s.quit()

def rm_expired_mathproblem():
    ip_dict = {}
    for file in os.listdir(TMP_PATH):
        file_path = "%s/%s" % (TMP_PATH, file)
        if ((os.path.isfile(file_path)) and (file[:12] == "mathproblem_")):
            ip = file[12:file[12:].find("_")+12]

            if (not ip_dict.has_key(ip)):
                ip_dict.update({ip: []})

            ip_dict[ip].append(file_path)

            file_mtime = os.stat(file_path).st_mtime
            if ((time.time() - file_mtime) >= EXPIRED_MATHPROBLEM):
                os.remove(file_path)

    for key in ip_dict.keys():
        if (len(ip_dict[key]) > MATHPROBLEMS_ON_ONEIP):
            for file_path in ip_dict[key]:
                subprocess.call(["rm", file_path])

def make_mathproblem():
    rm_expired_mathproblem()

    png_path = tempfile.mktemp(".png", "mathproblem_%s_" % cherrypy.request.remote.ip, dir=TMP_PATH)

    img = Image.new("RGB", (130, 45), "White")
    
    x = random.randint(0, 9)
    operation_chr = ["+", "-", "*"][random.randint(0, 2)]
    y = random.randint(0, 9)
    result = eval("%i %s %i" % (x, operation_chr, y))

    drawing = ImageDraw.ImageDraw(img, "RGB")
    drawing.text((0, 0), "(%i %s %i) = " % (x, operation_chr, y), fill=0, font=font)
    
    img.save(png_path)

    result_fo = open("%s.solution" % png_path, "w")
    result_fo.write("%i\n" % result)
    result_fo.close()

    return os.path.basename(png_path)

def make_confirmation(login):
    confirmation = uuid.uuid4()

    fo = open("%s/confirmation_%s" % (TMP_PATH, confirmation), "w")
    fo.write("%s\n" % login)
    fo.close()

    return confirmation

def action_confirmation(confirmation):
    confirmation_file = "%s/confirmation_%s" % (TMP_PATH, confirmation)

    if (os.path.isfile(confirmation_file)):
        fo = open(confirmation_file, "r")
        login = fo.read().strip()
        fo.close()

        user_filename = "%s/%s.xml" % (USERS_PATH, login)

        tree = etree.parse(user_filename, parser)
        user_elt = tree.xpath("/user")[0]
        user_elt.attrib["allow"] = "true"

        fo = open(user_filename, "w")
        fo.write(etree.tostring(tree.getroot(), encoding="UTF-8", xml_declaration=True, pretty_print=True))
        fo.close()

        os.remove(confirmation_file)
        
        result  = "<body><![CDATA["
        result += "<h2>Register user</h2>"
        result += "Welcome <b>%s</b>, registration is success." % login
        result += "]]></body>"

        return template.xml2html(StringIO(result))
    else:
        raise cherrypy.HTTPError(400, "Bad Request")

def korel_lock(lock, timeout=1000):
    i = 0
    while (1):
        try:
            fd = os.open(lock, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
            os.write(fd, "%s\n" % time.time())
            os.close(fd)
            break
        except Exception, e:
            i += 1

            if (i <= timeout):
                # waiting 50ms
                time.sleep(0.05)
                continue
            else:
                # TODO: zapsat do logu a poslat mail
                raise Exception("Create lock file failure")

def korel_unlock(lock):
    os.remove(lock)

def register_user(params):
    user_filename = "%s/%s.xml" % (USERS_PATH, params["login"])
    lock = "%s/user_%s.lock" % (VAR_RUN_PATH, params["login"])
    locked = False

    try:
        try:
            # LOCK
            korel_lock(lock, 0)
            locked = True
            user_fd = os.open(user_filename, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
        except:
            return "Please enter other login. Login '%s' exists." % params["login"]

        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(params["password"], salt)

        user_xml  = "<?xml version='1.0' encoding='UTF-8'?>\n"
        user_xml += "<user allow='false'>\n"
        user_xml += "    <first_name>%s</first_name>\n" % params["first_name"]
        user_xml += "    <surname>%s</surname>\n" % params["surname"]
        user_xml += "    <organization>%s</organization>\n" % params["organization"]
        user_xml += "    <email>%s</email>\n" % params["email"]
        user_xml += "    <hashed_password>%s</hashed_password>\n" % hashed_password
        user_xml += "</user>\n"

        os.write(user_fd, user_xml)
        os.close(user_fd)
    finally:
        if (locked):
            korel_unlock(lock)
            # UNLOCK

    return ""

class RootServer:
    @cherrypy.expose
    def index(self):
        return template.xml2html("./xml/index.xml")

    @cherrypy.expose
    def user(self, *vpath, **params):
        method = cherrypy.request.method

        action = vpath[0]

        if ((method == "POST") and (action == "register")):
            # defence against mathproblem_png == "../../any_file" atack
            mathproblem_png = os.path.basename(params["mathproblem_png"])
            if (len(mathproblem_png) != len(params["mathproblem_png"])):
                raise cherrypy.HTTPError(400, "Bad Request")

            # defence against mathproblem_png != "mathproblem_*" atack
            if (params["mathproblem_png"][:12] != "mathproblem_"):
                raise cherrypy.HTTPError(400, "Bad Request")

            mathproblem_png = "%s/%s" % (TMP_PATH, params["mathproblem_png"])
            mathproblem_solution = "%s/%s.solution" % (TMP_PATH, params["mathproblem_png"])

            errmsg = ""
            if (os.path.isfile(mathproblem_solution)):
                solution_fo = open(mathproblem_solution, "r")
                solution = solution_fo.read().strip()
                solution_fo.close()

                subprocess.call(["rm", mathproblem_png])
                subprocess.call(["rm", mathproblem_solution])

                if (params["mathproblem_solution"] != solution):
                    errmsg = "Bad solution math problem."
                elif (params["password"] != params["retype_password"]):
                    errmsg = "Bad re-type password."
                elif ("" in params.values()):
                    errmsg = "All values is required."
                elif (len(params["password"]) < 6):
                    errmsg = "Password must have min. 6 characters."
                elif (len(params["login"]) < 3):
                    errmsg = "Login must have min. 3 characters."
                elif (not patterns["login"].findall(params["login"])):
                    errmsg = "Login '%s' is not valid." % params["login"]
            else:
                errmsg = "Math problem expired. Solve new math problem."

            if (not errmsg):
                confirmation = make_confirmation(params["login"])

                body  = "Please confirm you registration on Korel RESTful Web Services:\n\n"
                body += "https://127.0.0.1:8000/user/confirm/%s\n\n" % confirmation
                body += "First name: %s\n" % params["first_name"]
                body += "Surname: %s\n" % params["surname"]
                body += "Organization: %s\n" % params["organization"]
                body += "Login: %s\n" % params["login"]
                body += "Password: %s\n" % params["password"]
                body += "E-mail: %s\n" % params["email"]

                send_mail("fuky@fuky.org", "Korel RESTful Web Service: Register user", body)
                errmsg = register_user(params)

                result  = "<body><![CDATA["
                result += "<h2>Register user</h2>"
                result += "Please confirm registration on your e-mail address."
                result += "]]></body>"

            if (errmsg != ""):
                for key in params.keys():
                    if (key in ["password", "retype_password", "mathproblem_solution"]):
                        params.pop(key)

                params.update({"errmsg": errmsg})
                raise cherrypy.HTTPRedirect(["/user/register?%s" % urllib.urlencode(params)], 303)

            return template.xml2html(StringIO(result))
        elif ((method == "GET") and (action == "register")):
            mathproblem_png = make_mathproblem()

            result  = "<register_user>"
            result += "<mathproblem_png>%s</mathproblem_png>" % mathproblem_png

            if (params != {}):
                for key in params:
                    result += "<%s>%s</%s>" % (key, params[key], key)

            result += "</register_user>"

            return template.xml2html(StringIO(result))
        elif ((method == "GET") and (action == "confirm")):
            return action_confirmation(vpath[1])
        else:
            raise cherrypy.HTTPError(400, "Bad Request")

    @cherrypy.expose
    def mathproblem(self, file):
        if (file[-4:] != ".png"):
            raise cherrypy.HTTPError(400, "Bad Request")

        file_path = os.path.abspath("%s/%s" % (TMP_PATH, file))
        return serve_file(file_path)

    @cherrypy.expose
    def css(self, file):
        file_path = os.path.abspath("./css/%s" % file)
        return serve_file(file_path)

    @cherrypy.expose
    def jobs(self, id=None, action=None, file=None, korel_dat=None, korel_par=None):
        self.id = id
        self.action = action
        self.file = file
        self.korel_dat = korel_dat
        self.korel_par = korel_par

        if (self.check_auth()):
            method = cherrypy.request.method
            if (method not in ["GET", "POST", "DELETE", "PUT"]):
                raise cherrypy.HTTPError(400, "Bad Request")

            http_method = getattr(self, method)
            return (http_method)()
        else:
            cherrypy.response.headers["www-authenticate"] = httpauth.basicAuth("Korel RESTful Web Services") 
            raise cherrypy.HTTPError(401, "You are not authorized to access that resource") 

    def GET(self):
        if (self.id is None):
            return jobs.list(self.username)
        elif (self.action is not None):
            if (self.action == "phase"):
                return jobs.phase(self.username, self.id)
            elif (self.action == "remove"):
                return jobs.remove(self.username, self.id)
            elif (self.action == "again"):
                return jobs.again(self.username, self.id)
            elif (self.action == "results"):
                if (self.file is None):
                    return jobs.results(self.username, self.id)
                else:
                    return jobs.download(self.username, self.id, self.file)
            elif (self.action == "lifetime"):
                raise cherrypy.HTTPError(400, "Bad Request")
            elif (self.action == "quote"):
                raise cherrypy.HTTPError(400, "Bad Request")
            else:
                raise cherrypy.HTTPError(400, "Bad Request")
        else:
            raise cherrypy.HTTPError(400, "Bad Request")

    def POST(self):
        if (self.id is None):
            if (self.korel_dat is None) or (self.korel_par is None):
                return template.xml2html("./xml/start_new_job.xml")

            return jobs.start(self.username, self.korel_dat, self.korel_par)
        elif (self.action == "againstart"):
            return jobs.againstart(self.username, self.id, self.korel_par)
        else:
            return jobs.cancel(self.username, self.id)

    def DELETE(self):
        if (self.id is not None):
            return jobs.cancel(self.username)
        else:
            raise cherrypy.HTTPError(400, "Bad Request")

    def PUT(self):
        raise cherrypy.HTTPError(400, "Bad Request")

    def check_auth(self): 
        try: 
            auth = httpauth.parseAuthorization(cherrypy.request.headers['authorization']) 
        except KeyError: 
            return False 

        self.username = auth['username'] 
        self.password = auth['password'] 
        user_xml = "%s/%s.xml" % (USERS_PATH, self.username)

        if (os.path.isfile(user_xml)):
            lock = "%s/user_%s.lock" % (VAR_RUN_PATH, self.username)
            # LOCK
            korel_lock(lock)
            try:
                user_elts = etree.parse(user_xml, parser).xpath('/user')
            finally:
                korel_unlock(lock)
                # UNLOCK

            for user_elt in user_elts:
                if ((not user_elt.attrib.has_key("allow")) or (user_elt.attrib["allow"] != "true")):
                    return False

                for element in user_elt.getchildren():
                    if (element.tag == "hashed_password"):
                        hashed_password = element.text
                        break

            salt = hashed_password[:hashed_password.rfind("$")+23]

            if (bcrypt.hashpw(self.password, salt) != hashed_password):
                return False

            try:
                home = "%s/%s" % (jobs.JOBS_PATH, self.username)
                if (not os.path.isdir(home)):
                    os.mkdir(home)
                return True 
            except:
                return False
        else: 
            return False 

#
#    In CherryPy 3.1, cherrypy.engine can do all of the above via the
#    Daemonizer plugin: 
#
#        from cherrypy.restsrv.plugins import Daemonizer, PIDFile 
#        Daemonizer(cherrypy.engine).subscribe()
#
#    ...and manage pid files via: 
#
#        PIDFile(cherrypy.engine, filename).subscribe()
#
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
    
    os.close(sys.stdin.fileno())
    os.close(sys.stdout.fileno())
    os.close(sys.stderr.fileno())

def create_pid():
    if (os.path.isfile(KOREL_RWS_PID)):
        pid_fo = open(KOREL_RWS_PID, "r")
        old_pid = pid_fo.readline().strip()
        pid_fo.close()

        if (subprocess.call(["ps", "--pid", old_pid, "-o", "pid="]) != 0):
            os.remove(KOREL_RWS_PID)

    try:
        fd = os.open(KOREL_RWS_PID, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
        os.write(fd, "%i\n" % os.getpid())
        os.close(fd)
    except:
        sys.exit(1)

def handle_error():
    cherrypy.response.status = 500

    result  = "<body><![CDATA["
    result += "<h2>Error</h2>"
    result += "Sorry, an error occurred."
    result += "]]></body>"

    cherrypy.response.body = [ template.xml2html(StringIO(result)) ]
    send_mail("fuky@fuky.org", "Error in Korel RESTful Web Service", _cperror.format_exc())

def main():
    config = {
        'global': {
            'server.socket_port': 8000,
            'server.ssl_certificate': 'cert.pem',
            'server.ssl_private_key': 'key.pem',
            'request.error_response': handle_error,
            'error_page.404': "error/404.html"
        }
    } 
 
    cherrypy.quickstart(RootServer(), '/', config=config)

#
#   Note that the internal CherryPy engine by default attempts to register signal
#   handlers for SIGTERM and SIGHUP.
#
if __name__ == '__main__':
    #daemonize()
    create_pid()

    cherrypy.log.screen = False
    cherrypy.log.access_file = os.path.abspath("%s/access.log" % VAR_LOG_PATH)
    cherrypy.log.error_file = os.path.abspath("%s/error.log" % VAR_LOG_PATH)

    main()

    if (os.path.isfile(KOREL_RWS_PID)):
        os.remove(KOREL_RWS_PID)
