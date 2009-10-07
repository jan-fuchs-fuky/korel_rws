""" Template """

import cherrypy
from lxml import etree

html_xsl = etree.parse("./xsl/html.xsl")
html_transform = etree.XSLT(html_xsl)

def xml2html(xml):
    xml_tree = etree.parse(xml)
    html = str(html_transform(xml_tree, service_url="'%s'" % cherrypy.url()))

    return html
