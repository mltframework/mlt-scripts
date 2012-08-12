#!/bin/bash
#
# This script compiles mlt against all branches of ffmpeg and libav.
#
# Author: Brian Matherly <pez4brian@yahoo.com>
# License: GPL2

source report_results.sh

FFBRANCH[0]="ffmpeg_master"
FFBRANCH[1]="ffmpeg_0.5"
FFBRANCH[2]="ffmpeg_0.6"
FFBRANCH[3]="ffmpeg_0.7"
FFBRANCH[4]="ffmpeg_0.8"
FFBRANCH[5]="ffmpeg_0.9"
FFBRANCH[6]="ffmpeg_0.10"
FFBRANCH[7]="ffmpeg_0.11"
FFBRANCH[8]="libav_master"
FFBRANCH[9]="libav_0.5"
FFBRANCH[10]="libav_0.6"
FFBRANCH[11]="libav_0.7"
FFBRANCH[12]="libav_0.8"

CONFIG[0]='
   FFMPEG_HEAD=1
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[1]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.5"
   FFMPEG_PROJECT="ffmpeg"
   FFMPEG_SUPPORT_LIBVPX=0'
CONFIG[2]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.6"
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[3]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.7"
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[4]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.8"
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[5]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.9"
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[6]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.10"
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[7]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.11"
   FFMPEG_PROJECT="ffmpeg"'
CONFIG[8]='
   FFMPEG_HEAD=1
   FFMPEG_PROJECT="libav"'
CONFIG[9]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.5"
   FFMPEG_PROJECT="libav"
   FFMPEG_SUPPORT_LIBVPX=0'
CONFIG[10]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.6"
   FFMPEG_PROJECT="libav"'
CONFIG[11]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.7"
   FFMPEG_PROJECT="libav"'
CONFIG[12]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.8"
   FFMPEG_PROJECT="libav"'

declare archive_artifact=0

print_help()
{
cat <<EOM
   -------------------------------------------------------------------------
      Usage: $(basename $0) [arg]
         -a       [a]rchive result
         -e       Stop on [e]rror
         -h       Print [h]elp and exit.
         -t       Report in [t]eamcity format
   -------------------------------------------------------------------------
EOM
}

parse_args()
{
   while getopts "aeht" opt; do
      case $opt in
        a) archive_artifact=1;;
        e) set -e;;
        h) print_help; exit 0;;
        t) report_tc_format;;
        *) echo "unknown arg: $opt"; print_help; exit 1;;
      esac
   done
}

init_suite()
{
   if [ -f build-melt.sh ]; then rm build-melt.sh; fi
   wget https://raw.github.com/mltframework/mlt-scripts/master/build/build-melt.sh
   chmod 755 build-melt.sh
}

cleanup_suite()
{
   rm build-melt.sh
}

init_test()
{
   if [ -f build-melt.conf ]; then rm build-melt.conf; fi
   echo 'INSTALL_DIR="$PWD/melt"' >> build-melt.conf
   echo 'SOURCE_DIR="$PWD/src"'   >> build-melt.conf
   echo 'AUTO_APPEND_DATE=0'      >> build-melt.conf

   for param in ${CONFIG[$1]} ; do
      echo $param >> build-melt.conf
   done
}

cleanup_test()
{
   rm -Rf melt src build-melt.conf
}

run_tests()
{

   branch_count=${#CONFIG[@]}
   echo "$branch_count branches to build"

   for (( i=0; i<${branch_count}; i++ ));
   do
      report_test_start ${FFBRANCH[$i]}
      init_test $i

      ./build-melt.sh
      if [ $? -ne 0 ] || [ ! -f "melt/bin/melt" ]; then
         report_test_fail "Failed to build melt against ${FFBRANCH[$i]}"
      fi

      if [ archive_artifact ]; then
        tar -czvf ${FFBRANCH[$i]}.tar.gz melt
      fi
      
      cleanup_test
      report_test_finish
   done
}

parse_args "$@"
report_suite_start "libav_regression"
init_suite
run_tests
cleanup_suite
report_suite_finish

