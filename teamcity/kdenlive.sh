#!/bin/bash

# This script is used by teamcity to retrieve the kdenlive script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/build/build-kdenlive.sh
echo 'INSTALL_DIR="$(pwd)/kdenlive"' >> build-kdenlive.conf
echo 'AUTO_APPEND_DATE=0' >> build-kdenlive.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-kdenlive.conf
chmod 755 build-kdenlive.sh

# Run Script
./build-kdenlive.sh 2>&1 | tee output.txt

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
   minutes=60
   while [ $minutes -gt 0 ]; do
      echo "Git clone failed. Retrying in $minutes minutes."
      sleep 60
      minutes=$((minutes-1))
   done
   ./build-kdenlive.sh 2>&1 | tee output.txt
fi

if grep "Some kind of error occured" output.txt; then
   echo "Build failed"
   exit 1
fi

# Create Archive
tar -cjvf kdenlive.tar.bz2 kdenlive
rm -Rf kdenlive src build-kdenlive.conf build-kdenlive.sh output.txt
