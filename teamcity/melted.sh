#!/bin/bash

# This script is used by teamcity to retrieve the melted script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/build/build-melted.sh
echo 'INSTALL_DIR="$(pwd)/melted"' >> build-melted.conf
echo 'AUTO_APPEND_DATE=0' >> build-melted.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-melted.conf
chmod 755 build-melted.sh

# Run Script
./build-melted.sh 2>&1 | tee -a output.txt

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
   minutes=60
   while [ $minutes -gt 0 ]; do
      echo "Git clone failed. Retrying in $minutes minutes."
      sleep 60
      minutes=$((minutes-1))
   done
   ./build-melted.sh
fi

# Create Archive
tar -cjvf melted.tar.bz2 melted
rm -Rf melted src build-melted.conf build-melted.sh output.txt
