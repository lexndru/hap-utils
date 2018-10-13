#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright 2018 Alexandru Catrina
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

import json

from SimpleXMLRPCServer import SimpleXMLRPCServer


# Create server
server = SimpleXMLRPCServer(("localhost", 23513))

# Check if all fields are non-null
def non_null(job_dataplan):
    with open(job_dataplan) as fd:
        ctx = json.load(fd)
    for record in ctx.get("records", []):
        for field, value in record.iteritems():
            if value is None:
                print("Job might be outdated ({} is null)".format(field))

# Register function as "ping" callback
server.register_function(non_null, "ping")

# Run the server's main loop
server.serve_forever()
