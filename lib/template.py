""" Template """

import os
import cherrypy
from lxml import etree

html_xsl = etree.parse("./xsl/html.xsl")
html_transform = etree.XSLT(html_xsl)

def xml2html(xml):
    service_url = "'%s'" % os.getenv("KOREL_SERVICE_URL", default="https://127.0.0.1:8000")
    xml_tree = etree.parse(xml)
    html = str(html_transform(xml_tree, service_url=service_url))

    return html
