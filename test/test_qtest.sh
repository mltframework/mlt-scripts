#!/bin/bash
#
# This script runs the QTest tests
#
# If the RadixRespondsToLocale teset fails then run this command:
#    sudo locale-gen de_DE
#
# Author: Brian Matherly <pez4brian@yahoo.com>
# License: GPL2

# Set up path for melt
source source-me
# Include reporting functions
source report_results.sh

declare MLT_SOURCE_PATH=""

print_help()
{
cat <<EOM
   -------------------------------------------------------------------------
      Usage: $(basename $0) [arg]
         -e        Stop on [e]rror
         -h        Print [h]elp and exit.
         -s <path> Specify the mlt [s]ource path (required)
         -t        Report in [t]eamcity format
   -------------------------------------------------------------------------
EOM
}

parse_args()
{
   while getopts "ehs:t" opt; do
      case $opt in
        e) set -e;;
        h) print_help; exit 0;;
        s) MLT_SOURCE_PATH=$OPTARG;;
        t) report_tc_format;;
        *) echo "unknown arg: $opt"; print_help; exit 1;;
      esac
   done

   if [ "x$MLT_SOURCE_PATH" == "x" ]; then
      echo "The path to the MLT source must be provided using the -s argument"
      print_help
      exit 1
   fi
}

filter_results() 
{
   # This function filters results from "make check" and converts them to the 
   # standard reporting format (Teamcity or not) as configured.
   while read data
   do
      # Detect the test suite start
      if [[ $data == *initTestCase* ]]; then
         suitename=${data%%::*}
         suitename=${suitename##*:}
         report_suite_start $suitename
      fi

      # Process output and report pass/fail
      case $data in
         'PASS '*)
            testname=${data##*:}
            testname=${testname%%()*}
            report_test_start $testname
            echo $data
            report_test_finish
            ;;
         'FAIL! '*)
            testname=${data##*:}
            testname=${testname%%()*}
            report_test_start $testname
            echo $data
            failmsg=${data#*)}
            report_test_fail "$failmsg"
            ;;
         *)
            echo $data
            ;;
      esac

      # Detect the test suite end
      if [[ $data == Totals:* ]]; then
         report_suite_finish
      fi
  done
}

compile_tests()
{
   report_test_start "Compile"
   pushd $MLT_SOURCE_PATH/src/tests
   if [ "$QTDIR" = "" ]; then
      qmake -r tests.pro
   else
      $QTDIR/bin/qmake -r tests.pro
   fi
   make
   RETVAL=$?
   popd

   if [ $RETVAL -eq 0 ]; then
      report_test_finish
   else
      report_test_fail "Failed to compile qtest suite"
   fi
}

run_tests()
{
   pushd $MLT_SOURCE_PATH/src/tests
   make check | filter_results
   popd
}

parse_args "$@"
report_suite_start "qtest"
compile_tests
run_tests
report_suite_finish "qtest"
