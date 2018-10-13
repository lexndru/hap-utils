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

# create a new background job for a link with a dataplan
join() {
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

    if [ -z "$HAP_JOBS_DIR" ]; then
        echo "Fatal: missing internal jobs directory"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ -z "$HAP_JOBS_LOG" ]; then
        echo "Fatal: missing internal jobs log file"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ "$HAP_DIR/$dataplan" != "$(find $HAP_DIR/$dataplan -name '*.json' 2> /dev/null)" ]; then
        dataplan="${dataplan}.json"
    fi

    if [ ! -f "$HAP_DIR/$dataplan" ]; then
        echo "Error: cannot check a dataplan that does not exist"
        exit 1
    fi

    if ! mkdir -p "$HAP_JOBS_DIR"; then
        echo "Error: cannot create internal jobs directory"
        exit 1
    fi

    if [ -z "$HAP_MANAGER" ]; then
        echo "Fatal: missing hap manager path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    if [ -z "$HAP_VALIDATOR" ]; then
        echo "Fatal: missing hap validator path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    echo "Notice: always run an integrity check before adding a job"
    echo "Notice: for the appropriate dataplan structure and please"
    echo "Notice: evaluate the correctness of the results"

    if $HAP_VALIDATOR "$HAP_DIR/$dataplan"; then
        result="$($HAP_MANAGER join $dataplan $link)"
        if [ ! $? -eq 0 ]; then
            echo "$result" | tr -d '\n'
            exit 1
        else
            message="$(echo "$result" | cut -d ":" -f1)"
            job_file="$(echo "$result" | cut -d ":" -f2)"
            if ! $HAP_BIN $job_file --verbose --refresh --no-cache --save 2>> $HAP_JOBS_LOG; then
                echo "Failed to run $job_file"
                exit 1
            fi
            echo $message
        fi
    fi

}

jobs() {
    if [ -z "$HAP_MANAGER" ]; then
        echo "Fatal: missing hap manager path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi
    $HAP_MANAGER jobs
}

pause() {
    [ $# -gt 1 ] && shift
    link=$1

    if [ -z "$link" ]; then
        echo "Error: missing link"
        echo "Error: please provide second argument as link"
        exit 1
    fi

    if [ -z "$HAP_MANAGER" ]; then
        echo "Fatal: missing hap manager path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    $HAP_MANAGER pause $link
}

purge() {
    [ $# -gt 1 ] && shift
    link=$1

    if [ -z "$link" ]; then
        echo "Error: missing link"
        echo "Error: please provide second argument as link"
        exit 1
    fi

    if [ -z "$HAP_MANAGER" ]; then
        echo "Fatal: missing hap manager path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    $HAP_MANAGER purge $link
}

resume() {
    [ $# -gt 1 ] && shift
    link=$1

    if [ -z "$link" ]; then
        echo "Error: missing link"
        echo "Error: please provide second argument as link"
        exit 1
    fi

    if [ -z "$HAP_MANAGER" ]; then
        echo "Fatal: missing hap manager path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    $HAP_MANAGER resume $link
}

dump() {
    [ $# -gt 1 ] && shift
    link=$1

    if [ -z "$link" ]; then
        echo "Error: missing link"
        echo "Error: please provide second argument as link"
        exit 1
    fi

    if [ -z "$HAP_MANAGER" ]; then
        echo "Fatal: missing hap manager path"
        echo "Fatal: please reinstall utils and try again"
        exit 1
    fi

    $HAP_MANAGER dump $link
}
