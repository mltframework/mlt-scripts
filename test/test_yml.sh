#!/bin/bash
#
# This script tests all the service metadata for correctness. It does this by 
# using kwalify to test against each .yml file to be checked against the schema.
# Additionally, it runs melt to make sure melt can parse the file.
#
# Author: Brian Matherly <pez4brian@yahoo.com>
# License: GPL2

source report_results.sh

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
   for file in `find share/mlt -type f -name \*.yml`; do
      file_name=${file##*/}
      service_type=${file_name%%_*}
      service_name=${file_name%*.yml}
      service_name=${service_name#*_}
      test_name=${service_type}_${service_name}

      report_test_start "$test_name"

      kwalify -f share/mlt/metaschema.yaml $file > /dev/null;
      if [ $? -ne 0 ]; then
         report_test_fail "failed to run kwalify -f share/mlt/metaschema.yaml $file"
      fi

      ./melt -query $service_type=$service_name > /dev/null;
      if [ $? -ne 0 ]; then
         report_test_fail "failed to run melt -query $service_type=$service_name"
      fi
      report_test_finish
   done
}

parse_args "$@"
report_suite_start "yml"
run_tests
report_suite_finish

