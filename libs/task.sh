#!/bin/bash
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

# check if a link is working with a dataplan
check() {
    [ $# -gt 2 ] && shift
    dataplan=$1
    link=$2

    if [ -z "$dataplan" ]; then
        echo "Error: missing dataplan"
        echo "Error: please provide first argument as dataplan"
        exit 1
    fi

    if [ -z "$link" ]; then
        echo "Error: missing link"
        echo "Error: please provide second argument as link"
        exit 1
    fi

    if [ -z "$HAP_BIN" ]; then
        echo "Fatal: missing hap binary path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ -z "$HAP_DIR" ]; then
        echo "Fatal: missing app directory"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ ! -f "$HAP_DIR/$dataplan" ]; then
        echo "Error: cannot check a dataplan that does not exist"
        exit 1
    fi

    if ! $HAP_BIN "$HAP_DIR/$dataplan" --no-cache --link $link; then
        echo "Error: unable to check dataplan with link $link"
    fi
}
