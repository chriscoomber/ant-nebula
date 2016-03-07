#!/usr/bin/env python
# Instance: load software - running on a load generator VM
import os
import subprocess
import stat

from cloudify import ctx


def download(filename, make_executable=False):
    if filename:
        path = ctx.download_resource(filename)
        if make_executable:
            st = os.stat(path)
            os.chmod(path, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        subprocess.call(["sudo", "mv", path, directory])
        return path

# Create a directory to work in
directory = "/etc/load"
if not os.path.exists(directory):
    subprocess.call(["sudo", "mkdir", directory])
subprocess.call(["sudo", "chown", "ubuntu:ubuntu", directory])

# SIPp
download("resources/load/sipp", make_executable=True)
download("resources/load/auth_reg_client.xml")
download("resources/load/media_uac.xml")
download("resources/load/media_uas.xml")
download("resources/load/g711a.pcap")

# Scripts
download("resources/load/run_load.sh", make_executable=True)
download("resources/load/run_load_calls.sh", make_executable=True)