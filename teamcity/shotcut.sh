#!/bin/bash

# This script is used by teamcity to retrieve the shotcut script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate http://raw.github.com/mltframework/shotcut/master/scripts/build-shotcut.sh
chmod 755 build-shotcut.sh
echo 'INSTALL_DIR="$(pwd)/shotcut"' >> build-shotcut.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-shotcut.conf

# Run Script
./build-shotcut.sh $@ 2>&1 | tee output.txt

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
   minutes=60
   while [ $minutes -gt 0 ]; do
      echo "Git clone failed. Retrying in $minutes minutes."
      sleep 60
      minutes=$((minutes-1))
   done
   ./build-shotcut.sh $@ 2>&1 | tee output.txt
fi

if grep "Some kind of error occured" output.txt; then
   echo "Build failed"
   exit 1
fi

# Cleanup
rm -Rf src
rm *.sh
rm *.conf
rm output.txt
