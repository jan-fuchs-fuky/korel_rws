""" Mail """

#
# Author: Jan Fuchs <fuky@sunstel.asu.cas.cz>
# $Date$
# $Rev$
#

__version__ = "0.9.1"

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
        cfg = ConfigParser.RawConfigParser()
        cfg.read("%s/../etc/korel_rws.cfg" % os.path.dirname(__file__))

        options = Options()

        options.smtp_address = cfg.get("smtp", "addresss")
        options.smtp_port = cfg.getint("smtp", "port")
        options.smtp_user = cfg.get("smtp", "user")
        options.smtp_password = cfg.get("smtp", "password")
        options.smtp_ssl = cfg.getboolean("smtp", "ssl")

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
