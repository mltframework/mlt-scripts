#!/bin/bash

# This script is used by teamcity to retrieve the melt script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate https://raw.githubusercontent.com/mltframework/mlt-scripts/master/build/build-melt.sh
echo 'INSTALL_DIR="$(pwd)/melt"' >> build-melt.conf
echo 'AUTO_APPEND_DATE=0' >> build-melt.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-melt.conf
echo 'FFMPEG_ADDITIONAL_OPTIONS=--disable-videotoolbox' >> build-melt.conf
chmod 755 build-melt.sh

# Run Script
./build-melt.sh 2>&1 | tee output.txt

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
   minutes=60
   while [ $minutes -gt 0 ]; do
      echo "Git clone failed. Retrying in $minutes minutes."
      sleep 60
      minutes=$((minutes-1))
   done
   ./build-melt.sh 2>&1 | tee output.txt
fi

if grep "Some kind of error occured" output.txt; then
   echo "Build failed"
   exit 1
fi

# Create Archive
tar -cjvf melt.tar.bz2 melt
rm -Rf melt src build-melt.conf build-melt.sh output.txt
