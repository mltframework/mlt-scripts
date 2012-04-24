#!/bin/bash -e

# This script is used by teamcity to retrieve the shotcut script and run it
# Author: Brian Matherly
# License: GPL2

# Get Script
wget --no-check-certificate http://gitorious.org/mltframework/shotcut/blobs/raw/master/scripts/build-shotcut.sh
chmod 755 build-shotcut.sh
echo 'INSTALL_DIR="$(pwd)/shotcut"' >> build-shotcut.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-shotcut.conf

# Run Script
./build-shotcut.sh

# Cleanup
rm -Rf src
rm *.sh
rm *.conf
