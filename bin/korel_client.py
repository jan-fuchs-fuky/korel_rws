#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import time
import urllib
import urllib2
import lxml.etree as etree
from StringIO import StringIO

import MultipartPostHandler

class KorelClient():
    def __init__(self):
        self.service_url = "https://stelweb.asu.cas.cz/vo-korel"
        #self.service_url = "https://localhost"

        opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(), MultipartPostHandler.MultipartPostHandler)
        urllib2.install_opener(opener)

        self.login()
        self.run_job()

        #result = self.GET()
        #print "%s %s" % (result.code, result.msg)
        #print result.read()
 
    def login(self):
        params = {}
        params["username"] = "fuky"
        params["password"] = "heslo"

        result = self.POST("/login", params)
        result_xml = result.read()

        print "%s %s" % (result.code, result.msg)
        jobs_etree = etree.parse(StringIO(result_xml))

        message_text_elt = jobs_etree.xpath("/message/text")
        if (message_text_elt):
            print message_text_elt[0].text
        else:
            self.list_jobs(jobs_etree)

    def list_jobs(self, jobs_etree):
        print "ID  Project              Starting Time       Running Time Phase"
        print "-----------------------------------------------------------------------"
        job_elts = jobs_etree.xpath("/uws:joblist/uws:job", namespaces={"uws": "http://www.ivoa.net/xml/UWS/v1.0rc3"})
        for job_elt in job_elts:
            job = {}
            for children in job_elt.getchildren():
                tag = children.tag.split("}")[1]

                if (tag == "jobInfo"):
                    for jobInfo in children.getchildren():
                        job["jobInfo.%s" % jobInfo.tag] = jobInfo.text
                else:
                    job[tag] = children.text

            print "%(jobId)-3s %(jobInfo.project)-20s %(startTime)-19s %(jobInfo.runningTime)-12s %(phase)-10s " % job
   
    def run_job(self):
        params = {}
        params["project"] = "Client"
        params["comment"] = "Test Korel RWS client"
        params["korel_archive"] = open("korel.tgz", "r")
        params["korel_dat"] = open("korel.dat", "r")
        params["korel_par"] = open("korel.par", "r")
        if (os.path.isfile("korel.tmp")):
            params["korel_tmp"] = open("korel.tmp", "r")

        result = self.POST("/jobs", params)
        print "%s %s" % (result.code, result.msg)
        result_xml = result.read()

        job_etree = etree.parse(StringIO(result_xml))
        jobid_elt = job_etree.xpath("/uws:job/uws:jobId", namespaces={"uws": "http://www.ivoa.net/xml/UWS/v1.0rc3"})
        if (jobid_elt):
            jobid = jobid_elt[0].text

        params = { "PHASE": "RUN" }
        phase_url = "/jobs/%s/phase" % jobid
        result = self.POST(phase_url, params)
        print "%s %s" % (result.code, result.msg)

        value = ""
        while (value != "COMPLETED"):
            result = self.GET(phase_url)
            result_xml = result.read()
            phase_etree = etree.parse(StringIO(result_xml))

            value_elt = phase_etree.xpath("/phase/value")
            if (value_elt):
                value = value_elt[0].text

                print "phase = %s" % value
            else:
                break

            time.sleep(1)

        filenames = [
            "korel.o-c",
            "korel.res",
            "korel.rv",
            "korel.spe",
        ]

        for filename in filenames:
            result = self.GET("/jobs/%s/results/%s" % (jobid, filename))
            if (result.code == 200):
                fo = open(filename, "w")
                fo.write(result.read())
                fo.close()

    def GET(self, action):
        url = "%s%s" % (self.service_url, action)
        print "GET %s" % url

        request = urllib2.Request(url)
        request.add_header("Accept", "text/xml")
        
        return urllib2.urlopen(request)

    def POST(self, action, params):
        url = "%s%s" % (self.service_url, action)
        print "POST %s" % url

        request = urllib2.Request(url, params)
        request.add_header("Accept", "text/xml")
        
        return urllib2.urlopen(request)

def main():
    KorelClient()

if __name__ == '__main__':
    main()
