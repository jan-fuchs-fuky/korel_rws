#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

""" Korel RESTful Web Services """

# TODO: vyuzivat modul logger

import os
import tempfile
import cherrypy
import urllib
import random
import bcrypt
import time
import Image
import ImageDraw
import ImageFont

from lxml import etree
from cherrypy.lib import httpauth
from cherrypy.lib.static import serve_file
from StringIO import StringIO

import jobs
import template

font = ImageFont.load("./share/fonts/ter-u24n_unicode.pil")
parser = etree.XMLParser(remove_blank_text=True)
user_lock = "./var/run/user.lock"
users_xml = "./etc/users.xml"

def make_mathproblem():
    png_path = tempfile.mktemp(".png", "mathproblem_", dir="./var/tmp")

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

def korel_lock(lock):
    i = 0
    while (1):
        try:
            fd = os.open(lock, os.O_RDWR | os.O_CREAT | os.O_EXCL, 0644)
            os.write(fd, "%s\n" % time.time())
            os.close(fd)
            break
        except Exception, e:
            i += 1

            if (i <= 60):
                # waiting 50ms
                time.sleep(0.05)
                continue
            else:
                # TODO: zapsat do logu a poslat mail
                break

def korel_unlock(lock):
    os.remove(lock)

# TODO: dokoncit
def register_user(params):
    # LOCK
    korel_lock(user_lock)
    try:
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(params["password"], salt)

        tree = etree.parse(users_xml, parser)
        users_elt = tree.xpath('/users')[0]
        user_elt = etree.SubElement(users_elt, "user")

        first_name_elt = etree.SubElement(user_elt, "first_name")
        first_name_elt.text = params["first_name"]

        surname_elt = etree.SubElement(user_elt, "surname")
        surname_elt.text = params["surname"]

        organization_elt = etree.SubElement(user_elt, "organization")
        organization_elt.text = params["organization"]

        login_elt = etree.SubElement(user_elt, "login")
        login_elt.text = params["login"]

        hashed_password_elt = etree.SubElement(user_elt, "hashed_password")
        hashed_password_elt.text = hashed_password

        email_elt = etree.SubElement(user_elt, "email")
        email_elt.text = params["email"]

        users_fo = open(users_xml, "w")
        users_fo.write(etree.tostring(tree.getroot(), encoding="UTF-8", xml_declaration=True, pretty_print=True))
        users_fo.close()
    finally:
        korel_unlock(user_lock)
    # UNLOCK

class RootServer:
    @cherrypy.expose
    def index(self):
        return template.xml2html("./xml/index.xml")

    @cherrypy.expose
    def user(self, action=None, **params):
        method = cherrypy.request.method

        if ((method == "POST") and (action == "register")):
            solution_fo = open("./var/tmp/%s.solution" % params["mathproblem_png"], "r")
            solution = solution_fo.read().strip()
            solution_fo.close()

            errmsg = ""
            if (params["mathproblem_solution"] != solution):
                errmsg = "Bad solution math problem."
            elif (params["password"] != params["retype_password"]):
                errmsg = "Bad re-type password."
            elif ("" in params.values()):
                errmsg = "All values is required."
            else:
                register_user(params)

            if (errmsg != ""):
                for key in params.keys():
                    if (key in ["password", "retype_password", "mathproblem_solution"]):
                        params.pop(key)

                params.update({"errmsg": errmsg})
                raise cherrypy.HTTPRedirect(["/user/register?%s" % urllib.urlencode(params)], 303)
        elif ((method == "GET") and (action == "register")):
            mathproblem_png = make_mathproblem()

            result  = "<register_user>"
            result += "<mathproblem_png>%s</mathproblem_png>" % mathproblem_png

            if (params != {}):
                for key in params:
                    result += "<%s>%s</%s>" % (key, params[key], key)

            result += "</register_user>"

            return template.xml2html(StringIO(result))

    @cherrypy.expose
    def mathproblem(self, file):
        if (file[-4:] != ".png"):
            raise cherrypy.HTTPError(400, "Bad Request")

        file_path = os.path.abspath("./var/tmp/%s" % file)
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

        if ((self.username == "admin") and (self.password == "heslo")):
            try:
                home = "%s/%s" % (jobs.JOBS_PATH, self.username)
                if (not os.path.isdir(home)):
                    os.mkdir(home)
                return True 
            except:
                return False
        else: 
            return False 

def main():
    config = {
        'global': {
            'server.socket_port': 8000,
            'server.ssl_certificate': 'cert.pem',
            'server.ssl_private_key': 'key.pem'
        }
    } 
 
    cherrypy.quickstart(RootServer(), '/', config=config)

if __name__ == '__main__':
    main()
