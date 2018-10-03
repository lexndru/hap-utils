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

# launch Hap! self-upgrade process
upgrade() {
    if ! declare -f is_installed > /dev/null; then
        echo "Fatal: missing lib/common functions. Aborting..." && exit 1
    fi
    if ! is_installed pip; then
        echo "Error: required dependency is not installed"
        echo "Error: please install \"pip\" and try again"
        exit 1
    fi
    pip install -U hap
}

# attempt to fix missing hap binary path
fix() {
    if ! command -v whereis; then
        echo "Fatal: missing whereis from util-linux package" && exit 1
    fi
    if [ -z "$1" ]; then
        echo "Error: missing current hap deployed path" && exit 1
    fi
    local hap=$1
    local pos=2  # cmd: bin1 bin2 bin3 ...
    while true; do
        local bin=$(whereis -b hap | cut -d " " -f$pos)
        if [ -z "$bin" ]; then
            break
        fi
        if [ "x$bin" != "x$hap" ]; then
            sed -E -i "s/export HAP_BIN=.*/export HAP_BIN=$bin/g" "$hap"
            break
        fi
        pos=$(expr $pos + 1)
    done
}
