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

source libs/common.sh

# define constants
export HOMEPAGE=http://github.com/lexndru/hap-utils
export HAP_SCRIPT=hap
export HAP_PATH=$HOME/bin/$HAP_SCRIPT

# validations here
if ! has_home; then
    console err "Fatal: cannot find user's HOME directory ..."
    close $ERROR_MISSING_HOME
fi

# check if wrapper is installed
if [ ! -f "$HAP_PATH" ]; then
    console err "Cannot find hap wrapper in user home directory"
    console err "It may not be installed..."
    close $FAILURE
fi

# confirm and remove it
while true; do
    read -p "Remove Hap! Utils from system? [yN] " answer
    if [ -z "$answer" ]; then
        answer="n"
    fi
    case $answer in
        Y|y) {
            console "Permanently removed"
            console "Closing now..."
            rm -f $HAP_PATH
            break
        }
        ;;
        N|n) {
            console "Nothing to do..."
            break
        }
        ;;
        *) {
            console err "Cannot understand answer"
        }
        ;;
    esac
done
