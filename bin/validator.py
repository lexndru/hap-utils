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

# init
supported_datatypes = ("decimal", "integer", "percentage", "string", "text", "ascii", "bytes", "boolean")
errors_counter, validated_counter = 0, 0

# define separator and colored steps
separator = lambda: print("-" * 60)

# define validation pass
def passed(text):
    global validated_counter
    print("\033[92m  ✔️  " + text + "\033[0m")
    validated_counter += 1

# define validation pass
def failed(text):
    global errors_counter
    print("\033[91m  ❌  " + text + "\033[0m")
    errors_counter += 1

# stop generator at the first error
def fail_fast(reason):
    raise SystemExit(reason)

# check if arguments are provided
if not len(sys.argv) > 1:
    fail_fast("Nothing to validate")

# read dataplan from file
filename, dataplan = sys.argv[1], {}
try:
    with open(filename, "rb") as fd:
        dataplan = json.load(fd)
except Exception as e:
    fail_fast("Cannot open dataplan: {}".format(e))
finally:
    print("Hap! dataplan validator ready to parse {}".format(filename))

# begin tests
separator()

# test meta name
meta_name = dataplan.get("meta", {}).get("name")
if meta_name:
    passed('Found a meta name ("{}")'.format(meta_name))
else:
    failed('Missing meta name')

# check config
config = dataplan.get("config", {})
if config:
    passed("Using custom configuration")
else:
    passed("Using base configuration")

# test link
link = dataplan.get("link", "")
if link:
    passed('Link found ("{}")'.format(link))
else:
    failed("Link is missing")

# test declarations
declarations = dataplan.get("declare", {})
if len(declarations) > 0:
    # passed("{} fields are declared".format(len(declarations)))
    for k, v in declarations.iteritems():
        if not v in supported_datatypes:
            failed('Unsupported declared field "{}" as "{}"'.format(k, v))
        else:
            passed('Found a valid declared field "{}" as "{}"'.format(k, v))
else:
    failed("Dataplan has nothing declared")

# test definitions
definitions = dataplan.get("define", [])
if len(definitions) == 0:
    failed("Dataplan has nothing defined")
else:
    holder = {}
    for d in definitions:
        holder.update(d)
    common = set(holder.keys()) & set(declarations.keys())
    if common != set(declarations.keys()):
        for v in set(declarations.keys()) - common:
            failed('Dataplan has an uncovered declared field: "{}"'.format(v))
    else:
        passed("Dataplan has all declared fields covered")

# test records
records = dataplan.get("records", [])
if len(records) > 0:
    rec_errs = errors_counter
    passed("Found {} record(s) saved to dataplan".format(len(records)))
    for i, record in enumerate(records):
        declared_keys = set(declarations.keys())
        record_keys = set(record.keys())
        diff_keys = []
        for each in declared_keys ^ record_keys:
            if each.startswith("_"):
                continue  # _* are ignored by hap
            if each in declared_keys and not each in record_keys:
                failed('Record number #{} doesn\'t have declared key "{}"'.format(i+1, each))
                continue
            diff_keys.append(each)
        if len(diff_keys) != 0:
            undeclard_keys = ", ".join(diff_keys)
            failed("Record number #{} contains undeclared keys: {}".format(i+1, undeclard_keys))
        null_values = []
        for k, v in record.iteritems():
            if k.startswith("_"):
                continue
            if v is None:
                null_values.append(k)
        if len(null_values) > 0:
            incorrect_keys = ", ".join(null_values)
            failed("Record number #{} contains unexpected data for: {}".format(i+1, incorrect_keys))
    if rec_errs == errors_counter:
        passed("Validated records")
    else:
        failed("Cannot validate records")
else:
    failed("Dataplan doesn't have any records saved")

# end of tests
separator()

# validate errors
if errors_counter > 0:
    raise SystemExit("Invalid dataplan: {} problem(s) found".format(errors_counter))
print("Valid dataplan")
