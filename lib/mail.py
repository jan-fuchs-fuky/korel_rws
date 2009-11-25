#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-

""" Mail """

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

__version__ = "0.9.5"

import os
import time
import smtplib
import mimetypes
import ConfigParser

from email.MIMEText import MIMEText
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email import encoders

MAIL_CONTENT_TYPE = "plain"
MAIL_CHARSET = "utf-8"
MAIL_FROM = "korel@sunstel.asu.cas.cz"
MAIL_USER_AGENT = "KorelRWS/%s" % __version__

class Options():
    smtp_address = None
    smtp_port = None
    smtp_user = None
    smtp_password = None
    smtp_ssl = None

def send_mail(to, subject, body, options=None, attachments=None):
    if (not options):
        options = Options()
        options.smtp_address = os.getenv("KOREL_SMTP_ADDREESS")
        options.smtp_port = int(os.getenv("KOREL_SMTP_PORT"))
        options.smtp_user = os.getenv("KOREL_SMTP_USER")
        options.smtp_password = os.getenv("KOREL_SMTP_PASSWORD")

        if (os.getenv("KOREL_SMTP_SSL") == "True"):
            options.smtp_ssl = True
        else:
            options.smtp_ssl = False

    m = MIMEMultipart()
    m["Date"] = time.strftime("%a, %d %b %Y %H:%M:%S -0000", time.gmtime())
    m["From"] = MAIL_FROM
    m["To"] = to
    m["Subject"] = subject
    m["User-Agent"] = MAIL_USER_AGENT

    m.attach(MIMEText(body.decode("utf-8").encode(MAIL_CHARSET), MAIL_CONTENT_TYPE, MAIL_CHARSET))
    
    if (attachments):
        for attachment in attachments:
            ctype, encoding = mimetypes.guess_type(attachment)
            if (ctype):
                maintype, subtype = ctype.split("/", 1)
            else:
                maintype = "text"
                subtype = "plain"

            mime_base = MIMEBase(maintype, subtype)

            fo = open(attachment, "r")
            mime_base.set_payload(fo.read())
            fo.close()

            encoders.encode_base64(mime_base)
            mime_base.add_header("Content-Disposition", "attachment", filename=os.path.basename(attachment))

            m.attach(mime_base)

    s = smtplib.SMTP(options.smtp_address, options.smtp_port)
    
    #s.set_debuglevel(1)

    if (options.smtp_ssl):
        s.starttls()

    if (options.smtp_user) and (options.smtp_password):
        s.login(options.smtp_user, options.smtp_password)

    s.sendmail(MAIL_FROM, to, m.as_string())
    s.quit()
