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

export HAP_SCRIPT=hap

# validations here

cat > $HAP_SCRIPT <<EOF
#!/bin/bash

export HOMEPAGE=http://github.com/lexndru/hap-utils
export HAP_VERSION=$(hap --version | cut -d " " -f2)
export HAP_BIN=$(command -v hap)
export HAP_EMAIL=\$HAP_EMAIL

if [ \$# -eq 0 ] || [ "x\$1" = "xhelp" ]; then
    echo " _                   _     _          _ _      "
    echo "| |__   __ _ _ __   / \___| |__   ___| | |     "
    echo "| '_ \ / _\\\` | '_ \ /  / __| '_ \\ / _ \\ | |  "
    echo "| | | | (_| | |_) /\\_/\\__ \\ | | |  __/ | |  "
    echo "|_| |_|\\__,_| .__/\\/  |___/_| |_|\\___|_|_|  "
    echo "            |_|                                "
    echo ""
    echo "Hap! shell utils [\$HAP_VERSION \$(uname -op)]"
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
    echo "  hap [option | flags]        - Launch an utility or invoke Hap! directly"
    echo ""
    echo "Options:"
    echo "  register [DATAPLAN]         - Register new dataplan or create it"
    echo "  unregister DATAPLAN         - Unregister existing dataplan"
    echo "  dataplans                   - List all master dataplans available"
    echo "  test DATAPLAN JOB_LINK      - Run once a dataplan with a link and test its output"
    echo "  add-job DATAPLAN JOB_LINK   - Add a new background job with a dataplan and a link"
    echo "  list-jobs                   - List all background jobs"
    echo "  pause-job                   - Temporary pause a background job"
    echo "  delete-job                  - Permanently delete a background job"
    echo "  logs JOB                    - View recent log activity"
    echo "  upgrade                     - Upgrade Hap! to the latest version"
    echo ""
    echo "Flags:"
    echo "  input                       - your JSON formated dataplan input"
    echo "  -h, --help                  - show this help message and exit"
    echo "  --sample                    - generate a sample dataplan"
    echo "  --link LINK                 - overwrite link in dataplan"
    echo "  --save                      - save collected data to dataplan"
    echo "  --verbose                   - enable verbose mode"
    echo "  --no-cache                  - disable cache link"
    echo "  --refresh                   - reset stored records before save"
    echo "  --silent                    - suppress any output"
    echo "  --version                   - print version number"
    echo ""
    exit 0
fi

echo "hello"
EOF

chmod +x $HAP_SCRIPT
