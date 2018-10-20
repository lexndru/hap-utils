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
source libs/dataplan.sh
source libs/task.sh
source libs/job.sh
source libs/log.sh
source libs/manager.sh

# define constants
export HOMEPAGE=http://github.com/lexndru/hap-utils
export HAP_UTILS_VER=0.2.0
export HAP_SCRIPT=hap
export HAP_GENERATOR=hap-generator
export HAP_VALIDATOR=hap-validator
export HAP_VIEWER=hap-viewer
export HAP_MANAGER=hap-manager
export HAP_OPTIONS="register unregister dataplans check join jobs pause purge resume logs dump upgrade fix"
export HAP_HOME=$HOME/bin

# validations here
if ! has_home; then
    console err "Fatal: cannot find user's HOME directory ..."
    close $ERROR_MISSING_HOME
fi

# initialize bin directory if not exists
mkdir -p $HAP_HOME

# check if old version of wrapper exists
if [ -f "$HAP_HOME/$HAP_SCRIPT" ]; then
    console err "A script with the same name already exists in $HAP_HOME/$HAP_SCRIPT"
    while true; do
        read -p "Override existing script? [Yn] " answer
        if [ -z "$answer" ]; then
            answer="y"
        fi
        case $answer in
            Y|y) {
                mv $HAP_HOME/$HAP_SCRIPT /tmp/$HAP_SCRIPT.backup
                break
            }
            ;;
            N|n) {
                console err "Closing" && close $SUCCESS
            }
            ;;
            *) {
                console err "Cannot understand answer"
            }
            ;;
        esac
    done
fi

# prepare script
cat > $HAP_SCRIPT <<EOF
#!/bin/bash
#
EOF

# check for license file
if ! file_exists LICENSE; then
    console err "Fatal: cannot find LICENSE file ..."
    close $ERROR_MISSING_FILE
fi

# append license to wrapper
cat LICENSE | while read line; do
    echo "# $line" >> $HAP_SCRIPT
done

# start building file
cat >> $HAP_SCRIPT <<EOF

export HOMEPAGE="$HOMEPAGE"
export HAP_DIR="$HOME/.hap"
export HAP_JOBS_DIR="\$HAP_DIR/.jobs"
export HAP_JOBS_LOG="\$HAP_DIR/.log"
export HAP_JOBS_DB="\$HAP_DIR/.db"
export HAP_VERSION="$(hap --version | cut -d " " -f2)"
export HAP_BIN="$(command -v hap)"
export HAP_EMAIL="\$HAP_EMAIL"
export HAP_OPTION="\$1"
export HAP_GENERATOR="$HAP_GENERATOR"
export HAP_VALIDATOR="$HAP_VALIDATOR"
export HAP_VIEWER="$HAP_VIEWER"
export HAP_MANAGER="$HAP_MANAGER"
$(cat libs/common.sh | tail -n +$(expr $(wc -l LICENSE | cut -d " " -f1) + 3))

# validate hap instalation
if [ -z "\$HAP_BIN" ] || [ ! -f "\$HAP_BIN" ]; then
    console err "Oops... Hap! is not installed on this machine"
    read -p "Try to install? [Yn] " answer
    if [ -z "\$answer" ]; then
        answer="y"
    fi
    case \$answer in
        Y|y) {
            hap upgrade && hap fix "$HAP_HOME/$HAP_SCRIPT"
            console "Restart program and try again"
            close \$SUCCESS
        }
        ;;
        N|n) {
            console err "This program cannot continue without \"hap\""
            console err "Install it with \"hap upgrade\" or \"pip install hap\""
            console "Closing..."
            close \$FAILURE
        }
        ;;
        *) {
            console err "Cannot understand answer"
            console "Closing..."
            close \$FAILURE
        }
        ;;
    esac
fi

# print help message
if [ \$# -eq 0 ] || [ "x\$1" = "xhelp" ]; then
    echo " _                   _       _   _ _      "
    echo "| |__   __ _ _ __   / \_   _| |_(_) |___  "
    echo "| '_ \ / _' | '_ \ /  / | | | __| | / __| "
    echo "| | | | (_| | |_) /\_/| |_| | |_| | \__ \ "
    echo "|_| |_|\__,_| .__/\/   \__,_|\__|_|_|___/ "
    echo "            |_|                           "
    echo ""
    echo "Hap! utils v$HAP_UTILS_VER [installed hap \$HAP_VERSION \$(uname -op)]"
    echo ""
    echo "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
    echo "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
    echo "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
    echo "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
    echo "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
    echo "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
    echo "SOFTWARE."
    echo ""
    echo "  Please report bugs at \$HOMEPAGE"
    echo ""
    echo "Usage:"
    echo "  hap [input | option]        - Launch an utility or invoke Hap! directly"
    echo ""
    echo "Options:"
    echo "  input [flags]               - File with JSON formated dataplan"
    echo "  dataplans                   - List all master dataplans available"
    echo "  register [DATAPLAN | name]  - Register new dataplan or create it"
    echo "  unregister DATAPLAN         - Unregister existing dataplan"
    echo "  check DATAPLAN LINK         - Run once a dataplan with a link and test its output"
    echo "  jobs                        - List all background jobs"
    echo "  join DATAPLAN LINK          - Add background job with a dataplan and a link"
    echo "  purge LINK                  - Permanently remove a background job"
    echo "  pause LINK                  - Temporary pause a background job"
    echo "  resume LINK                 - Resume a paused a background job"
    echo "  dump LINK                   - Export job's stored records as tsv"
    echo "  logs                        - View recent log activity"
    echo "  upgrade                     - Upgrade Hap! to the latest version"
    echo ""
    echo "Input flags:"
    echo "  --link LINK                 - Overwrite link in dataplan"
    echo "  --save                      - Save collected data to dataplan"
    echo "  --verbose                   - Enable verbose mode"
    echo "  --no-cache                  - Disable cache link"
    echo "  --refresh                   - Reset stored records before save"
    echo "  --silent                    - Suppress any output"
    echo ""
    exit 0
fi

EOF

# presumption of innocence
success="true"

# begin switch for hap option
cat >> $HAP_SCRIPT <<EOF
# switch hap option
case \$HAP_OPTION in

EOF

# loop through all handlers
for func in $HAP_OPTIONS; do
    option="$(declare -f $func)"
    if [ -z "$option" ]; then
        console err "Fatal: Missing handler for \"${func}\" ..."
        success="false"
    fi
    handler="$(echo "$option" | tail -n +2)"
    cat >> $HAP_SCRIPT <<EOF
$(echo "$func" | tr '_' '-')) ${handler} ;; # end $func

EOF
done

# end switch
cat >> $HAP_SCRIPT <<EOF
*) { # check if option is a file and check for flags
    if [ -z "\$1" ] || [ ! -f "\$1" ]; then
        echo "Error: provided argument \"\$1\" is neither a file nor an option"
        exit 1
    fi
    \$HAP_BIN \$@
} ;; # end default
esac

# generated by Hap! utils on $(date)
EOF

# check if deploy failed
if [ "x$success" != "xtrue" ]; then
    console err "Deploy failed... cleaning up"
    rm -f $HAP_SCRIPT 2> /dev/null
    close $ERROR_BAD_ARGUMENTS
fi

# deliver hap helper generator
if ! cp bin/generator.py "$HAP_HOME/$HAP_GENERATOR"; then
    console err "Cannot install generator helper script"
    close $FAILURE
fi

# deliver hap helper validator
if ! cp bin/validator.py "$HAP_HOME/$HAP_VALIDATOR"; then
    console err "Cannot install validator helper script"
    close $FAILURE
fi

# deliver hap helper viewer
if ! cp bin/viewer.py "$HAP_HOME/$HAP_VIEWER"; then
    console err "Cannot install viewer helper script"
    close $FAILURE
fi

# deliver hap helper manager
if ! cp bin/manager.py "$HAP_HOME/$HAP_MANAGER"; then
    console err "Cannot install manager helper script"
    close $FAILURE
else
    sed -i 's|os.environ.get("HAP_BIN")|os.environ.get("HAP_BIN", "'$(command -v hap)'")|' "$HAP_HOME/$HAP_MANAGER";
    sed -i 's|os.environ.get("HAP_DIR")|os.environ.get("HAP_DIR", "'$HOME/.hap'")|' "$HAP_HOME/$HAP_MANAGER";
    sed -i 's|os.environ.get("HAP_JOBS_DB")|os.environ.get("HAP_JOBS_DB", "'$HOME/.hap/.db'")|' "$HAP_HOME/$HAP_MANAGER";
    sed -i 's|os.environ.get("HAP_JOBS_DIR")|os.environ.get("HAP_JOBS_DIR", "'$HOME/.hap/.jobs'")|' "$HAP_HOME/$HAP_MANAGER";
fi

# check if user path contains script
home_path="false"
for path in $(echo $PATH | tr ':' ' '); do
    if [ "x$path" = "x$HAP_HOME" ]; then
        home_path="true"
    fi
done

# announce missing path
if [ "x$home_path" != "xtrue" ]; then
    console err "The directory \"$HAP_HOME\" is not part of your \$PATH"
    console err "Please consider adding it and try again"
    close $FAILURE
fi

# prepare private hap folder in user directory
if ! mkdir -p ${HOME}/.${HAP_SCRIPT}; then
    console err "Cannot create private folder in user directory"
    console err "Please check permissions and try again"
    close $FAILURE
fi

# deliver script
chmod +x $HAP_SCRIPT && mv $HAP_SCRIPT "$HAP_HOME/$HAP_SCRIPT"
console "Successfully installed utils. Try \"hap\" in a terminal"

# add manager cronjob
if [ "$(crontab -l | grep "$HAP_HOME/$HAP_MANAGER" | wc -l)" = "0" ]; then
    (crontab -l; echo "* * * * * $HAP_HOME/$HAP_MANAGER >> $HOME/.hap/.log 2>&1") | crontab -
fi
