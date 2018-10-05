#!/usr/bin/env python
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


# init
supported_datatypes = ("decimal", "integer", "percentage", "string", "text", "ascii", "bytes", "boolean")
errors = []

# stop generator at the first error
def fail_fast(reason):
    raise SystemExit(reason)

# check if arguments are provided
if not len(sys.argv) > 1:
    fail_fast("Nothing to validate")

# loop through all dataplans and validate
for filename in sys.argv[1:]:
    dataplan = {}

    # read dataplan from file
    try:
        with open(filename, "rb") as fd:
            dataplan = json.load(fd)
    except Exception as e:
        fail_fast("Cannot open dataplan: {}".format(e))

    # test meta name
    meta_name = dataplan.get("meta", {}).get("name")
    if meta_name:
        print('Attempt to validate "{}" ...'.format(meta_name))
    else:
        print("Attempt to validate dataplan without name ...")
        errors.append("Dataplan doesn't have a name")

    # check config
    config = dataplan.get("config", {})
    if config:
        print("Dataplan has a custom configuration")
    else:
        print("Dataplan is using base configuration")

    # test link
    link = dataplan.get("link", "")
    if link:
        print("Alright! Link found: {}".format(link))
    else:
        print("Failure! Link is missing ...")
        errors.append("Dataplan doesn't have a link")

    # test declarations
    declarations = dataplan.get("declare", {})
    if len(declarations) > 0:
        print("Good! {} fields are declared".format(len(declarations)))
        index = 1
        for k, v in declarations.iteritems():
            print("  {}) {} ({})".format(index, k, v))
            index += 1
            if not v in supported_datatypes:
                errors.append('Dataplan has an unsupported declared type "{}" for "{}"'.format(v, v))
    else:
        print("Failure! Nothing is declared ...")
        errors.append("Dataplan doesn't output data because of missing declarations")

    # test definitions
    definitions = dataplan.get("define", [])
    if len(definitions) > 0:
        print("Good! {} steps are defined".format(len(definitions)))
    else:
        print("Failure! Nothing is defined ...")
        errors.append("Dataplan doesn't output data because of missing definitions")
    holder = {}
    for d in definitions:
        holder.update(d)
    common = set(holder.keys()) & set(declarations.keys())
    if common != set(declarations.keys()):
        print("Not all declared fields are covered")
        for v in set(declarations.keys()) - common:
            errors.append('Dataplan has an uncovered declared field: "{}"'.format(v))
    else:
        print("All declared fields are covered")

    # test records
    records = dataplan.get("records", [])
    if len(records) > 0:
        print("Found {} records".format(len(records)))
        for index, record in enumerate(records):
            print("Testing record #{}".format(index))
            for k, v in record.iteritems():
                print("  {} => {}".format(k, v))
    else:
        print("No records are found ...")
        errors.append("Dataplan doesn't have any records saved")

# validate errors
print("-" * 80)
if len(errors) == 0:
    print("Perfect! No errors found ...")
else:
    print("Oops! {} error(s) found".format(len(errors)))
    for index, err in enumerate(errors):
        print("  {}) {}".format(index+1, err))
    print("Please correct these problems ...")
