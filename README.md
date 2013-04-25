Extractotron 2013
=================

This branch is an in-progress reimplementation of
[Extractotron](https://github.com/migurski/Extractotron),
made to address a few goals:

- Improved installation.
- Easier deployment outside EC2.
- Continued use after extraction; Extractotron currently shuts itself off after a successful run.

This work is generously funded by Lockheed Martin.

Install
-------

See `bootstrap.sh` to install Extractotron on a stock Ubuntu 12.04 system.
`Bootstrap.sh` will prepare the directory `/usr/local/extractotron` with a
git checkout of this codebase, read global configuration variables from
`chef/role-ec2.json`, then execute `run-install.sh` and finally `run-extract.py`.

`Run-install.sh` installs [Chef](http://www.opscode.com/chef/) and runs all
recipes found under the `chef` directory.

Extract
-------

`Run-extract.py` performs a download of fresh OpenStreetMap planet data,
generates extracts in various file formats and outputs a summary HTML file
with links and previews to `/index.html` in the webserver document root.

Currently, a hard-coded list of Bay Area cities is used for testing purposes
in preference to the worldwide `cities.txt` file in Extractotron’s master branch.