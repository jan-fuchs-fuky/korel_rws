#!/usr/bin/env python
# -*- coding: utf-8 -*-

""" Korel Universal Worker Service """

#
# Author: Jan Fuchs <fuky@asu.cas.cz>
#

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
import logging
import Image
import ImageDraw
import ImageFont
import ConfigParser
from lxml import etree
from cherrypy import _cperror
from cherrypy.lib import httpauth
from cherrypy.lib.static import serve_file
from StringIO import StringIO

#script_path = "/home/fuky/svn/korel_rws/trunk"
script_path = os.path.dirname(__file__)
#script_path = os.path.dirname(os.path.realpath(os.path.abspath(sys.argv[0])))
sys.path.append(os.path.abspath("%s/lib" % script_path))
os.chdir(script_path)

import jobs
import template
import share

from mail import send_mail, SMTP_Options

font = ImageFont.load("./share/fonts/ter-u24n_unicode.pil")
parser = etree.XMLParser(remove_blank_text=True)

environ = {}
patterns = {}
patterns.update({"login": re.compile("^[a-zA-Z][a-zA-Z._]*$")})
smtp_options = SMTP_Options()

USERS_PATH = "./etc/users"
TMP_PATH = "./var/tmp"
VAR_RUN_PATH = "./var/run"
VAR_LOG_PATH = "./var/log"
EXPIRED_MATHPROBLEM = 600
MATHPROBLEMS_ON_ONEIP = 100

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
        
        result = share.make_message("Register user", "Welcome %s, registration is success." % login)
        return template.xml2result(result, "message")
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
        hashed_password = bcrypt.hashpw(params["password"].encode("utf8"), salt)

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

class UpgradingServer:
    @cherrypy.expose
    def default(self, *vpath, **params):
        username = ""

        return template.xml2result("<ownerId>%s</ownerId>" % username, "upgrading")

class RootServer:
    @cherrypy.expose
    def index(self):
        username = ""

        if (self.check_auth()):
            username = cherrypy.request.cookie["KorelUserName"].value

        return template.xml2result("<ownerId>%s</ownerId>" % username, "index")

    @cherrypy.expose
    def logout(self):
        cookie = cherrypy.request.cookie
        cookie_response = cherrypy.response.cookie

        if (cookie.has_key("KorelUserName") and cookie.has_key("KorelAuthorizationKey")):
            cookie_response["KorelUserName"] = ""
            cookie_response["KorelUserName"]["expires"] = 0
            cookie_response["KorelAuthorizationKey"] = ""
            cookie_response["KorelAuthorizationKey"]["expires"] = 0

            filename = self.make_auth_filename(cookie["KorelUserName"].value, cookie["KorelAuthorizationKey"].value)
            if (os.path.isfile(filename)):
                os.remove(filename)

        raise cherrypy.HTTPRedirect(["/"])

    @cherrypy.expose
    def login(self, *vpath, **params):
        if (params.has_key("username") and params.has_key("password")):
            if (self.check_password(params["username"], params["password"])):
                authorization_key = uuid.uuid4()
                cookie = cherrypy.response.cookie
                cookie["KorelUserName"] = params["username"]
                cookie["KorelAuthorizationKey"] = authorization_key
                filename = self.make_auth_filename(params["username"], authorization_key)

                fo = open(filename, "w")
                fo.write("%i\n" % time.time())
                fo.close()

                raise cherrypy.HTTPRedirect(["/jobs"])
            else:
                error = share.make_message("Login", "Failure. Bad username or password.", "error")
                return template.xml2result(error, "message")
        else:
            return template.xml2result("<login>true</login>", "login")

    @cherrypy.expose
    def user(self, *vpath, **params):
        method = cherrypy.request.method

        what = vpath[0]

        if ((method == "POST") and (what == "register")):
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

                body = []
                body.append("Please confirm you registration on Korel RESTful Web Services:\n\n")
                body.append("%s/user/confirm/%s\n\n" % (share.settings["service_url"], confirmation))
                body.append("First name: %s\n" % params["first_name"])
                body.append("Surname: %s\n" % params["surname"])
                body.append("Organization: %s\n" % params["organization"])
                body.append("Login: %s\n" % params["login"])
                body.append("Password: %s\n" % params["password"])
                body.append("E-mail: %s\n" % params["email"])

                send_mail(params["email"], "Korel RESTful Web Service: Register user", "".join(body), smtp_options)
                errmsg = register_user(params)

            if (errmsg != ""):
                for key in params.keys():
                    if (key in ["password", "retype_password", "mathproblem_solution"]):
                        params.pop(key)

                params.update({"errmsg": errmsg})
                raise cherrypy.HTTPRedirect(["/user/register?%s" % urllib.urlencode(params)], 303)

            result = share.make_message("Register user", "Please confirm registration on your e-mail address.")
            return template.xml2result(result, "message")
        elif ((method == "GET") and (what == "register")):
            mathproblem_png = make_mathproblem()

            result = []
            result.append("<register>")
            result.append("<mathproblem_png>%s</mathproblem_png>" % mathproblem_png)

            if (params != {}):
                for key in params:
                    result.append("<%s>%s</%s>" % (key, params[key], key))

            result.append("</register>")

            return template.xml2result("\n".join(result), "register")
        elif ((method == "GET") and (what == "confirm")):
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
    def jobs(self, *vpath, **params):
        vpath_des = ["id", "what", "file"]

        for i in range(len(vpath)):
            params.update({vpath_des[i]: vpath[i]})

        if (self.check_auth()):
            method = cherrypy.request.method
            if (method not in ["GET", "POST", "DELETE", "PUT"]):
                raise cherrypy.HTTPError(400, "Bad Request")

            http_method = getattr(self, method)
            return (http_method)(params)
        else:
            raise cherrypy.HTTPRedirect(["/login"])

    def GET(self, params):
        if (not params.has_key("id")):
            return jobs.list(self.username, self.user_settings["max_disk_space"])
        elif (params.has_key("what")):
            if (params["what"] == "phase"):
                return jobs.phase(self.username, params["id"])
            elif (params["what"] == "again"):
                return jobs.again(self.username, self.user_settings["email"], params["id"])
            elif ((params["what"] == "param") and (params.has_key("file")) and \
                  (params["file"] in ["korel.dat", "korel.par", "korel.tmp"])):
                    return jobs.download(self.username, params["id"], params["file"])
            elif (params["what"] == "results"):
                if (params.has_key("file")):
                    return jobs.download(self.username, params["id"], params["file"])
                else:
                    return jobs.results(self.username, params["id"])
            elif (params["what"] == "destruction"):
                return jobs.destruction(self.username, params["id"])
            elif (params["what"] == "lifetime"):
                raise cherrypy.HTTPError(400, "Bad Request")
            elif (params["what"] == "quote"):
                raise cherrypy.HTTPError(400, "Bad Request")
            else:
                raise cherrypy.HTTPError(400, "Bad Request")
        else:
            return jobs.detail(self.username, params["id"])

    def POST(self, params):
        if (not params.has_key("id")):
            if (not params.has_key("korel_dat")) or (not params.has_key("korel_archive")):
                result = []
                result.append("<creatingjob>")
                result.append("<ownerId>%s</ownerId>" % self.username)
                result.append("<email>%s</email>" % self.user_settings["email"])
                result.append("</creatingjob>")
                return template.xml2result("\n".join(result), "creatingjob")
            return jobs.create(self.username, params, self.user_settings["max_disk_space"])
        elif (params.has_key("what")):
            if (params["what"] == "againstart"):
                return jobs.againstart(self.username, params, environ, self.user_settings["max_disk_space"])
            elif (params["what"] == "phase") and (params.has_key("PHASE")):
                if (params["PHASE"] == "ABORT"):
                    return jobs.abort(self.username, params["id"])
                elif (params["PHASE"] == "RUN"):
                    return jobs.run(self.username, params["id"], environ)
        elif (params.has_key("ACTION")):
            if (params["ACTION"] == "DELETE"):
                return jobs.delete(self.username, params["id"])
        else:
            raise cherrypy.HTTPError(400, "Bad Request")

    def DELETE(self, params):
        if (params.has_key("id")):
            return jobs.delete(self.username, params["id"])
        else:
            raise cherrypy.HTTPError(400, "Bad Request")

    def PUT(self, params):
        raise cherrypy.HTTPError(400, "Bad Request")

    def make_auth_filename(self, username, authorization):
        return "%s/var/authorization/%s-%s" % (script_path, username, authorization)

    def check_auth(self):
        cookie = cherrypy.request.cookie

        #http_accept = cherrypy.request.wsgi_environ["HTTP_ACCEPT"]

        #if (http_accept.find("text/html") == -1):
        #    self.username = "nobody"
        #    self.make_user_settings()
        #    return True

        if (cookie.has_key("KorelUserName") and cookie.has_key("KorelAuthorizationKey")):
            self.username = cookie["KorelUserName"].value
            filename = self.make_auth_filename(self.username, cookie["KorelAuthorizationKey"].value)
            if (os.path.isfile(filename)) and (self.make_user_settings()):
                    return True

        return False

    def make_user_settings(self):
        self.user_settings = share.get_user_settings("%s/%s.xml" % (share.KOREL_USERS_PATH, self.username))

        if (self.user_settings["attrib"].has_key("allow")) and (self.user_settings["attrib"]["allow"] != "true"):
            return False

        if (not self.user_settings.has_key("max_disk_space")):
            self.user_settings.update({"max_disk_space": share.settings["max_disk_space"]})

        self.user_settings["max_disk_space"] *= (1024 * 1024)
        return True

    def check_password(self, username, password): 
        self.username = username
        user_xml = "%s/%s.xml" % (USERS_PATH, self.username)

        if (os.path.isfile(user_xml)):
            if (not self.make_user_settings()):
                return False

            hp = self.user_settings["hashed_password"]
            salt = hp[:hp.rfind("$")+23]

            if (bcrypt.hashpw(password.encode("utf8"), salt) != hp):
                return False

            try:
                home = "%s/%s" % (jobs.JOBS_PATH, self.username)
                if (not os.path.isdir(home)):
                    os.mkdir(home)
                return True 
            except:
                return False
        else: 
            self.username = ""
            return False 

def handle_error():
    cherrypy.response.status = 500
    error = share.make_message("Error", "Sorry, an error occurred.", "error")
    cherrypy.response.body = [ template.xml2result(error, "message") ]
    send_mail(share.settings["exception_email"], "Error in Korel RESTful Web Service", _cperror.format_exc(), smtp_options)

cfg = ConfigParser.RawConfigParser()
cfg.read("%s/etc/korel_rws.cfg" % (os.path.dirname(__file__)))

smtp_options.smtp_address = cfg.get("smtp", "address")
smtp_options.smtp_port = cfg.getint("smtp", "port")
smtp_options.smtp_user = cfg.get("smtp", "user")
smtp_options.smtp_password = cfg.get("smtp", "password")
smtp_options.smtp_ssl = cfg.getboolean("smtp", "ssl")

share.settings["service_url"] = cfg.get("server", "service_url")
share.settings["upgrading"] = cfg.getboolean("server", "upgrading")
share.settings["max_process"] = cfg.getint("korel", "max_process")
share.settings["max_memory"] = cfg.getint("korel", "max_memory")
share.settings["max_disk_space"] = cfg.getint("korel", "max_disk_space")
share.settings["max_upload_file"] = cfg.getint("korel", "max_upload_file") * 1024 * 1024
share.settings["max_runtime"] = cfg.getint("korel", "max_runtime")
share.settings["exception_email"] = cfg.get("server", "exception_email")

environ["KOREL_SMTP_ADDREESS"] = smtp_options.smtp_address
environ["KOREL_SMTP_PORT"] = str(smtp_options.smtp_port)
environ["KOREL_SMTP_USER"] = smtp_options.smtp_user
environ["KOREL_SMTP_PASSWORD"] = smtp_options.smtp_password
environ["KOREL_SMTP_SSL"] = str(smtp_options.smtp_ssl)
environ["KOREL_MAX_PROCESS"] = cfg.get("korel", "max_process")

cherrypy.log.screen = False
cherrypy.log.access_file = os.path.abspath("%s/access.log" % VAR_LOG_PATH)
cherrypy.log.error_file = os.path.abspath("%s/error.log" % VAR_LOG_PATH)

config = {
    'global': {
        'request.error_response': handle_error,
        'error_page.404': 'error/404.html',
        'error_page.401': 'error/401.html',
    },

    '/': {
        'tools.staticdir.root': script_path
    },

    '/xsl': {
        'tools.staticdir.on': True,
        'tools.staticdir.dir': 'xsl',
    },

    '/css': {
        'tools.staticdir.on': True,
        'tools.staticdir.dir': 'css',
    },

    '/images': {
        'tools.staticdir.on': True,
        'tools.staticdir.dir': 'images',
    },
} 

if (share.settings["upgrading"]):
    application = cherrypy.Application(UpgradingServer(), script_name=None, config=config)
else:
    application = cherrypy.Application(RootServer(), script_name=None, config=config)
