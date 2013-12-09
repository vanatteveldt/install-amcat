Installing AmCAT
================

This repository contains a number of useful scripts for installing AmCAT (github.com/amcat/amcat). 
In particular, it has scripts to install the separate components of AmCAT on the same or different computers.

The components/scripts are:
* install_elastic.sh. This installs elastic together with the HitCountSimilarity extension
* install_wsgi.sh. This installs the AmCAT navigator on uwsgi+nginx. If the database is set to localhost, it also sets up the database. It assumes that an elastic node is reachable.

The repository contains a number of -dist files that function as templates for configuration files. The default.cfg file contains default values for the various parameters needed to install the AmCAT components. You can edit this file or supply these variables as environment variables.

Context
-------

The scripts are aimed at (and tested on) ubuntu 13.10 and rely on apt
and pip to install dependencies. They use upstart (/etc/init) scripts
to install services. These scripts are supposed to be run as root.

