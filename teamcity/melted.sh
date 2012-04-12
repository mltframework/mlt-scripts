#!/bin/bash -e

# This script is used by teamcity to retrieve the melted script and run it
# Author: Brian Matherly
# License: GPL2

# Get Script
wget http://www.mltframework.org/twiki/pub/MLT/BuildScripts/build-melted.sh
echo 'INSTALL_DIR="$(pwd)/melted"' >> build-melted.conf
echo 'AUTO_APPEND_DATE=0' >> build-melted.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-melted.conf
chmod 755 build-melted.sh

# Run Script
./build-melted.sh

# Create Archive
tar -cjvf melted.tar.bz2 melted
rm -Rf melted src build-melted.conf build-melted.sh
