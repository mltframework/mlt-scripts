#!/bin/bash
#
# This script tests the A/V sync of various formats using the blipflash 
# producer and consumer.
#
# Author: Brian Matherly <pez4brian@yahoo.com>
# License: GPL2

# Set up path for melt
source source-me
# Include reporting functions
source ../test/report_results.sh

declare -r TEST_DURATION=200 # 200 frames
declare -r RESULTS_FILE="results.txt"
declare -r TMP_FILE="tmp_output"
declare -r ONE_FRAME_MS="33.4" # 29.97 plus a little slop for rounding errors

TEST_NAME[0]="avformat-avi"
TEST_CMDS[0]="melt -silent -profile dv_ntsc blipflash out=$TEST_DURATION -consumer avformat:$TMP_FILE.avi acodec=mp2 terminate_on_pause=1; 
              melt -silent -profile dv_ntsc avformat:$TMP_FILE.avi -consumer blipflash:$RESULTS_FILE terminate_on_pause=1;"

TEST_NAME[1]="avformat-dv"
TEST_CMDS[1]="melt -silent -profile dv_ntsc blipflash out=$TEST_DURATION -consumer avformat:$TMP_FILE.dv pix_fmt=yuv422p terminate_on_pause=1;
              melt -silent -profile dv_ntsc avformat:$TMP_FILE.dv -consumer blipflash:$RESULTS_FILE terminate_on_pause=1"

TEST_NAME[2]="avformat-mkv"
TEST_CMDS[2]="melt -silent -profile dv_ntsc blipflash out=$TEST_DURATION -consumer avformat:$TMP_FILE.mkv terminate_on_pause=1;
              melt -silent -profile dv_ntsc avformat:$TMP_FILE.mkv -consumer blipflash:$RESULTS_FILE terminate_on_pause=1"

TEST_NAME[3]="avformat-mov"
TEST_CMDS[3]="melt -silent -profile dv_ntsc blipflash out=$TEST_DURATION -consumer avformat:$TMP_FILE.mov strict=-2 terminate_on_pause=1;
              melt -silent -profile dv_ntsc avformat:$TMP_FILE.mov -consumer blipflash:$RESULTS_FILE terminate_on_pause=1"

TEST_NAME[4]="avformat-mp4"
TEST_CMDS[4]="melt -silent -profile dv_ntsc blipflash out=$TEST_DURATION -consumer avformat:$TMP_FILE.mp4 strict=-2 terminate_on_pause=1;
              melt -silent -profile dv_ntsc avformat:$TMP_FILE.mp4 -consumer blipflash:$RESULTS_FILE terminate_on_pause=1"

TEST_NAME[5]="avformat-mpg"
TEST_CMDS[5]="melt -silent -profile dv_ntsc blipflash out=$TEST_DURATION -consumer avformat:$TMP_FILE.mpg vcodec=mpeg2video terminate_on_pause=1;
              melt -silent -profile dv_ntsc avformat:$TMP_FILE.mpg -consumer blipflash:$RESULTS_FILE terminate_on_pause=1"

print_help()
{
cat <<EOM
   -------------------------------------------------------------------------
      Usage: $(basename $0) [arg]
         -e       Stop on [e]rror
         -h       Print [h]elp and exit.
         -t       Report in [t]eamcity format
   -------------------------------------------------------------------------
EOM
}

parse_args()
{
   while getopts "eht" opt; do
      case $opt in
        e) set -e;;
        h) print_help; exit 0;;
        t) report_tc_format;;
        *) echo "unknown arg: $opt"; print_help; exit 1;;
      esac
   done
}


run_tests()
{
   test_count=${#TEST_NAME[@]}
   echo "$test_count tests to run"

   for (( i=0; i<${test_count}; i++ )); do
      report_test_start ${TEST_NAME[$i]}
 
      echo "About to execute:"
      echo ${TEST_CMDS[$i]}
      eval ${TEST_CMDS[$i]}

      if [ ! -f $RESULTS_FILE ]; then
         report_test_fail "Failed to calculate sync: No results created."
      else
         # Use the 5th offset calculation from the results file.
         offset=`awk 'NR==5{print $2;}' $RESULTS_FILE`
         echo "A/V Offset: $offset"

         if [ -z "$offset" ] || [ "$offset" = "??" ]; then
            report_test_fail "Failed to calculate offset: $offset"
         else
            in_sync=`echo "($offset < $ONE_FRAME_MS) && ($offset > -$ONE_FRAME_MS)" | bc`
            if [ -z "$in_sync" ] || [ "$in_sync" -ne "1" ]; then
               report_test_fail "Out of sync. Offset: $offset"
            fi
         fi
      fi

      rm -f $RESULTS_FILE
      rm -f $TMP_FILE.*      
      report_test_finish
   done
}

parse_args "$@"
report_suite_start "avsync"
run_tests
report_suite_finish

