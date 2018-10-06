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

import re
import sys
import json

from urlparse import urlparse


# crash scripts trying to import the generator
assert __name__ == "__main__", "Cannot use file as a module"

# url regex validator
URL = re.compile(
    r"^(?:https?)://"
    r"(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|"
    r"localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(?::\d+)?"
    r"(?:/?|[/?]\S+)$", re.IGNORECASE)

# set all top-level supported fields
separator = lambda: print(" " * 60)
required_fields = {
    "meta": dict,
    "config": dict,
    "define": list,
    "declare": dict,
    "records": list,
    "link": unicode,
}

# prevent ^C raise an exception
def safe_output(func):
    def wrapper(*args, **kwargs):
        try:
            func(*args, **kwargs)
        except KeyboardInterrupt:
            print("")
            separator()
            print("Cleaning up ...")
        else:
            separator()
            print("Saving dataplan ...")
    return wrapper

# stop generator at the first error
def fail_fast(reason):
    raise SystemExit(reason)

# announce user what's about to happen
print("Hap! dataplan generator ready (exit with ^C)")
separator()
print("The following steps will guide you through the process")
print("of creating and validating a working dataplan for Hap!")
separator()

# initialize dataplan
dataplan = {k:t() for k, t in required_fields.iteritems()}

@safe_output
def main(index=1):
    fmt = lambda text: " {}) {}".format(index, text)

    # meta name for dataplan
    dataplan_name = "???"

    # grab a link
    link = ""
    print("A dataplan is like a blueprint for an HTML page. The first")
    print("thing one must provide to obtain a working dataplan is an ")
    print("URL of the HTML desired to be parsed.")
    print("The validation is at a minimum level so plase double check")
    print("to be sure you typed the URL correct.")
    while not link:
        link = raw_input(fmt("Enter an URL: "))
        if not link:
            print("    Unexpected empty field! You must provide an URL to continue")
        elif URL.match(link) is None:
            print("    Malformed URL detected! Please type correct URL to continue")
            link = ""
    try:
        dataplan_name = urlparse(link).netloc
    except Exception as e:
        fail_fast("Bad URL provided: {}".format(e))
    print("    OK!")
    separator()
    dataplan.update({"link": link})
    index += 1

    # grab desired output
    print("The purpose of a dataplan is to harvest data from an HTML")
    print("document and describe patterns that can be used to gather")
    print("data from any URL pointing to a similar dataplan.")
    print("Add the fields you want to harvest as FieldName = DataType")
    print('where "FieldName" can be anything and "DataType" can be one')
    print("of the following:")
    print("     decimal              - for currency")
    print("     integer, percentage  - for numbers")
    print("     string, text, ascii  - for unicode or ascii strings")
    print("     bytes                - for raw bytes sequences")
    print("     boolean              - for booleans")
    print("E.g. harvest the title of a book and its price")
    print("     Declare field: title = text            ")
    print("     Declare field: price = decimal         ")
    print("Leave the prompt empty to continue. At least one field is")
    print("required to move to the next step.")
    supported_datatypes = ("decimal", "integer", "percentage", "string", "text", "ascii", "bytes", "boolean")
    fields = []
    while True:
        field = raw_input(fmt("Declare field: "))
        if not field and len(fields) > 0:
            break
        if not field:
            print("    Unexpected empty field! You must provide at least one field to continue")
            continue
        if not "=" in field:
            print("    Invalid field! Follow the pattern FieldName = DataType e.g. book_title = text")
            continue
        fn, dt = field.split("=", 1)
        fn, dt = fn.strip(), dt.strip()
        if not fn:
            print("    Empty field name! Provide a non-empty string for the name e.g. book_title")
            continue
        if not dt:
            print("    Empty field type! Provide one of the supported field data types from above")
            continue
        if dt not in supported_datatypes:
            print("    Unsupported field type! Choose one of the supported field data types from above")
            continue
        fields.append((fn, dt))
    print("    OK!")
    separator()
    dataplan.update({"declare": {k: v for k, v in fields}})
    index += 1

    # setup a custom configuration
    print("You can configure a dataplan to use different HTTP headers")
    print("on its requests to harvest. Setting a header is similar to")
    print("declaring a field. Follow the pattern HeaderField = Value ")
    print("where HeaderField should be a valid HTTP header and Value ")
    print("can be any supported value for the provided header field. ")
    print("E.g. set a custom user-agent")
    print("     Set header: User-Agent = MyCustomUserAgent           ")
    print("Leave the prompt empty to continue.")
    headers = []
    while True:
        header = raw_input(fmt("Set header: "))
        if not header:
            break
        if not "=" in header:
            print("    Invalid format! Follow the pattern HeaderField = Value")
            continue
        key, val = header.split("=", 1)
        key, val = key.strip(), val.strip()
        if not key:
            print("    Empty header field! Provide a non-empty string for the header field")
            continue
        if not val:
            print("    Empty header value! Provide a non-empty string for the header value")
            continue
        headers.append((key, val))
    print("    OK!")
    separator()
    dataplan.update({"config": {"headers": {k: v for k, v in headers}}})
    index += 1

    # set a name
    print("A dataplan supports meta fields. Every dataplan should have")
    print("a human readable alias for easy recognition, especially for")
    print("master dataplans (like the one you're generating).")
    print("An alias has been auto generated from the URL provided at")
    print("step 1). If you don't like it, type a new one.")
    meta_name = raw_input(fmt("Enter a name [{}]: ".format(dataplan_name)))
    if len(meta_name.strip()) > 0:
        dataplan_name = meta_name.strip()
    print("    OK!")
    separator()
    dataplan.update({"meta": {"name": dataplan_name}})
    index += 1

    # prepare definitions
    print("Finally, a dataplan must define step by step the process of")
    print("gathering data for each declared field at step 2). The final")
    print("output is saved under a \"records\" label as a map of fields")
    print("with the apropriate values converted as the declarations are")
    print("set. Please consult the documentation for more details.")
    print("     https://github.com/lexndru/hap-utils")
    print("The generator will prepare all definitions, but it's up to")
    print("you to write the gathering process for a specific DOM.")
    print("The following methods are available to use:")
    print("     query, query_css     - evaluate CSS selector")
    print("     query_xpath          - evaluate XPath expression")
    print("     pattern              - extract groups from regex")
    print("     replace              - replace regex pattern with string")
    print("     remove               - remove regex pattern from results")
    print("     glue                 - concatenate variables and strings")
    print("You can also use a plan string to define raw \"as is\" values")
    print('e.g. "name" : "Book Title" ')
    print('     "name" : { "query": "h1.title" } ')
    dataplan.update({"define": [{k: [{"...": "..."}]} for k, _ in fields]})
    separator()

    # confirm to save
    print("Save the dataplan to disk.")
    filename = ""
    if len(sys.argv) > 1:
        filename = "".join(sys.argv[1:])
    while not filename:
        filename = raw_input(fmt("Filename [{}]: ".format(dataplan_name)))
        if len(filename.strip()) > 0:
            if re.match(r"[a-zA-Z0-9_\.\-]+", filename) is None:
                print("    Invalid filename! Use the following characters: a-z, A-Z, 0-9, dot, dash and underscore")
                filename = ""
                continue
            filename = filename.strip()
        else:
            filename = dataplan_name.strip()
    if not filename.endswith(".json"):
        filename += ".json"
    print("    OK!")

    # write to disk
    try:
        with open(filename, "wb") as fd:
            json.dump(dataplan, fd, indent=4)
    except Exception as e:
        fail_fast("Cannot write to disk: {}".format(e))


if __name__ == "__main__":
    main()
