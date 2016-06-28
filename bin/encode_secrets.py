#!/usr/bin/env python
import base64
import os.path
import sys

if len(sys.argv) != 3 :
    print "usage: encode_secrets.py [output-secret-name] [filename]"
    sys.exit(1)

secret_name = sys.argv[1]
file_name = sys.argv[2]

if not os.path.isfile(file_name):
    print "%s is not a valid file" % file_name
    sys.exit(1)

print """\
apiVersion: v1
kind: Secret
metadata:
  name: %s
type: Opaque
data:""" % secret_name

with open(file_name, "r") as f:
    for line in f:
        key, val = line.split("=")
        key = key.lower().replace("_", "-")
        val = base64.b64encode(val.strip())
        print "  %s: %s" % (key, val)
