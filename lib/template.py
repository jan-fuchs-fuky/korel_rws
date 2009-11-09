""" Template """

import os
import cherrypy
from lxml import etree
from StringIO import StringIO

html_xsl = etree.parse("./xsl/html.xsl")
html_transform = etree.XSLT(html_xsl)

def xml2result(xml, user=""):
    service_url = "'%s'" % os.getenv("KOREL_SERVICE_URL", default="https://127.0.0.1:8000")

    if (xml[0] == "<"):
        xml = StringIO('<?xml version="1.0" encoding="UTF-8"?>\n%s' % xml)

    if ((cherrypy.request.wsgi_environ["HTTP_ACCEPT"]) == "application/xml"):
        return xml
    else:
        xml_tree = etree.parse(xml)
        html = str(html_transform(xml_tree, service_url=service_url, user="'%s'" % user))

        return html
