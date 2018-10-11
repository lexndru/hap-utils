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

import os
import re
import sys
import json
import time

try:
    import sqlite3
except Exception as e:
    raise SystemExit("Please install sqlite3 module")


# crash scripts trying to import the generator
assert __name__ == "__main__", "Cannot use file as a module"

# detect stdin
__stdin__ = sys.stdin.fileno()

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


class Jobs(object):

    fields = (
        ("link",       "text primary key"),
        ("dataplan",   "text"),
        ("interval",   "integer"),  # hours
        ("callback",   "text"),
        ("comment",    "text"),
        ("start_date", "text"),
        ("pause_date", "text"),
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

    def insert(self, dataplan, link):
        fields = "dataplan, link, interval"
        values = [dataplan, link, 24]
        self.cursor.execute(r"INSERT INTO {} ({}, start_date) VALUES ({},CURRENT_TIMESTAMP)".format(
            self.dbname, fields, ",".join(["?" for _ in values])), values)
        self.db.commit()

    def delete(self, link):
        self.cursor.execute(r"DELETE FROM {} WHERE link=?".format(
            self.dbname), [link])
        self.db.commit()

    def select(self):
        self.cursor.execute(r"SELECT * FROM {}".format(self.dbname))
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

    def __init__(self):
        pass

    def parse_job(self, job, retval):
        link, job_file, interval, _, _, start_date, pause_date, _ = job
        if retval == "link":
            return link
        elif retval == "job_file":
            return job_file
        elif retval == "interval":
            return interval
        elif retval == "start_date":
            return start_date
        elif retval == "pause_date":
            return pause_date
        raise SystemExit("Undefined return value after parsing job")

    def handle_jobs(self, *args):
        """jobs"""
        try:
            with Jobs() as jobs:
                for job in jobs.select():
                    print("Link: {:<20}".format(self.parse_job(job, "link")))
        except Exception as e:
            raise SystemExit("Unexpected error while listing jobs: {}".format(e))

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

    def handle_join(self, dataplan, link, *args):
        """join DATAPLAN LINK"""
        if not dataplan.endswith(".json"):
            dataplan += ".json"
        if not self.has_dataplan(dataplan):
            raise SystemExit("Unsupported dataplan {}".format(dataplan))
        with open(os.path.join(DATAPLANS_DIR, dataplan), "r") as fd:
            data = json.load(fd)
            data.update({"link": link})
        job_link = re.sub(r"\W+", "_", link).strip("_")
        job_file = os.path.join(JOBS_DIRECTORY, job_link)
        if not job_file.endswith(".json"):
            job_file += ".json"
        with open(job_file, "w") as fd:
            json.dump(data, fd, indent=4)
        try:
            with Jobs() as jobs:
                jobs.insert(job_file, link)
            print("Successfully added new background job (daily interval)")
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
        pass


def console(prefix="handle_"):

    # initialize console application
    app = Console()

    # check if arguments are provided
    if not len(sys.argv) > 1:
        options = [o[len(prefix):] for o in dir(app) if o.startswith(prefix)]
        raise SystemExit("Usage: jobs {" + "|".join(options) + "}")

    # detect needed action
    action_name = sys.argv[1]
    action_call = prefix + action_name

    # check if action is supported
    if not hasattr(app, action_call):
        raise SystemExit("Unsupported action {}".format(action_name))

    # call action handler
    handler = getattr(app, action_call)
    handler(*sys.argv[2:])
    try:
        pass
    except TypeError as e:
        raise SystemExit("Usage: jobs {}".format(handler.__doc__))
    except Exception as e:
        raise SystemExit("Unexpected error: {}".format(e))

    return os.isatty(__stdin__)

def task():
    app = Task()
    return not os.isatty(__stdin__)

if __name__ == "__main__":
    console() or task()
