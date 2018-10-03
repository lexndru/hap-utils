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

# register new master dataplan into hap home directory
register () {
    if ! declare -f is_installed > /dev/null; then
        echo "Fatal: missing lib/common functions. Aborting..." && exit 1
    fi
    if ! is_installed python; then
        echo "Error: required dependency is not installed"
        echo "Error: please install \"python\" and try again"
        exit 1
    fi
    dataplan=$2
    script="import json as j;f=open('$dataplan');d=j.load(f);print(d.get('meta', {}).get('name'));f.close();"
    result=$(python -c "$script" 2> /tmp/.hap.log)
    if [ ! $? -eq 0 ] || [ -z "$result" ]; then
        echo "Error: invalid file parameter provided" && exit 1
    fi
    if [ "x$result" = "xNone" ]; then
        echo "Warning: no meta.name field found in dataplan"
        echo "Warning: add a name and try again"
        exit 1
    fi
    if [ -f "$HAP_DIR/$result" ]; then
        echo "Warning: dataplan name conflict for \"$result\""
        while true; do
            read -p "Override it? [yn] " answer
            case $answer in
                Y|y) {
                    echo "Overriding..."
                    break
                }
                ;;
                N|n) {
                    echo "Doing nothing..."
                    exit 0
                }
                ;;
                *) {
                    echo "Cannot understand answer..."
                    echo "(use y for YES or n for NO)"
                }
                ;;
            esac
        done
    fi
    if ! cp "$dataplan" "$HAP_DIR/$result"; then
        echo "Error: cannot register dataplan $dataplan as \"$result\""
        exit 1
    fi
    echo "New master dataplan has been registered!"
    echo "You can use \"$result\" to add jobs or tasks"
}

unregister () {
    echo "Unsupported option, yet"
}

dataplans () {
    echo "Unsupported option, yet"
}
