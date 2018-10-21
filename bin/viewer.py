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

from __future__ import print_function

import sys
import json


# crash scripts trying to import the generator
assert __name__ == "__main__", "Cannot use file as a module"

# check if arguments are provided
if not len(sys.argv) > 1:
    raise SystemExit("Nothing to view")

# read dataplan from file
filename, dataplan = sys.argv[1], {}
try:
    with open(filename, "rb") as fd:
        dataplan = json.load(fd)
except Exception as e:
    raise SystemExit("Cannot open dataplan: {}".format(e))

# get declarations
declarations = dataplan.get("declare", {})

# find max length of key declaration
max_key_len = max([len(k) for k in declarations.keys()])

# get first record
first_record = dataplan.get("records", []).pop(0)

# viewer formatter
def view(field, type, sample):
    global max_key_len
    line_fmt = u"{:<" + unicode(max_key_len) + u"} | {:<10} | {}"
    print(line_fmt.format(field, type, sample).encode("utf-8"))

# viewer separator
def separator():
    global max_key_len
    line_sep = ("=" * (max_key_len+1)) + "|" + ("=" * 12) + "|" + ("=" * 60)
    print(line_sep)

# display table-like view
view("Field", "Type", "Sample")
separator()
for k, v in declarations.iteritems():
    view(k, v, first_record.get(k))
