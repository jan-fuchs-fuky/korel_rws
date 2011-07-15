#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
from subprocess import Popen, PIPE

def dpkg_S(file):
    dpkg_pipe = Popen("dpkg -S %s" % file, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    retcode = dpkg_pipe.wait()

    if (retcode == 0):
        pkg_name = dpkg_pipe.stdout.readline().split(":")[0]
        return pkg_name
    else:
        print "%s not found" % file
        print >>sys.stderr, dpkg_pipe.stderr.read()

    return None

if (len(sys.argv) != 2):
    print "Usage: %s modules.list" % sys.argv[0]
    sys.exit(0)

fo = open(sys.argv[1], "r")

for module_name in fo.readlines():
    module_name = module_name.strip()

    try:
        exec("import %s" % module_name)
    except:
        print "WARNING: skipping %s" % module_name
        continue

    # skip built-in module
    if (repr(sys.modules[module_name]).find("built-in") != -1):
        continue

    exec("module_file = %s.__file__" % module_name)

    if (module_file[-4:] == ".pyc"):
        module_file = module_file[:-1]

    while (1):
        if (os.path.islink(module_file)):
            module_file_tmp = os.readlink(module_file)
            if (module_file_tmp[0] != "/"):
                module_file_tmp = os.path.abspath("%s/%s" % (os.path.dirname(module_file), module_file_tmp))

            module_file = module_file_tmp
        else:
            break

    pkg_name = dpkg_S(module_file)
    if (pkg_name):
        print "%s => %s" % (module_name, pkg_name)

fo.close()
