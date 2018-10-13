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

# view entire verbose log file
logs() {
    if ! declare -f is_installed > /dev/null; then
        echo "Fatal: missing lib/common functions. Aborting..." && exit 1
    fi
    if ! is_installed less; then
        echo "Error: required dependency is not installed"
        echo "Error: please install \"less\" and try again"
        exit 1
    fi

    if [ -z "$HAP_JOBS_LOG" ]; then
        echo "Fatal: missing internal jobs log file"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    elif [ ! -f "$HAP_JOBS_LOG" ]; then
        echo "Error: cannot find log file"
        exit 1
    fi

    less +G $HAP_JOBS_LOG
}
