#!/bin/bash -e

# This script is used by teamcity to retrieve the kdenlive script and run it
# Author: Brian Matherly
# License: GPL2

# Get Script
wget https://github.com/mltframework/mlt-scripts/raw/master/build/build-kdenlive.sh
echo 'INSTALL_DIR="$(pwd)/kdenlive"' >> build-kdenlive.conf
echo 'AUTO_APPEND_DATE=0' >> build-kdenlive.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-kdenlive.conf
chmod 755 build-kdenlive.sh

# Run Script
./build-kdenlive.sh

# Create Archive
tar -cjvf kdenlive.tar.bz2 kdenlive
rm -Rf kdenlive src build-kdenlive.conf build-kdenlive.sh
