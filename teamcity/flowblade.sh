#!/bin/bash

# This script is used by teamcity to retrieve the flowblade script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

# Get Script
wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/build/build-flowblade.sh
echo 'INSTALL_DIR="$(pwd)/flowblade"' >> build-flowblade.conf
echo 'AUTO_APPEND_DATE=0' >> build-flowblade.conf
echo 'SOURCE_DIR="$(pwd)/src"' >> build-flowblade.conf
chmod 755 build-flowblade.sh

# Run Script
./build-flowblade.sh 2>&1 | tee -a output.txt

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
   minutes=60
   while [ $minutes -gt 0 ]; do
      echo "Git clone failed. Retrying in $minutes minutes."
      sleep 60
      minutes=$((minutes-1))
   done
   ./build-flowblade.sh
fi

# Create Archive
tar -cjvf flowblade.tar.bz2 flowblade
rm -Rf flowblade src build-flowblade.conf build-flowblade.sh output.txt
