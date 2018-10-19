#!/usr/bin/env python
# -*- coding: utf-8 -*-
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

from __future__ import print_function

import io
import os
import sys
import json
import time
import subprocess
import xmlrpclib
import socket

try:
    import sqlite3
except Exception as e:
    raise SystemExit("Please install sqlite3 module")


# crash scripts trying to import the generator
assert __name__ == "__main__", "Cannot use file as a module"

# detect stdin
__stdin__ = sys.stdin.fileno()

# define rpc address
RPC_ADDRESS = r"http://localhost:23513"

# define hap binary path
HAP_BIN_PATH = os.environ.get("HAP_BIN")
if not HAP_BIN_PATH or len(HAP_BIN_PATH.strip()) == 0:
    raise SystemExit("Missing HAP_BIN environment parameter")

# define datavase path
JOBS_DATABASE = os.environ.get("HAP_JOBS_DB")
if not JOBS_DATABASE or len(JOBS_DATABASE.strip()) == 0:
    raise SystemExit("Missing HAP_JOBS_DB environment parameter")

# define db directory
JOBS_DIRECTORY = os.environ.get("HAP_JOBS_DIR")
if not JOBS_DIRECTORY or len(JOBS_DIRECTORY.strip()) == 0:
    raise SystemExit("Missing HAP_JOBS_DIR environment parameter")

# define dataplans dir
DATAPLANS_DIR = os.environ.get("HAP_DIR")
if not DATAPLANS_DIR or len(DATAPLANS_DIR.strip()) == 0:
    raise SystemExit("Missing HAP_DIR environment parameter")

# fetch all registered dataplans
def dataplans():
    for dataplan in os.listdir(DATAPLANS_DIR):
        filepath = os.path.join(DATAPLANS_DIR, dataplan)
        if not os.path.isfile(filepath) or not dataplan.endswith(".json"):
            continue
        yield dataplan

# parse job fields
def parse_job(job, retval):
    link, dataplan, job_file, interval, _, _, start_date, pause_date, last_run, _ = job
    if retval == "link":
        return link
    elif retval == "dataplan":
        return dataplan
    elif retval == "job_file":
        return job_file
    elif retval == "interval":
        return interval
    elif retval == "start_date":
        return start_date
    elif retval == "pause_date":
        return pause_date
    elif retval == "last_run":
        return last_run
    raise SystemExit("Undefined return value after parsing job")


class Jobs(object):

    fields = (
        ("link",       "text primary key"),
        ("dataplan",   "text"),
        ("job_file",   "text"),
        ("interval",   "integer"),  # hours
        ("callback",   "text"),
        ("comment",    "text"),
        ("start_date", "text"),
        ("pause_date", "text"),
        ("last_run",   "text"),
        ("status",     "text"),
    )

    def __init__(self, name="jobs"):
        self.dbname = name
        self.db = sqlite3.connect(JOBS_DATABASE)

    def initialize(self):
        fields = ",".join(["{} {}".format(k, v.upper()) for k, v in self.fields])
        self.cursor.execute(r"CREATE TABLE IF NOT EXISTS {} ({})".format(
            self.dbname, fields))
        self.db.commit()

    def insert(self, dataplan, job_file, link):
        fields = "dataplan, job_file, link, interval"
        values = [dataplan, job_file, link, 24]
        self.cursor.execute(r"INSERT INTO {} ({}, start_date) VALUES ({},CURRENT_TIMESTAMP)".format(
            self.dbname, fields, ",".join(["?" for _ in values])), values)
        self.db.commit()

    def delete(self, link):
        self.cursor.execute(r"DELETE FROM {} WHERE link=?".format(
            self.dbname), [link])
        self.db.commit()

    def ping(self, link):
        self.cursor.execute(r"UPDATE {} SET last_run=CURRENT_TIMESTAMP WHERE link=?".format(
            self.dbname), [link])
        self.db.commit()

    def select(self):
        self.cursor.execute(r"SELECT * FROM {}".format(self.dbname))
        self.db.commit()
        return self.cursor.fetchall()

    def select_fifo24(self):
        self.cursor.execute(
            r"SELECT * FROM {} "
            r"WHERE pause_date IS NULL AND "
            r"(last_run IS NULL OR DATETIME('now', '-1 day') > last_run)".format(self.dbname))
        self.db.commit()
        return self.cursor.fetchall()

    def get(self, link):
        self.cursor.execute(r"SELECT * FROM {} WHERE link=?".format(
            self.dbname), [link])
        self.db.commit()
        return self.cursor.fetchone()

    def pause_now(self, link):
        self.cursor.execute(r"UPDATE {} SET pause_date=CURRENT_TIMESTAMP WHERE link=?".format(
            self.dbname), [link])
        self.db.commit()

    def resume_now(self, link):
        self.cursor.execute(r"UPDATE {} SET pause_date=NULL WHERE link=?".format(
            self.dbname), [link])
        self.db.commit()

    def __enter__(self):
        self.cursor = self.db.cursor()
        self.initialize()
        return self

    def __exit__(self, *args):
        self.db.close()


class Console(object):

    def parse_job(self, job, retval):
        return parse_job(job, retval)

    def has_dataplan(self, dataplan):
        for dp in dataplans():
            if dp == dataplan:
                return True
        return False

    def has_job(self, link):
        try:
            with Jobs() as jobs:
                return jobs.get(link) is not None
            raise SystemExit("Unexpected job link: cannot find job by link")
        except Exception as e:
            raise SystemExit("Unexpected error: {}".format(e))

    def handle_jobs(self, *args):
        """jobs"""
        try:
            with Jobs() as jobs:
                index = 1
                for job in jobs.select():
                    start_date = self.parse_job(job, "start_date")
                    pause_date = self.parse_job(job, "pause_date")
                    last_run = self.parse_job(job, "last_run")
                    link = self.parse_job(job, "link")
                    dp_file = self.parse_job(job, "job_file")
                    with open(dp_file) as fd:
                        dataplan = json.load(fd)
                        dp_name = dataplan.get("meta", {}).get("name", "n/a")
                        records = dataplan.get("records", [])
                        keys = ", ".join(dataplan.get("declare", {}).keys())
                    print("{:>3}) {}".format(index, link))
                    if pause_date is None:
                        if last_run is None:
                            print("   * \033[93mQueued\033[00m (never performed)".format(start_date))
                        else:
                            print("   * \033[92mActive\033[00m (last run on {})".format(last_run))
                    else:
                        if last_run is None:
                            print("   * \033[91mPaused\033[00m since {} (never performed)".format(pause_date))
                        else:
                            print("   * \033[91mPaused\033[00m since {} (last run on {})".format(pause_date, last_run))
                    print("   * Collected {} record(s) with the following fields: {}".format(len(records), keys))
                    print('   * Registered on {} with "{}" dataplan'.format(start_date, dp_name))
                    index += 1
                if not index > 1:
                    print("No jobs found")
        except Exception as e:
            raise SystemExit("Unexpected error while listing jobs: {}".format(e))

    def handle_dump(self, link, *args):
        """dump LINK"""
        write_line = lambda line: "\t".join(line)
        try:
            with Jobs() as jobs:
                job_file = self.parse_job(jobs.get(link), "job_file")
            with open(job_file) as fd:
                data = json.load(fd)
                declared_keys = data.get("declare", {})
                records = data.get("records", [])
            ordonated_columns = [("_datetime", "Date and Time")]
            for k in declared_keys.iterkeys():
                ordonated_columns.append((k, k.replace("_", " ").capitalize()))
            headers = [x[-1] for x in ordonated_columns]
            ordonated_rows = [write_line(headers)]
            for each in records:
                row = []
                for c, _ in ordonated_columns:
                    cell = unicode(each.get(c, "n/a"))
                    row.append(cell)
                ordonated_rows.append(write_line(row))
            exportpath = "records_{}.tsv".format(int(time.time()))
            with io.open(exportpath, "w", encoding="utf8") as fd:
                fd.write("\n".join(ordonated_rows))
            print("Exported {} record(s) to {}".format(len(records), exportpath))
        except Exception as e:
            raise SystemExit("Failed to export jobs because: {}".format(e))

    def handle_join(self, dataplan, link, *args):
        """join DATAPLAN LINK"""
        if not dataplan.endswith(".json"):
            dataplan += ".json"
        if not self.has_dataplan(dataplan):
            raise SystemExit("Unsupported dataplan {}".format(dataplan))
        with open(os.path.join(DATAPLANS_DIR, dataplan), "r") as fd:
            data = json.load(fd)
            data.update({"link": link})
            data.update({"records": []})
        now = int(time.time())
        job_file = os.path.join(JOBS_DIRECTORY, "{}_{}".format(dataplan, now))
        if not job_file.endswith(".json"):
            job_file += ".json"
        with open(job_file, "w") as fd:
            json.dump(data, fd, indent=4)
        try:
            with Jobs() as jobs:
                jobs.insert(dataplan, job_file, link)
            print("Successfully added new background job: {}".format(job_file))
        except Exception as e:
            raise SystemExit("Failed to add background job because: {}".format(e))

    def handle_purge(self, link, *args):
        """purge LINK"""
        if not self.has_job(link):
            raise SystemExit("Job does not exist")
        try:
            with Jobs() as jobs:
                job_file = self.parse_job(jobs.get(link), "job_file")
                os.remove(job_file)
                jobs.delete(link)
            print("Successfully removed background job")
        except Exception as e:
            raise SystemExit("Failed to remove background job because: {}".format(e))

    def handle_pause(self, link, *args):
        """pause LINK"""
        try:
            with Jobs() as jobs:
                pause_date = self.parse_job(jobs.get(link), "pause_date")
                if pause_date is not None:
                    raise SystemExit("Job is already paused")
                jobs.pause_now(link)
            print("Successfully paused background job")
        except Exception as e:
            raise SystemExit("Failed to pause job because: {}".format(e))

    def handle_resume(self, link, *args):
        """resume LINK"""
        try:
            with Jobs() as jobs:
                pause_date = self.parse_job(jobs.get(link), "pause_date")
                if pause_date is None:
                    raise SystemExit("Job is already running")
                jobs.resume_now(link)
            print("Successfully resumed background job")
        except Exception as e:
            raise SystemExit("Failed to resume job because: {}".format(e))


class Task(object):

    def __init__(self):
        self.tasks = {}
        self.rpc = xmlrpclib.ServerProxy(RPC_ADDRESS, allow_none=True)

    def run_fifo(self):
        with Jobs() as jobs:
            for j in jobs.select_fifo24():
                dataplan_name = parse_job(j, "dataplan")
                if dataplan_name in self.tasks:
                    continue
                dataplan_job = parse_job(j, "job_file")
                self.tasks.update({dataplan_name: dataplan_job})
                link = parse_job(j, "link")
                jobs.ping(link)
        for each in self.tasks.itervalues():
            self.resolve_job(each)
            self.callback_job(each)

    def resolve_job(self, job):
        job_file = open(job)
        cmd = [HAP_BIN_PATH, job, "--save", "--verbose", "--no-cache"]
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        _, verbose = proc.communicate(input=job_file.read())
        job_file.close()
        print(verbose)

    def callback_job(self, job):
        try:
            self.rpc.ping(job)
        except xmlrpclib.Fault as e:
            print("Unexpected RPC error: {}".format(e))
        except socket.error:
            pass  # server is offline?


def console(prefix="handle_"):
    if not os.isatty(__stdin__):
        return False

    # initialize console application
    app = Console()

    # check if arguments are provided
    if not len(sys.argv) > 1:
        options = [o[len(prefix):] for o in dir(app) if o.startswith(prefix)]
        raise SystemExit("Usage: manager {" + "|".join(options) + "}")

    # detect needed action
    action_name = sys.argv[1]
    action_call = prefix + action_name

    # check if action is supported
    if not hasattr(app, action_call):
        raise SystemExit("Unsupported action {}".format(action_name))

    # call action handler
    handler = getattr(app, action_call)
    try:
        handler(*sys.argv[2:])
    except TypeError as e:
        raise SystemExit("Usage: jobs {}".format(handler.__doc__))
    except Exception as e:
        raise SystemExit("Unexpected error: {}".format(e))

    return True

def task():
    if os.isatty(__stdin__):
        return False

    # initialize app and run fifo
    app = Task()
    app.run_fifo()

    return True

if __name__ == "__main__":
    console() or task()
