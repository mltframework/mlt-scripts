#!/bin/bash -e

# This script is used by teamcity to retrieve the openshot script and run it
# Author: Brian Matherly
# License: GPL2

# Get Script
wget http://www.mltframework.org/twiki/pub/MLT/BuildScripts/build-openshot.sh
echo 'INSTALL_DIR="$(pwd)/openshot"' >> build-openshot.conf
echo 'AUTO_APPEND_DATE=0' >> build-openshot.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-openshot.conf
chmod 755 build-openshot.sh

# Run Script
./build-openshot.sh

# Create Archive
tar -cjvf openshot.tar.bz2 openshot
rm -Rf openshot src build-openshot.conf build-openshot.sh
