#!/bin/bash

# This script is used by teamcity to retrieve the melt script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate http://github.com/mltframework/mlt-scripts/raw/master/build/build-melt.sh
echo 'INSTALL_DIR="$(pwd)/melt"' >> build-melt.conf
echo 'AUTO_APPEND_DATE=0' >> build-melt.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-melt.conf
chmod 755 build-melt.sh

# Run Script
./build-melt.sh

# Create Archive
tar -cjvf melt.tar.bz2 melt
rm -Rf melt src build-melt.conf build-melt.sh
