#!/bin/bash
#
# This script compiles mlt against all supported branches of ffmpeg and libav.
#
# Author: Brian Matherly <code@brianmatherly.com>
# License: GPL2

source report_results.sh

FFBRANCH[0]="ffmpeg_master"
FFBRANCH[1]="ffmpeg_2_4"
FFBRANCH[2]="ffmpeg_2_5"
FFBRANCH[3]="ffmpeg_2_6"
FFBRANCH[4]="ffmpeg_2_7"
FFBRANCH[5]="ffmpeg_2_8"
FFBRANCH[6]="ffmpeg_3_0"
FFBRANCH[7]="ffmpeg_3_1"
FFBRANCH[8]="ffmpeg_3_2"
FFBRANCH[9]="ffmpeg_3_3"
FFBRANCH[10]="ffmpeg_3_4"
FFBRANCH[11]="ffmpeg_4_0"
FFBRANCH[12]="ffmpeg_4_1"
FFBRANCH[13]="libav_master"
FFBRANCH[14]="libav_12"

CONFIG[0]='
   FFMPEG_HEAD=1
   FFMPEG_PROJECT="FFmpeg"'
CONFIG[1]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/2.4"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[2]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/2.5"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[3]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/2.6"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[4]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/2.7"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[5]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/2.8"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[6]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/3.0"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[7]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/3.1"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[8]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/3.2"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[9]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/3.3"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[10]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/3.4"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[11]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.0"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[12]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/4.1"
   FFMPEG_PROJECT="FFmpeg"
   FFMPEG_SUPPORT_H264=0
   FFMPEG_SUPPORT_H265=0
   FFMPEG_SUPPORT_LIBVPX=0
   FFMPEG_SUPPORT_THEORA=0
   FFMPEG_SUPPORT_MP3=0
   FFMPEG_SUPPORT_FAAC=0'
CONFIG[13]='
   FFMPEG_HEAD=1
   FFMPEG_PROJECT="libav"
   FFMPEG_SUPPORT_LIBVPX=0'
CONFIG[14]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/12"
   FFMPEG_PROJECT="libav"
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
   wget --no-check-certificate https://raw.github.com/mltframework/mlt-scripts/master/build/build-melt.sh
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

      ./build-melt.sh
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
