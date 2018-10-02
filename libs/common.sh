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

# define exit errors constants
export SUCCESS=0
export FAILURE=1
export ERROR_BAD_CALL=100
export ERROR_MISSING_DEPS=101
export ERROR_EMPTY_FILE=102
export ERROR_JUNK_FILE=103
export ERROR_MISSING_HOME=104
export ERROR_MISSING_FILE=105
export ERROR_CANNOT_CREATE=107
export ERROR_BAD_ARGUMENTS=120

# check if the HOME variable is missing
has_home() {
    if [ -z "$HOME" ]; then
        echo "Cannot find your user's home directory..."
        return $FAILURE
    fi
    return $SUCCESS
}

# output wrapper
console() {
    if [ "x$1" = "xerr" ]; then
        shift
        echo "$*" >&2
    else
        echo "$*"
    fi
}

# clean close with error code
close() {
    local EXIT_CODE=0
    if [ $# -eq 1 ]; then
        EXIT_CODE=$1
    fi
    console "Closed"
    exit $EXIT_CODE
}

# check if dependency is installed
is_installed() {
    if [ -z "$1" ]; then
        close $ERROR_BAD_CALL
    fi
    if [ -x "$(command -v $1)" ]; then
        return $SUCCESS
    fi
    return $FAILURE
}

# output an error with missing dependency
require_deps() {
    if [ $# -eq 0 ]; then
        console err "Cannot yield missing dependencies without a list of dependencies"
        close $ERROR_BAD_CALL
    fi
    console err "Notice: The following packages are required in order to continue:"
    local count=0
    for dep in $@; do
        if [ "x$dep" != "x" ]; then
            count=$(expr $count + 1)
            console err " ${count}) $dep"
        fi
    done
    console err "Please install the packages listed above and try again"
    close $ERROR_MISSING_DEPS
}


# check dependency list
check_deps() {
    local missing
    for dep in tail cat wc grep sed tr cut tee touch mkdir ls mv rm; do
        if ! is_installed $dep; then
            missing="$missing $dep"
        fi
    done
    if [ ! $# -eq 0 ]; then
        for dep in $*; do
            if ! is_installed $dep; then
                missing="$missing $dep"
            fi
        done
    fi
    if [ ! -z $missing ]; then
        require_deps $missing
    fi
}

# check if file exists or not
file_exists() {
    if [ -z "$1" ]; then
        close $ERROR_BAD_CALL
    fi
    local EXISTS=$(ls -l "$1" 2> /dev/null | wc -l)
    if [ "$EXISTS" = "0" ]; then
        return $FAILURE
    fi
    return $SUCCESS
}
