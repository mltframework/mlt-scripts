#!/bin/bash

# This script is used by teamcity to retrieve the openshot script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate https://raw.githubusercontent.com/mltframework/mlt-scripts/master/build/build-openshot.sh
echo 'INSTALL_DIR="$(pwd)/openshot"' >> build-openshot.conf
echo 'AUTO_APPEND_DATE=0' >> build-openshot.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-openshot.conf
chmod 755 build-openshot.sh

# Run Script
./build-openshot.sh 2>&1 | tee output.txt

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
   minutes=60
   while [ $minutes -gt 0 ]; do
      echo "Git clone failed. Retrying in $minutes minutes."
      sleep 60
      minutes=$((minutes-1))
   done
   ./build-openshot.sh 2>&1 | tee output.txt
fi

if grep "Some kind of error occured" output.txt; then
   echo "Build failed"
   exit 1
fi

# Create Archive
tar -cjvf openshot.tar.bz2 openshot
rm -Rf openshot src build-openshot.conf build-openshot.sh output.txt
