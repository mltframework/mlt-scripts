#!/bin/bash
#
# This script provides useful functions for the mlt test scripts. The output
# can be configured to be human readable or compatible with teamcity test 
# reports.
#
# Author: Brian Matherly <pez4brian@yahoo.com>
# License: GPL2

declare -r GREEN_ESC="\E[0;32m"
declare -r RED_ESC="\E[0;31m"
declare -r NORMAL_ESC="\E[0;10m"

declare suite_name=""
declare test_name=""
declare -i teamcity_format=0

report_tc_format()
{
   teamcity_format=1
}

report_suite_start()
{
   suite_name=$1
   if [ $teamcity_format -eq 1 ]; then
      echo "##teamcity[testSuiteStarted name='$suite_name']"
   else
      echo -en $GREEN_ESC
      echo "Started test suite: $suite_name"
      echo -en $NORMAL_ESC
   fi
}

report_suite_finish()
{
   if [ $teamcity_format -eq 1 ]; then
      echo "##teamcity[testSuiteFinished name='$suite_name']"
   else
      echo -en $GREEN_ESC
      echo "Finished test suite: $suite_name"
      echo -en $NORMAL_ESC
   fi
}

report_test_start()
{
   test_name=$1
   if [ $teamcity_format -eq 1 ]; then
	   echo "##teamcity[testStarted name='$test_name' captureStandardOutput='true']"
   else
      echo -en $GREEN_ESC
      echo "Started test: $test_name"
      echo -en $NORMAL_ESC
   fi
}

report_test_finish()
{
   if [ $teamcity_format -eq 1 ]; then
	   echo "##teamcity[testFinished name='$test_name']"
   else
      echo -en $GREEN_ESC
      echo "Finished test: $test_name"
      echo -en $NORMAL_ESC
   fi
}

report_test_fail()
{
   fail_message=$1
   if [ $teamcity_format -eq 1 ]; then
		echo "##teamcity[testFailed name='$test_name' message='$fail_message']"
   else
      echo -en $RED_ESC
      echo "Failed test: $test_name"
      echo "             $fail_message"
      echo -en $NORMAL_ESC
   fi
}
