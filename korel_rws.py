#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

""" Korel RESTful Web Services """

import os
import cherrypy

from lxml import etree
from cherrypy.lib import httpauth
from cherrypy.lib.static import serve_file

import jobs
import template

class RootServer:
    @cherrypy.expose
    def index(self):
        return template.xml2html("./xml/index.xml")

    @cherrypy.expose
    def user(self):
        return "user"

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
            elif (self.action == "results"):
                return jobs.results(self.username)
            elif (self.action == "remove"):
                return jobs.remove(self.username, self.id)
            elif (self.action == "result-id"):
                if (self.file is None):
                    return jobs.result_id(self.username, self.id)
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
