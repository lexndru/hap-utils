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
export HAP_WORKSTATION=hap-workstation
export WORKSTATION_PATH=/opt/${HAP_SCRIPT}
export SYSTEMD_UNIT_FILE_PATH=/lib/systemd/system

# annouce user about next steps
console "Installing a workstation requires root privileges. Make sure you have"
console "previously installed hap core and hap utils otherwise the workstation"
console "will not work properly."

# ask for path to rpc script
console "Please type the absolute path to your RPC server application below."
read -p "Path: " rpc_server
if [ -z "$rpc_server" ]; then
    console err "Error: path is empty!"
    close $FAILURE
elif [ ! -f "$rpc_server" ]; then
    console err "Error: path to file is invalid!"
    close $FAILURE
fi

# copy user file
mkdir -p "$WORKSTATION_PATH" && cp "$rpc_server" "$WORKSTATION_PATH/$HAP_WORKSTATION"
if [ ! $? -eq 0 ]; then
    console err "Error: failed to copy your RPC application"
    close $FAILURE
fi

# make application executable
if ! chmod 500 "$WORKSTATION_PATH/$HAP_WORKSTATION"; then
    console err "Error: failed to change permissions for RPC application"
    close $FAILURE
fi

# copy workstation systemd unit file
cat > $SYSTEMD_UNIT_FILE_PATH/${HAP_WORKSTATION}.service <<EOL
[Unit]
Description=Hap! Workstation ($(uname -n))
After=network.target

[Service]
User=$(whoami)
Environment=HAP_PORT=23513
ExecStart=$WORKSTATION_PATH/$HAP_WORKSTATION
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
WorkingDirectory=$WORKSTATION_PATH
SyslogIdentifier=$HAP_WORKSTATION

[Install]
WantedBy=multi-user.target
Alias=${HAP_WORKSTATION}.service
EOL

# train user
console "Workstation installed on local machine."
console "You can now enable your service and control it through systemd:"
console "  service ${HAP_WORKSTATION} {start|restart|stop|status}"
console "Absolute path to workstation:"
console "  $WORKSTATION_PATH/$HAP_WORKSTATION"
console "Keep in mind that any changes require a restart"
