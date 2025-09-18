#!/bin/bash
#
# This script compiles mlt against all supported branches of ffmpeg and libav.
#
# Author: Brian Matherly <code@brianmatherly.com>
# License: GPL2

source ./test/report_results.sh

FFBRANCH[0]="ffmpeg_master"
FFBRANCH[1]="ffmpeg_4_0"
FFBRANCH[2]="ffmpeg_4_1"
FFBRANCH[3]="ffmpeg_4_2"
FFBRANCH[4]="ffmpeg_4_3"
FFBRANCH[5]="ffmpeg_4_4"

CONFIG[0]='
   FFMPEG_HEAD=1
   FFMPEG_PROJECT="FFmpeg"'
CONFIG[1]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.0"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[2]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.1"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[3]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.2"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[4]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.3"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[5]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.4"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'

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
   wget --no-check-certificate https://raw.githubusercontent.com/mltframework/mlt-scripts/master/build/build-melt.sh
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
   echo 'ENABLE_FREI0R=0'         >> build-melt.conf
   echo 'ENABLE_SWFDEC=0'         >> build-melt.conf
   echo 'ENABLE_MOVIT=0'          >> build-melt.conf
   echo 'ENABLE_VIDSTAB=0'        >> build-melt.conf
   echo 'ENABLE_WEBVFX=0'         >> build-melt.conf
   echo 'ENABLE_RUBBERBAND=0'     >> build-melt.conf

   for param in ${CONFIG[$1]} ; do
      echo $param >> build-melt.conf
   done
}

cleanup_test()
{
   rm -Rf melt src/FFmpeg src/libav build-melt.conf
}

run_tests()
{

   branch_count=${#CONFIG[@]}
   echo "$branch_count branches to build"

   for (( i=0; i<${branch_count}; i++ ));
   do
      report_test_start ${FFBRANCH[$i]}
      init_test $i

      ./build/build-melt.sh
      if [ $? -ne 0 ] || [ ! -f "melt/bin/melt" ]; then
         report_test_fail "Failed to build melt against ${FFBRANCH[$i]}"
      fi

      if [ "$archive_artifact" -ne "0" ]; then
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
