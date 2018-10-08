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
add_job() {
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

    if [ ! -f "$HAP_DIR/$dataplan" ]; then
        echo "Error: cannot check a dataplan that does not exist"
        exit 1
    fi

    if ! mkdir -p "$HAP_JOBS_DIR"; then
        echo "Error: cannot create internal jobs directory"
        exit 1
    fi

    echo "Notice: always run an integrity check before adding a job"
    echo "Notice: for the appropriate dataplan structure and please"
    echo "Notice: evaluate the correctness of the results"

    job_link=$(echo "$link" | sed -En 's/\W+/_/pg')
    python - <<EOF
import json as j;
f=open('$HAP_DIR/$dataplan');
d=j.load(f);
f.close();
d.update({'link':'$link'});
f=open('$HAP_JOBS_DIR/$job_link'+'.json', 'w');
j.dump(d, f, indent=4);
f.close();
EOF

    job_file="$HAP_JOBS_DIR/${job_link}.json"
    job_log="$HAP_JOBS_DIR/${job_link}.log"
    job_preview="$($HAP_BIN $job_file --no-cache --refresh --save)"
    if [ ! $? -eq 0 ] ; then
        echo "Error: unable to run fresh dataplan for job $job_link"
    fi

    echo
    echo "Preview of job results"
    echo "--------------------------------------------------------------------"
    echo "$job_preview"
    echo "--------------------------------------------------------------------"
    echo

    properties="$(python -c "import json as j; print(', '.join([k for k in j.loads('''$job_preview''').keys() if k[0]!='_'])) ")"

    read -p "Choose one property as the title of the job (e.g. $properties): " title
    while true; do
        valid_title="false"
        for each in $(echo $properties | tr -d ','); do
            if [ "x$each" = "x$title" ]; then
                valid_title="true"
                break
            fi
        done
        if [ "$valid_title" = "false" ]; then
            echo "Warning: \"$title\" is not a valid title..."
            read -p "(choose one from the following $properties): " title
        else
            break
        fi
    done

    job_title="$(python -c "import json as j; print(j.loads('''$job_preview''').get('$title'))")"

    echo -e "${job_title}\t\t${job_link}" >> $HAP_JOBS_FILE
    echo "Successfully added new background job"
    echo "  Job title: $job_title"
    echo "   Dataplan: $dataplan"
    echo "       Link: $link"
    echo "   Interval: $interval"

    # echo "$HAP_BIN $job_file --save --verbose --no-cache >> $job_log"
}

list_jobs() {
    echo "Unsupported option, yet"
}

pause_job() {
    echo "Unsupported option, yet"
}

delete_job() {
    echo "Unsupported option, yet"
}
