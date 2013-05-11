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
   wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/build/build-melt.sh
   echo 'INSTALL_DIR="$(pwd)/melt"' >> build-melt.conf
   echo 'AUTO_APPEND_DATE=0' >> build-melt.conf
   echo 'SOURCE_DIR="$(pwd)/src"' >> build-melt.conf
   chmod 755 build-melt.sh
   ./build-melt.sh

   # Test must run in the melt directory
   pushd melt
      # Get the test scripts
      wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/test/report_results.sh
      wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/test/test_yml.sh
      wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/test/test_avsync.sh
      wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/test/test_qtest.sh

      # Run the YML test
      chmod 755 test_yml.sh
     ./test_yml.sh -t

      # Run the A/V sync test
      chmod 755 test_avsync.sh
     ./test_avsync.sh -t

      # Run the qtests
      chmod 755 test_qtest.sh
     ./test_qtest.sh -t -s "$PWD/../src/mlt"
   popd

   # Cleanup
   rm -Rf melt src build-melt.*
}

test_libav_regression()
{
   # Get the test scripts
   wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/test/report_results.sh
   wget --no-check-certificate http://raw.github.com/mltframework/mlt-scripts/master/test/test_libav_regression.sh

   # Run the script
   chmod 755 test_libav_regression.sh
   ./test_libav_regression.sh -t

   #Cleanup
   rm report_results.sh
   rm test_libav_regression.sh
}

test_latest
test_libav_regression
