#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

""" Template """

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

import os
import cherrypy

from lxml import etree
from StringIO import StringIO

import share

def xml2result(xml, name_xsl=""):
    result = []
    result.append('<?xml version="1.0" encoding="UTF-8"?>')

    http_accept = cherrypy.request.wsgi_environ["HTTP_ACCEPT"]
    #if ((http_accept.find("text/xml") != -1) or (http_accept.find("application/xml") != -1)):
    if (http_accept.find("text/html") == -1):
        result.append(xml)
        cherrypy.response.headers['Content-Type'] = "text/xml"
        return "\n".join(result)
    else:
        result.append('<?xml-stylesheet href="%s/xsl/html-%s.xsl" type="text/xsl"?>' % \
                      (share.settings["service_url"], name_xsl))
        result.append(xml)

        cherrypy.response.headers['Content-Type'] = "text/html"

        html_xsl = etree.parse("./xsl/html-%s.xsl" % name_xsl)
        html_transform = etree.XSLT(html_xsl)
        xml_tree = etree.parse(StringIO("\n".join(result)))

        return str(html_transform(xml_tree))
