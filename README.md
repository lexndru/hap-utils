# Hap! utils
[![Build Status](https://travis-ci.org/lexndru/hap-utils.svg?branch=master)](https://travis-ci.org/lexndru/hap-utils)

Hap! utils brings a set of utilities to generate and validate dataplans, automate tasks as background jobs, collect harvested records and extend with custom user functionality. Get Hap! from https://github.com/lexndru/hap or PyPI.

Notice: installing utils replaces hap CLI with a new and improved one; it does NOT delete hap from your system.

## Install from sources
```
$ make install
$ hap
_                   _       _   _ _      
| |__   __ _ _ __   / \_   _| |_(_) |___  
| '_ \ / _' | '_ \ /  / | | | __| | / __|
| | | | (_| | |_) /\_/| |_| | |_| | \__ \
|_| |_|\__,_| .__/\/   \__,_|\__|_|_|___/
           |_|                           

Hap! utils v0.2.1 [installed hap v1.2.3 x86_64 GNU/Linux]

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

 Please report bugs at http://github.com/lexndru/hap-utils

Usage:
 hap [input | option]        - Launch an utility or invoke Hap! directly

Options:
 input [flags]               - File with JSON formated dataplan
 dataplans                   - List all master dataplans available
 register [DATAPLAN | name]  - Register new dataplan or create it
 unregister DATAPLAN         - Unregister existing dataplan
 check DATAPLAN LINK         - Run once a dataplan with a link and test its output
 jobs                        - List all background jobs
 join DATAPLAN LINK          - Add background job with a dataplan and a link
 purge LINK                  - Permanently remove a background job
 pause LINK                  - Temporary pause a background job
 resume LINK                 - Resume a paused a background job
 dump LINK                   - Export job's stored records as tsv
 logs                        - View recent log activity
 upgrade                     - Upgrade Hap! to the latest version

Input flags:
 --link LINK                 - Overwrite link in dataplan
 --save                      - Save collected data to dataplan
 --verbose                   - Enable verbose mode
 --no-cache                  - Disable cache link
 --refresh                   - Reset stored records before save
 --silent                    - Suppress any output
```

## Compatibility
The new CLI is backwards compatible with JSON input files as dataplans. E.g. launching a dataplan from `/tmp/dataplan.json` with the new CLI `hap /tmp/dataplan.json --verbose`.

## Usage and options
The purpose of these utilities is to help generate dataplans and automate harvesting processes in a cronjob-like way. In fact, the background jobs system relies on Linux's `crontab` utility. Handling dataplans is done by a set of tools to `register` and `join` such files.

#### Register master dataplan
A proper dataplan is required in order to harvest something from an HTML document. A dataplan is like a blueprint for an HTML document and any other URL matching the pattern of a document can use the same dataplan, as long as the user seeks to harvest the exact same fields. The purpose of registering a dataplan is to keep it in a "safe place" for later use with any URL that fits the requirements. This is called registering a master dataplan. E.g. for a dataplan kept at `/tmp/another_dataplan.json` an user would do:

```
$ hap register /tmp/another_dataplan.json
Hap! dataplan validator ready to parse /tmp/another_dataplan.json
------------------------------------------------------------
  ✔️  Found a meta name ("another_dataplan")
  ✔️  Using custom configuration
  ✔️  Link found ("http://localhost:8080/something")
  ✔️  Found a valid declared field "full_name" as "string"
  ✔️  Dataplan has all declared fields covered
  ✔️  Found 1 record(s) saved to dataplan
  ✔️  Validated records
------------------------------------------------------------
Valid dataplan
New master dataplan has been registered!
You can use "another_dataplan.json" to add jobs or tasks
```

#### View known master dataplans
At any point in time the user can see a complete list of the master dataplans registered with the system. Each entry shows the name of the dataplan (that can be used to add jobs) and a table-like display of the declared fields, their datatype and a valid sample to match the fields.

```
$ hap dataplans
Found 1 master dataplan(s):
# another_dataplan.json
  Field     | Type       | Sample
  ==========|============|============================================================
  fist_name | string     | Alexandru Catrina
```

#### Unregister a master dataplan
Removing or unregistering a master dataplan does not affect added background jobs, but it will no longer be able to add jobs with the removed dataplan. It is possible to register it again.

```
$ hap unregister another_dataplan.json
Warning: unregistering a master dataplan means you will no longer be able
Warning: to add jobs or tasks with it. Current running tasks or jobs will
Warning: not be affected.
Permanently unregister another_dataplan.json? [yn]
...
```

#### Validating an URL with a master dataplan
Checking the compatibility of an URL is a good practice before adding a background job to run indefinitely. The procedure will run a master dataplan with a given URL as a parameter and return to stdout the results. Fields with non-null values are considered to be valid.

```
$ hap check another_dataplan.json http://localhost/path/to/something
{
    "_datetime": "2018-10-14 23:44:34.195463",
    "first_name": "some value here... or null if incompatible"
}
```

#### Background jobs
Utils extend Hap! by automating it. Adding a background job is similar to a cronjob, but with dataplans. A background job requires a master dataplan and a valid URL compatible with the dataplan. The job will run indefinitely and daily update the newly created dataplan as a result of the join between the master dataplan and the URL provided. Jobs cannot be directly created without master dataplans.

```
$ hap join another_dataplan.json http://localhost/path/to/something
...
```

Background jobs can be listed with `jobs`, temporary paused with `pause` or permanently removed with `purge`. A paused job is ignored on the daily update and will not receive any new records. A paused job can be resumed with `resume`, but resuming a job does not mean it recovers the missing records while it was paused.

#### Jobs records
The collected results can be exported to a `*.tsv` file on local disk. The records can be imported into a database or viewed with any program capable of handing csv-like files (e.g. LibreOffice).

```
$ hap dump http://localhost/path/to/something/saved/as/job
...
```


## License
Copyright 2018 Alexandru Catrina

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
