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
    [ ! -z "$1" ] && shift
    dataplan=$1

    if ! declare -f is_installed > /dev/null; then
        echo "Fatal: missing lib/common functions. Aborting..." && exit 1
    elif ! is_installed python; then
        echo "Error: required dependency is not installed"
        echo "Error: please install \"python\" and try again"
        exit 1
    elif ! is_installed vim; then
        echo "Error: required dependency is not installed"
        echo "Error: please install \"vim\" and try again"
        exit 1
    fi

    if [ -z "$HAP_GENERATOR" ]; then
        echo "Fatal: missing helper scripts (generator)"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ -z "$HAP_VALIDATOR" ]; then
        echo "Fatal: missing helper scripts (validator)"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ -z "$HAP_DIR" ]; then
        echo "Fatal: missing app directory"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ ! -f "$dataplan" ]; then
        echo "Notice: the file you provided does not exist"
        while true; do
            read -p "Create it now? [Yn] " answer
            if [ -z "$answer" ]; then
                answer=y
            fi
            case $answer in
                Y|y) {
                    if ! $HAP_GENERATOR "$dataplan"; then
                        echo "Error: cannot generate dataplan $dataplan"
                        exit 1
                    elif [ "$dataplan" != "$(find $dataplan -name '*.json')" ]; then
                        dataplan="${dataplan}.json"
                    fi
                    if [ ! -f "$dataplan" ]; then
                        echo "Error: dataplan was not saved to disk"
                        exit 0
                    fi
                    vim "$dataplan"
                    if ! hap "$dataplan" --verbose --save --no-cache; then
                        echo "Error: cannot run dataplan (hap error)"
                        exit 1
                    fi
                    break
                }
                ;;
                N|n) {
                    echo "Please check path to file and try again"
                    exit 1
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

    if ! $HAP_VALIDATOR "$dataplan"; then
        echo "Error: validation failed for dataplan $dataplan"
        exit 1
    fi

    result="$dataplan"
    for path in $(echo "$dataplan" | tr '/' ' '); do
        result="$path"
    done

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

# unregister one master dataplan from hap home directory
unregister () {
    [ ! -z "$1" ] && shift
    dataplan=$1

    if [ -z "$HAP_DIR" ]; then
        echo "Fatal: missing app directory"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ ! -f "$HAP_DIR/$dataplan" ]; then
        echo "Error: cannot unregister a dataplan that does not exist"
        exit 1
    fi

    echo "Warning: unregistering a master dataplan means you will no longer be able"
    echo "Warning: to add jobs or tasks with it. Current running tasks or jobs will"
    echo "Warning: not be affected."

    while true; do
        read -p "Permanently unregister ${dataplan}? [yn] " answer
        case $answer in
            Y|y) {
                if ! rm -f $HAP_DIR/$dataplan; then
                    echo "Error: cannot unregister dataplan"
                    exit 1
                else
                    echo "Dataplan has ben removed"
                    exit 0
                fi
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
}

# list all master dataplan from hap home directory
dataplans () {
    if [ -z "$HAP_DIR" ]; then
        echo "Fatal: missing app directory"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    index=1
    echo "Found $(ls "$HAP_DIR" | wc -w) master dataplan(s):"
    for file in $(ls "$HAP_DIR"); do
        echo "# $file"
        $HAP_VIEWER "$HAP_DIR/$file" | while read line; do
            echo "  $line"
        done
        index=$(expr 1 + $index)
    done
}
