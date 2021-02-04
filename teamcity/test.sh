#!/bin/bash
#
# This script is used by teamcity to retrieve all the test scripts and run them.
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

test_latest()
{
   # Run the tests that require a fresh build of the latest mlt.
   # Get it and compile it.
   echo 'INSTALL_DIR="$(pwd)/melt"' >> build-melt.conf
   echo 'AUTO_APPEND_DATE=0' >> build-melt.conf
   echo 'SOURCE_DIR="$(pwd)/src"' >> build-melt.conf
   ./build/build-melt.sh

   # Test must run in the melt directory
   pushd melt
      # Run the YML test
     ../test/test_yml.sh

      # Run the A/V sync test
     ../test/test_avsync.sh

      # Run the qtests
     ../test/test_qtest.sh -s "$PWD/../src/mlt"
   popd

   # Cleanup
   rm -Rf melt src build-melt.*
}

test_libav_regression()
{
   # Run the script
   ./test/test_libav_regression.sh
}

test_latest
test_libav_regression
