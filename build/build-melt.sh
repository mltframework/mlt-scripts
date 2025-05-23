#!/bin/bash

# This script builds melt and many of its dependencies.
# It can accept a configuration file, default: build-melt.conf

# List of programs used:
# bash, test, tr, awk, ps, make, cmake, cat, sed, curl or wget, and possibly others

# Author: Dan Dennedy <dan@dennedy.org>
# Version: 24
# License: GPL2

################################################################################
# ARGS AND GLOBALS
################################################################################

# These are all of the configuration variables with defaults
INSTALL_DIR="$HOME/melt"
AUTO_APPEND_DATE=1
SOURCE_DIR="$INSTALL_DIR/src"
ACTION_GET_COMPILE_INSTALL=1
ACTION_GET_ONLY=0
ACTION_COMPILE_INSTALL=1
SOURCES_CLEAN=1
INSTALL_AS_ROOT=0
CREATE_STARTUP_SCRIPT=1
BUNDLE_EXTRAS=0
ENABLE_FREI0R=1
FREI0R_HEAD=1
FREI0R_REVISION=
ENABLE_SWFDEC=0
SWFDEC_HEAD=
SWFDEC_REVISION=
ENABLE_MOVIT=1
MOVIT_HEAD=0
MOVIT_REVISION="origin/shotcut-opengl3"
LIBEPOXY_REVISION="v1.3.1"
X264_HEAD=1
X264_REVISION=
X265_HEAD=1
X265_REVISION=
LIBVPX_HEAD=0
LIBVPX_REVISION="v1.15.1"
ENABLE_LAME=0
FFMPEG_PROJECT="FFmpeg"
FFMPEG_HEAD=0
FFMPEG_REVISION="origin/release/7.1"
FFMPEG_SUPPORT_H264=1
FFMPEG_SUPPORT_H265=1
FFMPEG_SUPPORT_LIBVPX=1
FFMPEG_SUPPORT_THEORA=1
FFMPEG_SUPPORT_MP3=0
FFMPEG_SUPPORT_FAAC=0
FFMPEG_SUPPORT_SSL=0
FFMPEG_ADDITIONAL_OPTIONS=
ENABLE_VIDSTAB=1
VIDSTAB_HEAD=1
VIDSTAB_REVISION=
MLT_HEAD=1
MLT_REVISION=
ENABLE_WEBVFX=0
WEBVFX_HEAD=1
WEBVFX_REVISION=
ENABLE_RUBBERBAND=1
RUBBERBAND_HEAD=1
RUBBERBAND_REVISION=
MLT_DISABLE_SOX=0
MLT_DISABLE_SDL=0
MLT_SWIG_LANGUAGES="python"

################################################################################
# Location of config file - if not overriden on command line
CONFIGFILE=build-melt.conf

# If defined to 1, outputs trace log lines
TRACE=0

# If defined to 1, outputs debug log lines
DEBUG=0

# We need to set LANG to C to avoid e.g. svn from getting to funky
export LANG=C

# User CFLAGS and LDFLAGS sometimes prevent more recent local headers.
# Also, you can adjust some flags here.
export CFLAGS=
export CXXFLAGS=
export LDFLAGS=

################################################################################
# FUNCTION SECTION
################################################################################

#################################################################
# usage
# Reports legal options to this script
function usage {
  echo "Usage: $0 [-c config-file] [-t] [-h]"
  echo "Where:"
  echo -e "\t-c config-file\tDefaults to $CONFIGFILE"
  echo -e "\t-t\t\tSpawn into sep. process"
}

#################################################################
# parse_args
# Parses the arguments passed in $@ and sets some global vars
function parse_args {
  CONFIGFILEOPT=""
  DETACH=0
  while getopts ":tc:d:l:" OPT; do
    case $OPT in
      c ) CONFIGFILEOPT=$OPTARG
          echo Setting configfile to $CONFIGFILEOPT
      ;;
      t ) DETACH=1;;
      h ) usage
          exit 0;;
      * ) echo "Unknown option $OPT"
          usage
          exit 1;;
    esac
  done

  # Check configfile
  if test "$CONFIGFILEOPT" != ""; then
    if test ! -r "$CONFIGFILEOPT" ; then
      echo "Unable to read config-file $CONFIGFILEOPT"
      exit 1
    fi
    CONFIGFILE="$CONFIGFILEOPT"
  fi
}
######################################################################
# DATA HANDLING FUNCTIONS
######################################################################

#################################################################
# to_key
# Returns a numeric key from a known subproject
# $1 : string: ffmpeg, mlt, etc.
function to_key {
  case $1 in
    $FFMPEG_PROJECT)
      echo 0
    ;;
    mlt)
      echo 1
    ;;
    frei0r)
      echo 2
    ;;
    x264)
      echo 3
    ;;
    libvpx)
      echo 4
    ;;
    swfdec)
      echo 5
    ;;
    lame)
      echo 6
    ;;
    vid.stab)
      echo 7
    ;;
    movit)
      echo 8
    ;;
    libepoxy)
      echo 9
    ;;
    eigen)
      echo 10
    ;;
    webvfx)
      echo 11
    ;;
    x265)
      echo 12
    ;;
    rubberband)
      echo 13
    ;;
    *)
      echo UNKNOWN
    ;;
  esac
}

#################################################################
# lookup - lookup a value from an array and return it
# $1 array name, $2 subdir name, that is, text string
function lookup {
  eval echo "\${${1}[`to_key $2`]}"
}

######################################################################
# LOG FUNCTIONS
######################################################################

#################################################################
# init_log_file
# Write some init stuff
function init_log_file {
  log `date`
  log $0 starting
}

#################################################################
# trace
# Function that prints a trace line
# $@ : arguments to be printed
function trace {
  if test "1" = "$TRACE" ; then
    echo "TRACE: $@"
  fi
}

#################################################################
# debug
# Function that prints a debug line
# $@ : arguments to be printed
function debug {
  if test "1" = "$DEBUG" ; then
    echo "DEBUG: $@"
  fi
}

#################################################################
# log
# Function that prints a log line
# $@ : arguments to be printed
function log {
  echo "LOG: $@"
}

#################################################################
# log warning
# Function that prints a warning line
# $@ : arguments to be printed
function warn {
  echo "WARN: $@"
}

#################################################################
# die
# Function that prints a line and exists
# $@ : arguments to be printed
function die {
  echo "ERROR: $@"
  feedback_result FAILURE "Some kind of error occured: $@"
  exit -1
}

#################################################################
# cmd
# Function that does a (non-background, non-outputting) command, after logging it
function cmd {
  trace "Entering cmd @ = $@"
  log About to run command: "$@"
  "$@"
}


######################################################################
# SETUP FUNCTIONS
######################################################################

#################################################################
# read_configuration
# Reads $CONFIGFILE, parses it, and exports global variables reflecting the
# content. Aborts, if the file does not exist or is not readable
CONFIGURATION=""
function read_configuration {
  trace "Entering read_configuration @ = $@"
  if test ! -r "$CONFIGFILE"; then
    warn "Unable to read config file $CONFIGFILE"
    return
  fi
  debug "Reading configuration from $CONFIGFILE"
  # This is for replacement in startup scripts
  for LINE in `tr "\t" "=" < $CONFIGFILE`; do
    debug Setting $LINE
    CONFIGURATION="$CONFIGURATION$LINE   "
    #export $LINE || die "Invalid export line: $LINE. Unable to set configuration options from CONFIGFILE"
  done ||\
    die "Unable to set configuration options from $CONFIGFILE"
  source "$CONFIGFILE" || die "Unable to evaluate configuration options from $CONFIGFILE"
}

#################################################################
# set_globals
# Set up globals based on configuration
# This is where the configuration options for each subproject is assembled
function set_globals {
  trace "Entering set_globals @ = $@"
  # Set two convenience variables.
  if test 1 = "$ACTION_GET_ONLY" -o 1 = "$ACTION_GET_COMPILE_INSTALL" ; then
    GET=1
  else
    GET=0
  fi
  NEED_SUDO=0
  if test 1 = "$ACTION_GET_COMPILE_INSTALL" -o 1 = "$ACTION_COMPILE_INSTALL" ; then
    COMPILE_INSTALL=1
    if test 1 = $INSTALL_AS_ROOT ; then
      NEED_SUDO=1
    fi
  else
    COMPILE_INSTALL=0
  fi
  debug "GET=$GET, COMPILE_INSTALL=$COMPILE_INSTALL, NEED_SUDO=$NEED_SUDO"

  # The script sets CREATE_STARTUP_SCRIPT to true always, disable if not COMPILE_INSTALL
  if test 0 = "$COMPILE_INSTALL" ; then
    CREATE_STARTUP_SCRIPT=0
  fi
  debug "CREATE_STARTUP_SCRIPT=$CREATE_STARTUP_SCRIPT"

  # Subdirs list, for number of common operations
  # Note, the function to_key depends on this
  SUBDIRS="$FFMPEG_PROJECT mlt"
  if test "$ENABLE_MOVIT" = 1 && test "$MOVIT_HEAD" = 1 -o "$MOVIT_REVISION" != ""; then
      SUBDIRS="libepoxy eigen movit $SUBDIRS"
  fi
  if test "$ENABLE_FREI0R" = 1 ; then
      SUBDIRS="frei0r $SUBDIRS"
  fi
  if test "$ENABLE_SWFDEC" = 1 && test "$SWFDEC_HEAD" = 1 -o "$SWFDEC_REVISION" != ""; then
      SUBDIRS="swfdec $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_H264" = 1 && test "$X264_HEAD" = 1 -o "$X264_REVISION" != ""; then
      SUBDIRS="x264 $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_H265" = 1 && test "$X265_HEAD" = 1 -o "$X265_REVISION" != ""; then
      SUBDIRS="x265 $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_LIBVPX" = 1 && test "$LIBVPX_HEAD" = 1 -o "$LIBVPX_REVISION" != ""; then
      SUBDIRS="libvpx $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_MP3" = 1 && test "$ENABLE_LAME" = 1; then
      SUBDIRS="lame $SUBDIRS"
  fi
  if test "$ENABLE_VIDSTAB" = 1 ; then
      SUBDIRS="vid.stab $SUBDIRS"
  fi
  if test "$ENABLE_WEBVFX" = "1" && test "$WEBVFX_HEAD" = 1 -o "$WEBVFX_REVISION" != ""; then
      SUBDIRS="$SUBDIRS webvfx"
  fi
  if test "$ENABLE_RUBBERBAND" = 1 ; then
      SUBDIRS="rubberband $SUBDIRS"
  fi
  debug "SUBDIRS = $SUBDIRS"

  # REPOLOCS Array holds the repo urls
  if test "$FFMPEG_PROJECT" = "FFmpeg"; then
      REPOLOCS[0]="https://github.com/FFmpeg/FFmpeg.git"
  elif test "$FFMPEG_PROJECT" = "libav"; then
      REPOLOCS[0]="git://git.libav.org/libav.git"
  else
      die "Unknown FFMPEG_PROJECT ($FFMPEG_PFOJECT). Options are: FFmpeg or libav."
  fi
  REPOLOCS[1]="https://github.com/mltframework/mlt.git"
  REPOLOCS[2]="https://github.com/dyne/frei0r.git"
  REPOLOCS[3]="https://github.com/mirror/x264.git"
  REPOLOCS[4]="https://chromium.googlesource.com/webm/libvpx.git"
  REPOLOCS[5]="https://github.com/mltframework/swfdec.git"
  REPOLOCS[6]="https://ftp.osuosl.org/pub/blfs/conglomeration/lame/lame-3.99.5.tar.gz"
  REPOLOCS[7]="https://github.com/georgmartius/vid.stab.git"
  REPOLOCS[8]="https://github.com/ddennedy/movit.git"
  REPOLOCS[9]="https://github.com/anholt/libepoxy.git"
  REPOLOCS[10]="https://gitlab.com/libeigen/eigen.git"
  REPOLOCS[11]="https://github.com/mltframework/webvfx.git"
  REPOLOCS[12]="https://github.com/videolan/x265.git"
  REPOLOCS[13]="https://github.com/breakfastquay/rubberband.git"

  # REPOTYPE Array holds the repo types. (Yes, this might be redundant, but easy for me)
  REPOTYPES[0]="git"
  REPOTYPES[1]="git"
  REPOTYPES[2]="git"
  REPOTYPES[3]="git"
  REPOTYPES[4]="git"
  REPOTYPES[5]="git"
  REPOTYPES[6]="http-tgz"
  REPOTYPES[7]="git"
  REPOTYPES[8]="git"
  REPOTYPES[9]="git"
  REPOTYPES[10]="git"
  REPOTYPES[11]="git"
  REPOTYPES[12]="git"
  REPOTYPES[13]="git"

  # And, set up the revisions
  REVISIONS[0]=""
  if test 0 = "$FFMPEG_HEAD" -a "$FFMPEG_REVISION" ; then
    REVISIONS[0]="$FFMPEG_REVISION"
  fi
  # Git, just use blank or the hash.
  REVISIONS[1]=""
  if test 0 = "$MLT_HEAD" -a "$MLT_REVISION" ; then
    REVISIONS[1]="$MLT_REVISION"
  fi
  REVISIONS[2]=""
  if test 0 = "$FREI0R_HEAD" -a "$FREI0R_REVISION" ; then
    REVISIONS[2]="$FREI0R_REVISION"
  fi
  REVISIONS[3]=""
  if test 0 = "$X264_HEAD" -a "$X264_REVISION" ; then
    REVISIONS[3]="$X264_REVISION"
  fi
  REVISIONS[4]=""
  if test 0 = "$LIBVPX_HEAD" -a "$LIBVPX_REVISION" ; then
    REVISIONS[4]="$LIBVPX_REVISION"
  fi
  REVISIONS[5]=""
  if test 0 = "$SWFDEC_HEAD" -a "$SWFDEC_REVISION" ; then
    REVISIONS[5]="$SWFDEC_REVISION"
  fi
  REVISIONS[6]="lame-3.99.5"
  REVISIONS[7]=""
  if test 0 = "$VIDSTAB_HEAD" -a "$VIDSTAB_REVISION" ; then
    REVISIONS[7]="$VIDSTAB_REVISION"
  fi
  REVISIONS[8]=""
  if test 0 = "$MOVIT_HEAD" -a "$MOVIT_REVISION" ; then
    REVISIONS[8]="$MOVIT_REVISION"
  fi
  REVISIONS[9]=""
  if test "$LIBEPOXY_REVISION" ; then
    REVISIONS[9]="$LIBEPOXY_REVISION"
  fi
  REVISIONS[10]="3.2.4"
  REVISIONS[11]=""
  if test 0 = "$WEBVFX_HEAD" -a "$WEBVFX_REVISION" ; then
    REVISIONS[11]="$WEBVFX_REVISION"
  fi
  REVISIONS[12]=""
  if test 0 = "$X265_HEAD" -a "$X265_REVISION" ; then
    REVISIONS[12]="$X265_REVISION"
  fi
  REVISIONS[13]=""
  if test 0 = "$RUBBERBAND_HEAD" -a "$RUBBERBAND_REVISION" ; then
    REVISIONS[13]="$RUBBERBAND_REVISION"
  fi

  # Figure out the install dir - we may not install, but then we know it.
  FINAL_INSTALL_DIR=$INSTALL_DIR
  if test 1 = "$AUTO_APPEND_DATE" ; then
    FINAL_INSTALL_DIR="$INSTALL_DIR/`date +'%Y%m%d'`"
  fi
  debug "Using install dir FINAL_INSTALL_DIR=$FINAL_INSTALL_DIR"

  # Figure out the number of cores in the system. Used both by make and startup script
  [ "$TARGET_ARCH" = "" ] && TARGET_ARCH="$(uname -m)"
  [ "$TARGET_OS" = "" ] && TARGET_OS="$(uname -s)"
  if test "$TARGET_OS" = "Darwin"; then
    CPUS=$(sysctl -a hw | grep "ncpu:" | cut -d ' ' -f 2)
  else
    CPUS=$(grep "processor.*:" /proc/cpuinfo | wc -l)
  fi
  # Sanity check
  if test 0 = $CPUS ; then
    CPUS=1
  fi
  MAKEJ=$(( $CPUS + 1 ))
  debug "Using make -j$MAKEJ for compilation"

  # CONFIG Array holds the ./configure (or equiv) command for each project
  # CFLAGS_ Array holds additional CFLAGS for the configure/make step of a given project
  # LDFLAGS_ Array holds additional LDFLAGS for the configure/make step of a given project

  #####
  # ffmpeg
  CONFIG[0]="./configure --prefix=$FINAL_INSTALL_DIR --enable-gpl --enable-version3 --enable-shared --enable-debug --enable-pthreads --enable-runtime-cpudetect"

  if [[ "$FFMPEG_REVISION" != *"0.5" ]]; then
    CONFIG[0]="${CONFIG[0]} --disable-doc"
  fi
  if test 1 = "$FFMPEG_SUPPORT_THEORA" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libtheora --enable-libvorbis"
  fi
  if test 1 = "$FFMPEG_SUPPORT_MP3" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libmp3lame"
  fi
  if test 1 = "$FFMPEG_SUPPORT_FAAC" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libfaac --enable-nonfree"
  fi
  if test 1 = "$FFMPEG_SUPPORT_H264" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libx264"
  fi
  if test 1 = "$FFMPEG_SUPPORT_H265" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libx265"
  fi
  if test 1 = "$FFMPEG_SUPPORT_LIBVPX" ; then
    case "$FFMPEG_REVISION" in
      *0.5) die "libvpx not supported in ffmpeg/libav 0.5 - set FFMPEG_SUPPORT_LIBVPX=0" ;;
      *)    CONFIG[0]="${CONFIG[0]} --enable-libvpx" ;;
    esac
  fi
  if test 1 = "$FFMPEG_SUPPORT_SSL" ; then
    CONFIG[0]="${CONFIG[0]} --enable-openssl --enable-nonfree"
  fi
  # Add optional parameters
  CONFIG[0]="${CONFIG[0]} $FFMPEG_ADDITIONAL_OPTIONS"
  CFLAGS_[0]="-I$FINAL_INSTALL_DIR/include $CFLAGS"
  LDFLAGS_[0]="-L$FINAL_INSTALL_DIR/lib $LDFLAGS"
  if test "$TARGET_OS" = "Darwin" ; then
    CFLAGS_[0]="${CFLAGS_[0]} -I/opt/local/include"
    LDFLAGS_[0]="${LDFLAGS_[0]} -L/opt/local/lib"
  fi

  #####
  # mlt
  CONFIG[1]="cmake -GNinja -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR -DCMAKE_PREFIX_PATH=$QTDIR -DGPL=ON -DGPL3=ON -DMOD_QT=OFF -DMOD_QT6=ON -DMOD_GLAXNIMATE_QT6=ON ."
  # Remember, if adding more of these, to update the post-configure check.
  [ "$MLT_SWIG_LANGUAGES" ] && CONFIG[1]="${CONFIG[1]} -DSWIG_PYTHON=ON"
  if test "1" != "$ENABLE_MOVIT" ; then
    CONFIG[1]="${CONFIG[1]} -DMOD_MOVIT=OFF"
  fi
  if test "1" = "$MLT_DISABLE_SOX" ; then
    CONFIG[1]="${CONFIG[1]} -DMOD_SOX=OFF"
  fi
  CFLAGS_[1]="-I$FINAL_INSTALL_DIR/include $CFLAGS"
  if test "1" = "$MLT_DISABLE_SDL" ; then
    CONFIG[1]="${CONFIG[1]} -DMOD_SDL1=OFF -DMOD_SDL2=OFF"
    CFLAGS_[1]="${CFLAGS_[1]} -DMELT_NOSDL"
  fi
  LDFLAGS_[1]="-L$FINAL_INSTALL_DIR/lib $LDFLAGS"
  if test "$TARGET_OS" = "Darwin" ; then
    CFLAGS_[1]="${CFLAGS_[1]} -I/opt/local/include"
    LDFLAGS_[1]="${LDFLAGS_[1]} -L/opt/local/lib"
  fi

  ####
  # frei0r
  CONFIG[2]="cmake -GNinja -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR -DWITHOUT_GAVL=1 -DWITHOUT_OPENCV=1 $CMAKE_DEBUG_FLAG"
  CFLAGS_[2]=$CFLAGS
  LDFLAGS_[2]=$LDFLAGS

  ####
  # x264
  CONFIG[3]="./configure --prefix=$FINAL_INSTALL_DIR --disable-lavf --disable-ffms --disable-gpac --disable-swscale --enable-shared"
  CFLAGS_[3]=$CFLAGS
  [ "$TARGET_OS" = "Darwin" ] && CFLAGS_[3]="-I. -fno-common -read_only_relocs suppress ${CFLAGS_[3]} "
  LDFLAGS_[3]=$LDFLAGS

  ####
  # libvpx
  CONFIG[4]="./configure --prefix=$FINAL_INSTALL_DIR --enable-vp8 --enable-postproc --enable-multithread --disable-install-docs --disable-debug-libs --disable-examples --disable-unit-tests --extra-cflags=-std=c99"
  [ "$TARGET_ARCH" != "arm64" ] && CONFIG[4]="${CONFIG[4]} --enable-runtime-cpu-detect"
  [ "$TARGET_OS" = "Darwin" ] && CONFIG[4]="${CONFIG[4]} --disable-avx512"
  [ "$TARGET_OS" = "Linux" ] && CONFIG[4]="${CONFIG[4]} --enable-shared"
  CFLAGS_[4]=$CFLAGS
  LDFLAGS_[4]=$LDFLAGS

  #####
  # swfdec
  CONFIG[5]="./configure --prefix=$FINAL_INSTALL_DIR --disable-gtk --disable-gstreamer"
  CFLAGS_[5]=$CFLAGS
  LDFLAGS_[5]=$LDFLAGS

  #####
  # lame
  CONFIG[6]="./configure --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib --disable-decoder --disable-frontend"
  CFLAGS_[6]=$CFLAGS
  LDFLAGS_[6]=$LDFLAGS

  ####
  # vid.stab
  CONFIG[7]="cmake -DCMAKE_INSTALL_PREFIX:PATH=$FINAL_INSTALL_DIR"
  if test "$TARGET_OS" = "Darwin" ; then
    CONFIG[7]="${CONFIG[7]} -DUSE_OMP=OFF"
  fi
  CFLAGS_[7]=$CFLAGS
  LDFLAGS_[7]=$LDFLAGS

  #####
  # movit
  CONFIG[8]="./autogen.sh --prefix=$FINAL_INSTALL_DIR"
  if test "$TARGET_OS" = "Win32" ; then
    CONFIG[8]="${CONFIG[8]} --host=x86-w64-mingw32"
    CFLAGS_[8]="$CFLAGS"
  elif test "$TARGET_OS" = "Darwin"; then
    CFLAGS_[8]="$CFLAGS -I/opt/local/include"
  else
    CFLAGS_[8]="$CFLAGS"
  fi
  CFLAGS_[8]="-I../eigen ${CFLAGS_[8]}"
  LDFLAGS_[8]=$LDFLAGS

  #####
  # libepoxy
  CONFIG[9]="./autogen.sh --prefix=$FINAL_INSTALL_DIR"
  if test "$TARGET_OS" = "Win32" ; then
    CONFIG[9]="${CONFIG[9]} --host=x86-w64-mingw32"
    CFLAGS_[9]="$CFLAGS"
  elif test "$TARGET_OS" = "Darwin"; then
    CFLAGS_[9]="$CFLAGS -I/opt/local/include"
  else
    CFLAGS_[9]="$CFLAGS"
  fi
  LDFLAGS_[9]=$LDFLAGS

  #######
  # eigen - no build required
  CONFIG[10]=""

  #####
  # WebVfx
  if [ "$TARGET_OS" = "Darwin" ]; then
    if [ "$QTDIR" = "" ]; then
      CONFIG[11]="qmake -r -spec macx-g++ MLT_PREFIX=$FINAL_INSTALL_DIR"
    else
      CONFIG[11]="$QTDIR/bin/qmake -r -spec macx-g++ MLT_PREFIX=$FINAL_INSTALL_DIR"
    fi
  elif [ "$TARGET_OS" = "Win32" -o "$TARGET_OS" = "Win64" ]; then
    CONFIG[11]="$QMAKE -r -spec mkspecs/mingw LIBS+=-L${QTDIR}/lib INCLUDEPATH+=$FINAL_INSTALL_DIR/include"
  else
    if [ "$QTDIR" = "" ]; then
      CONFIG[11]="qmake -r"
    else
      CONFIG[11]="$QTDIR/bin/qmake -r"
    fi
  fi
  CONFIG[11]="${CONFIG[11]} PREFIX=$FINAL_INSTALL_DIR MLT_SOURCE=$SOURCE_DIR/mlt"
  CFLAGS_[11]=$CFLAGS
  LDFLAGS_[11]=$LDFLAGS

  ######
  # x265
  CFLAGS_[12]=$CFLAGS
  if test "$TARGET_OS" = "Win32" -o "$TARGET_OS" = "Win64" ; then
    CONFIG[12]="cmake -GNinja -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR -DCMAKE_TOOLCHAIN_FILE=my.cmake -DENABLE_CLI=OFF"
  else
    CONFIG[12]="cmake -GNinja -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR -DENABLE_CLI=OFF"
  fi
  LDFLAGS_[12]=$LDFLAGS

  #####
  # rubberband
  CONFIG[13]="meson setup builddir --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib"
  CFLAGS_[13]=$CFLAGS
  LDFLAGS_[13]=$LDFLAGS
}

######################################################################
# FEEDBACK FUNCTIONS
######################################################################

#################################################################
# feedback_init
# $1 : ProgressBar maximum
# Resets the progressbar or textual output based on DCOPREF
function feedback_init {
  trace "Entering feedback_init @ = $@"
  case $DCOPREF in
    none)
      log Total number of steps needed to complete $1
      log Press Ctrl+C to abort
    ;;
    kdialog*)
      cmd dcop $DCOPREF ProgressDialog setTotalSteps $1 || \
        warn Unable to setTotalSteps on ProgressBar
      cmd dcop $DCOPREF ProgressDialog showCancelButton true || \
        warn Unable to show Cancel button on kdialog instance
    ;;
    kmdr*)
      cmd dcop $DCOPREF KommanderIf setMaximum ProgressBar $1 || \
        warn Unable to setMaximum on ProgressBar
    ;;
  esac
  PROGRESS=0
  feedback_set_progress $PROGRESS
}

#################################################################
# feedback_progress
# $1 : ProgressBar position
# Sets the progressbar position or textual output based on DCOPREF
function feedback_set_progress {
  trace "Entering feedback_set_progress @ = $@"
  case $DCOPREF in
    none)
      log Number of steps completed : $1
    ;;
    kdialog*)
      cmd dcop $DCOPREF ProgressDialog setProgress $1 || \
        warn Unable to setProgress on ProgressBar
    ;;
    kmdr*)
      cmd dcop $DCOPREF KommanderIf setText ProgressBar $1 || \
        warn Unable to setProgress on ProgressBar
    ;;
  esac
}

#################################################################
# feedback_status
# $@ status information
# Displays/Appends status, based on DCOPREF
function feedback_status {
  trace "Entering feedback_status @ = $@"
  # Need to collect $@ in a single variable for cmd to work
  ARG=$@
  log "$ARG"
}

#################################################################
# feedback_result
# $1 : SUCCESS, FAILURE, ABORTED
# $2 : Additional information
# Does the relevant feedback, and terminates.
function feedback_result {
  trace "Entering feedback_result @ = $@"

  # If needed, kill the checker process
  if test "" != "$CHECKERPID" ; then
    # Kill the checker process
    kill -9 $CHECKERPID &> /dev/null
  fi

  log "Process has finished. Reason: $@"
}


#################################################################
# feedback_progress
# $@ : Description of task completed
# Increases the progressbar with 1 and sets the status to $@
function feedback_progress {
  trace "Entering feedback_progress @ = $@"
  PROGRESS=$(( $PROGRESS + 1 ))
  feedback_status $@
  feedback_set_progress $PROGRESS
}

#################################################################
# prepare_feedback
# Function to prepare the feedback. E.g. set up max progress steps
# Based on configuration read and the DCOPREF variable
function prepare_feedback {
  trace "Entering prepare_feedback @ = $@"
  # Figure out the number of steps
  # Get adds 8 if cleaning, 4 otherwise (2/1 pr. proj)
  # Compile/Install adds 12 (3/proj)
  # Script install adds 1
  NUMSTEPS=0
  if test 1 = "$GET" ; then
    debug Adding 3 steps for get
    NUMSTEPS=$(( $NUMSTEPS + 3 ))
    if test 1 = "$ENABLE_FREI0R" ; then
      debug Adding 1 step for get frei0r
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test 1 = "$ENABLE_MOVIT" ; then
      debug Adding 3 steps for get movit, libepoxy, and eigen
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test 1 = "$ENABLE_SWFDEC" ; then
      debug Adding 1 step for get swfdec
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test 1 = "$ENABLE_WEBVFX" ; then
      debug Adding 1 step for get webvfx
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
  fi
  if test 1 = "$GET" -a 1 = "$SOURCES_CLEAN" ; then
    debug Adding 3 steps for clean on get
    NUMSTEPS=$(( $NUMSTEPS + 3 ))
    if test 1 = "$ENABLE_FREI0R" ; then
      debug Adding 1 step for clean frei0r
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test 1 = "$ENABLE_MOVIT" ; then
      debug Adding 3 steps for clean movit, libepoxy, and eigen
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test 1 = "$ENABLE_SWFDEC" ; then
      debug Adding 1 step for clean swfdec
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test 1 = "$ENABLE_WEBVFX" ; then
      debug Adding 1 step for clean webvfx
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
  fi
  if test 1 = "$COMPILE_INSTALL" ; then
    debug Adding 9 steps for compile-install
    NUMSTEPS=$(( $NUMSTEPS + 9 ))
    if test 1 = "$ENABLE_FREI0R" ; then
      debug Adding 3 steps for compile-install frei0r
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test 1 = "$ENABLE_MOVIT" ; then
      debug Adding 9 steps for compile-install movit, libepoxy, and eigen
      NUMSTEPS=$(( $NUMSTEPS + 9 ))
    fi
    if test 1 = "$ENABLE_SWFDEC" ; then
      debug Adding 3 steps for compile-install swfdec
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test 1 = "$ENABLE_WEBVFX" ; then
      debug Adding 3 steps for compile-install webvfx
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
  fi
  if test 1 = "$CREATE_STARTUP_SCRIPT" ; then
    debug Adding 1 step for script creating
    NUMSTEPS=$(( $NUMSTEPS + 1 ))
  fi
  log Number of steps determined to $NUMSTEPS
  feedback_init $NUMSTEPS
}

#################################################################
# check_abort
# Function that checks if the user wanted to cancel what we are doing.
# returns "stop" or "cont" as appropiate
function check_abort {
  # log "$ARG"
  echo
}

######################################################################
# GLOBAL TEST FUNCTIONS
######################################################################

#################################################################
# is_newer_equal
# Compares versions strings, and returns 1 if $1 is newer than $2
# This is highly ineffective, I am sorry to say...
function is_newer_equal {
  trace "Entering is_newer_equal @ = $@"
  A1=`echo $1 | cut -d. -f1`
  A2=`echo $1 | cut -d. -f2`
  A3=`echo $1 | cut -d. -f3 | sed 's/^\([0-9]\{1,3\}\).*/\1/'`
  B1=`echo $2 | cut -d. -f1`
  B2=`echo $2 | cut -d. -f2`
  B3=`echo $2 | cut -d. -f3 | sed 's/^\([0-9]\{1,3\}\).*/\1/'`
  debug "A = $A1 $A2 $A3, B = $B1 $B2 $B3"
  test "$A1" -gt "$B1" -o \( "$A1" = "$B1" -a "$A2" -gt "$B2" \) -o \( "$A1" = "$B1" -a "$A2" = "$B2" -a "$A3" -ge "$B3" \)
}

######################################################################
# ACTION GET FUNCTIONS
######################################################################

#################################################################
# make_clean_dir
# Make clean in a specific directory
# $1: The directory to make clean in.
# Any errors are ignored. Make clean is only called if cd success.
# Assumes cwd is common parent dir
function make_clean_dir {
  trace "Entering make_clean_dir @ = $@"
  log Make clean for $1 called
  feedback_status "Cleaning out sources for $1"
  cmd pushd .
  # Special hack for ffmpeg, it sometimes requires distclean to work.
  if test "$FFMPEG_PROJECT" = "$1" ; then
      cmd cd $1 && cmd make distclean
  else
      cmd cd $1 && cmd make clean
  fi
  feedback_progress Cleaned up in $1
  cmd popd
}

#################################################################
# clean_dirs
# Make clean in all directories
function clean_dirs {
  trace "Entering clean_dirs @ = $@"
  feedback_status Cleaning out all subdirs
  cmd cd $SOURCE_DIR || mkdir -p $SOURCE_DIR
  cmd cd $SOURCE_DIR || die "Unable to change to directory $SOURCE_DIR"
  for DIR in $SUBDIRS ; do
    make_clean_dir $DIR
  done
  feedback_status Done cleaning out in source dirs
}

#################################################################
# get_subproject
# $1 The sourcedir to get sources for
# Get the sources for a single project
# Assumes cwd is common parent dir
# Errors abort
function get_subproject {
  trace "Entering get_subproject @ = $@"
  feedback_status Getting or updating source for $1 - this could take some time
  cmd pushd .

  # Check for repository setyp
  REPOTYPE=`lookup REPOTYPES $1`
  REPOLOC=`lookup REPOLOCS $1`
  REVISION=`lookup REVISIONS $1`
  debug "REPOTYPE=$REPOTYPE, REPOLOC=$REPOLOC, REVISION=$REVISION"

  # Note that svn can check out to current directory, whereas git will not. Sigh.
  if test "git" = "$REPOTYPE" ; then
      # If the dir is there, check if it is a git repo
      if test -d "$1" ; then
          # Change to it
          cmd cd $1 || die "Unable to change to directory $1"
          debug "About to look for git repo"
          git --no-pager status 2>&1 | grep "fatal" &> /dev/null
          if test 0 != $? ; then
              # Found git repo
              debug "Found git repo, will update"
              feedback_status "Pulling git sources for $1"
              cmd git reset --hard || die "Unable to reset git tree for $1"
              if [ "$1" = "rubberband" ]; then
                MAIN_GIT_BRANCH=default
              elif [ "$1" = "libvpx" ]; then
                MAIN_GIT_BRANCH=main
              else
                MAIN_GIT_BRANCH=master
              fi
              cmd git checkout $MAIN_GIT_BRANCH || die "Unable to git checkout $MAIN_GIT_BRANCH"
              cmd git --no-pager pull $REPOLOC $MAIN_GIT_BRANCH || die "Unable to git pull sources for $1"
              cmd git checkout $REVISION || die "Unable to git checkout $REVISION"
          else
              # A dir with the expected name, but not a git repo, bailing out
              PWD=`pwd`
              die "Found a dir with the expected name $1 ($PWD), but it was not a git repo. Unable to proceed. If you have old mlt/mlt++ sources, please delete these directories, before rerunning the script."
          fi
      else
          # No git repo
          debug "No git repo, need to check out"
          feedback_status "Cloning git sources for $1"
          cmd git --no-pager clone --recurse-submodules $REPOLOC || die "Unable to git clone source for $1 from $REPOLOC"
          cmd cd $1 || die "Unable to change to directory $1"
          cmd git checkout --recurse-submodules $REVISION || die "Unable to git checkout $REVISION"
      fi
  elif test "svn" = "$REPOTYPE" ; then
      # Create subdir if not exist
      if test ! -d "$1" ; then
          cmd mkdir -p $1 || die "Unable to create directory $1"
      fi
      # Change to it
      cmd cd $1 || die "Unable to change to directory $1"
      FIND_STR="\(Revision\|Last\ Changed\ Date\)"
      debug "About to look for SVN revision info for $REPOLOC $REVISION"
      svn --non-interactive info | grep "$FIND_STR"
      if test 0 = $? ; then
          debug "Found existing SVN checkout"
          # Found svn info
          # For KDENLIVE: If the svn info URL matches the one we have in the REPOLOCS array, do an update, otherwise, do a switch.
          REPOLOCURL=`svn --non-interactive info | grep URL | awk '{print $2}'`
          # Now, we have to be a bit clever here, because if the user originally checked it out using
          # https, we can not change to http. So, we check for https in the current URL
          # Note, that beeing clever almost always fails at some point. But, at least we give it a try...
          if test "${REPOLOCURL:0:5}" = "https" ; then
              REPOLOC=${REPOLOC/http/https}
          fi
          if test "kdenlive" = "$1" -a $REPOLOCURL != $REPOLOC ; then
              warn "Existing url $REPOLOCURL for $1 does not match the url for selected version: $REPOLOC. Trying svn switch to update"
              feedback_status "Trying to switch repo url for $1"
              cmd svn --non-interactive switch $REPOLOC $REVISION || die "Unable to switch svn repo from $REPOLOCURL to $REPOLOC $REVISION"
          else
              feedback_status "Updating SVN sources for $1"
              cmd svn --non-interactive update $REVISION || die "Unable to update SVN repo in $1 to $REVISION"
          fi
      else
          # No svn info
          feedback_status "Getting SVN sources for $1"
          cmd svn --non-interactive co $REPOLOC . $REVISION || die "Unable to get SVN source for $1 from $REPOLOC $REVISION"
      fi
  elif test "http-tgz" = "$REPOTYPE" ; then
      if test ! -d "$1" ; then
          feedback_status "Downloading archive for $1"
          which curl > /dev/null
          if test 0 = $?; then
              cmd $(curl -L $REPOLOC | tar -xz) || die "Unable to download source for $1 from $REPOLOC"
          else
              which wget > /dev/null
              if test 0 = $?; then
                  cmd $(wget -O - $REPOLOC | tar -xz) || die "Unable to download source for $1 from $REPOLOC"
              fi
          fi
          cmd mv "$REVISION" "$1" || due "Unable to rename $REVISION to $1"
      fi
  fi # git/svn

  feedback_progress Done getting or updating source for $1
  cmd popd
}

#################################################################
# get_all_sources
# Gets all the sources for all subprojects
function get_all_sources {
  trace "Entering get_all_sources @ = $@"
  feedback_status Getting all sources
  log Changing to $SOURCE_DIR
  cd $SOURCE_DIR || mkdir -p "$SOURCE_DIR"
  cd $SOURCE_DIR || die "Unable to change to directory $SOURCE_DIR"
  for DIR in $SUBDIRS ; do
    get_subproject $DIR
  done
  feedback_status Done getting all sources
}

######################################################################
# ACTION COMPILE-INSTALL FUNCTIONS
######################################################################

#################################################################
# mlt_format_required
# log a string that expresses a requirement
function mlt_format_required {
  log 'MLTDISABLED <b>'$1'</b> : this is a <b>required</b> module. '$2'Will abort compilation.'
}

#################################################################
# mlt_format_optional
# log a string that expresses missing an optional
function mlt_format_optional {
  log 'MLTDISABLED <b>'$1'</b> : this is an <b>optional</b> module that provides '$2'. To enable it, try installing a package called something like '$3'.'
}

#################################################################
# mlt_check_configure
# This is a special hack for mlt. Mlt does not allow --enable, or abort
# if something is missing, so we check all the disable files. Some are
# optional, some are required. We stop compilation if a required file is
# missing. For optionals, we report them to the log
# Oh, and it is assumed we are in the toplevel mlt source directory, when
# this is called.
function mlt_check_configure {
  trace "Entering check_mlt_configure @ = $@"
  cmd pushd .
  DODIE=0
  cmd cd src/modules || die "Unable to check mlt modules list"
  for FILE in `ls disable-* 2>/dev/null` ; do
    debug "Checking $FILE"
    case $FILE in
      # REQUIRED
      disable-core)
        mlt_format_required core "I have no idea why this was disabled. "
        DODIE=1
      ;;
      disable-avformat)
        mlt_format_required avformat "Did ffmpeg installation fail? "
        DODIE=1
      ;;
      disable-xml)
        mlt_format_required xml "Please install libxml2-dev. "
        DODIE=1
      ;;
      disable-sdl2)
        if test "0" = "$MLT_DISABLE_SDL" ; then
          mlt_format_required sdl2 "Please install libsdl2-dev. "
          DODIE=1
        fi
      ;;
      disable-qt)
        mlt_format_required qt "Please provide paths for QT on the 'Compile options' page. "
        DODIE=1
      ;;

      # AUDIO
      disable-sox)
        if test "0" = "$MLT_DISABLE_SOX" ; then
          mlt_format_optional sox "sound effects/operations" "sox-dev"
        fi
      ;;
      disable-jackrack)
        mlt_format_optional jackrack "sound effects/operations" "libjack-dev"
      ;;
      disable-resample)
        mlt_format_optional resample "audio resampling" "libsamplerate0-dev"
      ;;

      # IMAGE
      disable-gtk2)
        mlt_format_optional gtk2 "some additional image loading support" "libgtk2-dev?"
      ;;
      disable-kdenlive)
        mlt_format_optional kdenlive "slow motion and freeze effects" "??"
      ;;
      disable-frei0r)
        mlt_format_optional frei0r "plugin architecture. Several additional effects and transitions" "see http://www.piksel.org/frei0r"
      ;;

      # OTHERS
      disable-dv)
        mlt_format_optional dv "loading and saving of DV files" "libdv/libdv-dev"
      ;;
      disable-vorbis)
        mlt_format_optional vorbis "loading and saving ogg/theora/vorbis files" "libvorbis-dev"
      ;;

      # FALLBACK
      disable-*)
        mlt_format_optional ${FILE/disable-} "... dunno ... " "... dunno ..."
      ;;
    esac
  done
  if test 1 = "$DODIE" ; then
    die "One or more required MLT modules could not be enabled"
  fi
  cmd popd
}

#################################################################
# configure_compile_install_subproject
# $1 The sourcedir to configure, compile, and install
# Configures, compiles, and installs a single subproject.
# Assumes cwd is common parent dir
# Errors abort
function configure_compile_install_subproject {
  trace "Entering configure_compile_install_subproject @ = $@"
  feedback_status Configuring, compiling, and installing $1

  OLDCFLAGS=$CFLAGS
  OLDLD_LIBRARY_PATH=$LD_LIBRARY_PATH
  cmd pushd .

  # Change to right directory
  cmd cd $1 || die "Unable to change to directory $1"

  # Set cflags, log settings
  log PATH=$PATH
  log LD_RUN_PATH=$LD_RUN_PATH
  log PKG_CONFIG_PATH=$PKG_CONFIG_PATH
  export CFLAGS=`lookup CFLAGS_ $1`
  log CFLAGS=$CFLAGS
  export LDFLAGS=`lookup LDFLAGS_ $1`
  log LDFLAGS=$LDFLAGS

  # Configure
  feedback_status Configuring $1
  # Special hack for libvpx
  if test "libvpx" = "$1" ; then
    cmd make clean
  fi

  # Special hack for movit
  if test "movit" = "$1" -o "mlt" = "$1"; then
    if test "$ENABLE_MOVIT" = "1"; then
      if test "Darwin" = "$TARGET_OS"; then
        export CXXFLAGS="-std=c++11 -stdlib=libc++ $CFLAGS"
      else
        export CXXFLAGS="-std=c++11 $CFLAGS"
      fi
    else
      export CXXFLAGS="$CFLAGS"
    fi
  fi

  # Special hack for swfdec
  if test "swfdec" = "$1" ; then
    debug "Need to create configure for $1"
    cmd autoreconf -i || die "Unable to create configure file for $1"
    if test ! -e configure ; then
      die "Unable to confirm presence of configure file for $1"
    fi
  fi

  # Special hack for x265
  if test "x265" = "$1"; then
    cd source
  fi

  # Special hack for eigen
  if test "eigen" = "$1" ; then
    cmd mkdir build 2> /dev/null
    cmd cd build
  fi

  MYCONFIG=`lookup CONFIG $1`
  if test "$MYCONFIG" != ""; then
    cmd $MYCONFIG || die "Unable to configure $1"
    feedback_progress Done configuring $1
  fi

  # Special hack for mlt, post-configure
  if test "mlt" = "$1" ; then
    mlt_check_configure
  fi

  # Special hack for rubberband
  if [ "rubberband" = "$1" ]; then
    if [ "$TARGET_OS" = "Win32" -o "$TARGET_OS" = "Win64" ]; then
      cmd sed 's/-lrubberband/-lrubberband -lfftw3-3 -lsamplerate/' -i rubberband.pc.in
    fi
  fi

  # Compile
  feedback_status Building $1 - this could take some time
  if test "movit" = "$1" ; then
    cmd make -j$MAKEJ RANLIB="$RANLIB" libmovit.la || die "Unable to build $1"
  elif test "rubberband" = "$1" ; then
    cmd ninja -C builddir -j $MAKEJ || die "Unable to build $1"
  elif test "mlt" = "$1" -o "x265" = "$1" -o "frei0r" = "$1" ; then
    cmd ninja -j $MAKEJ || die "Unable to build $1"
  elif test "$MYCONFIG" != ""; then
    cmd make -j$MAKEJ || die "Unable to build $1"
  fi
  feedback_progress Done building $1

  # Install
  feedback_status Installing $1
  # This export is only for kdenlive, really, and only for the install step
  export LD_LIBRARY_PATH=`lookup LD_LIBRARY_PATH_ $1`
  log "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
  if test "1" = "$NEED_SUDO" -a "$MYCONFIG" != "" ; then
    debug "Needs to be root to install - trying"
    log About to run $SUDO make install
    TMPNAME=`mktemp -t build-melt.installoutput.XXXXXXXXX`
    # At least kdesudo does not return an error code if the program fails
    # Filter output for error, and dup it to the log
    $SUDO make install > $TMPNAME 2>&1
    cat $TMPNAME 2>&1
    # If it contains error it returns 0. 1 matches, 255 errors
    # Filter X errors out too
    grep -v "X Error" $TMPNAME | grep -i error 2>&1
    if test 0 = $? ; then
      die "Unable to install $1"
    fi
  elif test "rubberband" = "$1" ; then
    cmd meson install -C builddir || die "Unable to install $1"
  elif test "mlt" = "$1" -o "x265" = "$1" -o "frei0r" = "$1" ; then
    cmd ninja install || die "Unable to install $1"
  elif test "$MYCONFIG" != "" ; then
    cmd make install || die "Unable to install $1"
    if test "mlt" = "$1" ; then
      cmd cp -a src/swig/python/{_mlt.so,mlt.py} "$FINAL_INSTALL_DIR/lib"
    elif test "libepoxy" = "$1" -a "$TARGET_OS" = "Win32" ; then
      cmd make install || die "Unable to install $1"
      cmd install -p -c include/epoxy/wgl*.h "$FINAL_INSTALL_DIR"/include/epoxy
      # libopengl32.dll is added to prebuilts to make libtool build a dll for
      # libepoxy, but it is not an import lib for other projects.
      cmd rm "$FINAL_INSTALL_DIR"/lib/libopengl32.dll
    fi
  fi
  feedback_progress Done installing $1

  # Reestablish
  cmd popd
  export CFLAGS=$OLDCFLAGS
  export LD_LIBRARY_PATH=$OLDLD_LIBRARY_PATH
}


#################################################################
# configure_compile_install_all
# Configures, compiles, and installs all subprojects
function configure_compile_install_all {
  trace "Entering configure_compile_install_all @ = $@"
  feedback_status Configuring, compiling and installing all sources

  # Set some more vars for this operation
  log "Using install dir $FINAL_INSTALL_DIR"
  log "Found $CPUS cpus. Will use make -j $MAKEJ for compilation"

  # set global settings for all jobs
  export PATH="$FINAL_INSTALL_DIR/bin:$PATH"
  export LD_RUN_PATH="$FINAL_INSTALL_DIR/lib"
  export PKG_CONFIG_PATH="$FINAL_INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"

  log Changing to $SOURCE_DIR
  cd $SOURCE_DIR || die "Unable to change to directory $SOURCE_DIR"
  for DIR in $SUBDIRS ; do
    configure_compile_install_subproject $DIR
  done
  feedback_status Done configuring, compiling and installing all sources
}

######################################################################
# ACTION CREATE_STARTUP_SCRIPT
######################################################################


#################################################################
# get_dir_info
# Helper function for startup script creating - returns svn rev information
# for a given directory
function get_dir_info {
  # trace "Entering get_dir_info @ = $@"
  pushd . &> /dev/null
  cd $1 || die "Unable to change directory to $1"
  REPOTYPE=`lookup REPOTYPES $1`
  if test "xgit" = "x$REPOTYPE" ; then
    FIND_STR="\(commit\|Date\)"
    INFO_TEXT=`git --no-pager log -n1 | grep "$FIND_STR"`
  else
    FIND_STR="\(Revision\|Last\ Changed\ Date\)"
    INFO_TEXT=`svn info | grep "$FIND_STR"`
  fi
  echo
  echo -e $1: ${INFO_TEXT:-Warning: No $REPOTYPE information found in $SOURCE_DIR/$1.}
  echo
  popd  &> /dev/null
}

#################################################################
# sys_info
# Returns some information about the system
function sys_info {
  echo
  echo uname -a at time of compilation:
  uname -a
  echo Information about cc at the time of compilation:
  LANG=C cc -v 2>&1
  if which dpkg ; then
    echo Found dpkg - running dpkg -l to grep libc6
    dpkg -l | grep libc6
  else
    if which rpm ; then
      echo Found rpm - running rpm -qa to grep libc6
      rpm -qa | grep libc
    else
      echo Found neither dpkg or rpm...
    fi
  fi
}

#################################################################
# create_startup_script
# Creates a startup script. Note, that the actual script gets
# embedded by the Makefile
function create_startup_script {
  trace "Entering create_startup_script @ = $@"
  pushd .

  log Changing to $FINAL_INSTALL_DIR
  cd $FINAL_INSTALL_DIR || die "Unable to change to directory $FINAL_INSTALL_DIR"

  TMPFILE=`mktemp -t build-melt.env.XXXXXXXXX`
  log Creating environment script in $TMPFILE
  cat > $TMPFILE <<End-of-environment-setup-template
#!/bin/sh
# Set up environment
# Source this file using a bash/sh compatible shell, to get an environment,
# where you use the binaries and libraries for this melt build.
INSTALL_DIR=\$(pwd)
export PATH="\$INSTALL_DIR/bin":\$PATH
export LD_LIBRARY_PATH="\$INSTALL_DIR/lib":"\$INSTALL_DIR/lib/frei0r-1":\$LD_LIBRARY_PATH
export MLT_REPOSITORY="\$INSTALL_DIR/lib/mlt-7"
export MLT_DATA="\$INSTALL_DIR/share/mlt-7"
export MLT_PROFILES_PATH="\$INSTALL_DIR/share/mlt-7/profiles"
export MLT_MOVIT_PATH="\$INSTALL_DIR/share/movit"
export FREI0R_PATH="\$INSTALL_DIR/lib/frei0r-1":/usr/lib/frei0r-1:/usr/local/lib/frei0r-1:/opt/local/lib/frei0r-1
export MANPATH=\$MANPATH:"\$INSTALL_DIR/share/man"
export PKG_CONFIG_PATH="\$INSTALL_DIR/lib/pkgconfig":\$PKG_CONFIG_PATH
export QT_PLUGIN_PATH="\$INSTALL_DIR/lib/qt"
export QML2_IMPORT_PATH="\$INSTALL_DIR/lib/qml"
End-of-environment-setup-template
  if test 0 != $? ; then
    die "Unable to create environment script"
  fi
  chmod 755 $TMPFILE || die "Unable to make environment script executable"
  $SUDO cp $TMPFILE "$FINAL_INSTALL_DIR/source-me" || die "Unable to create environment script - cp failed"

  log Creating wrapper script in $TMPFILE
  cat > $TMPFILE <<End-of-wrapper-script
#!/bin/sh
# Set up environment
# Run this instead of trying to run bin/melt. It runs melt with the correct environment.
CURRENT_DIR=\$(readlink -f "\$0")
INSTALL_DIR=\$(dirname "\$CURRENT_DIR")
export LD_LIBRARY_PATH="\$INSTALL_DIR/lib":"\$INSTALL_DIR/lib/frei0r-1":\$LD_LIBRARY_PATH
export MLT_REPOSITORY="\$INSTALL_DIR/lib/mlt-7"
export MLT_DATA="\$INSTALL_DIR/share/mlt-7"
export MLT_PROFILES_PATH="\$INSTALL_DIR/share/mlt-7/profiles"
export MLT_MOVIT_PATH="\$INSTALL_DIR/share/movit"
export FREI0R_PATH="\$INSTALL_DIR/lib/frei0r-1":/usr/lib/frei0r-1:/usr/local/lib/frei0r-1:/opt/local/lib/frei0r-1
export QT_PLUGIN_PATH="\$INSTALL_DIR/lib/qt"
export QML2_IMPORT_PATH="\$INSTALL_DIR/lib/qml"
"\$INSTALL_DIR/bin/melt" "\$@"
End-of-wrapper-script
  if test 0 != $? ; then
    die "Unable to create wrapper script"
  fi
  chmod 755 $TMPFILE || die "Unable to make wrapper script executable"
  $SUDO cp $TMPFILE "$FINAL_INSTALL_DIR/melt" || die "Unable to create wrapper script - cp failed"

  feedback_progress Done creating startup and environment script
  popd
}

#################################################################
# bundle_dependencies
# Add some library dependencies from platform into the bundle.
# Skip over common libs such as libc, stdc++, math, and pthreads.
function bundle_dependencies {
  trace "Entering bundle_dependencies @ = $@"
  pushd .

  log Changing to $FINAL_INSTALL_DIR
  cd $FINAL_INSTALL_DIR || die "Unable to change to directory $FINAL_INSTALL_DIR"

  if [ "$QTDIR" != "" ]; then
    log Copying Qt plugins
    cmd install -d "$FINAL_INSTALL_DIR"/lib/qt
    cmd cp -a "$QTDIR"/plugins/{imageformats,platforms,xcbglintegrations} "$FINAL_INSTALL_DIR"/lib/qt
    export LD_LIBRARY_PATH="$QTDIR/lib:$LD_LIBRARY_PATH"
    for lib in "$FINAL_INSTALL_DIR"/lib/qt/{imageformats,platforms,xcbglintegrations}/*.so; do
        fixlibs "$lib"
    done
  fi

  for lib in {lib,lib/mlt,lib/frei0r-1}/*.so; do
    fixlibs "$lib"
  done

  feedback_progress Done bundling library dependencies
  popd
}

function fixlibs
{
  target=$(dirname "$1")/$(basename "$1")
  log fixing library paths of "$lib"
  libs=$(ldd "$target" |
    awk '($3 ~ /^\/usr/) && ($3 !~ /libstdc++/) && ($3 !~ /\/libX/) && ($3 !~ /\/libxcb/) && ($3 !~ /nvidia/) {print $3}')
  if [ "$QTDIR" != "" ]; then
    qtlibs=$(ldd "$target" | grep $QTDIR | cut -d ' ' -f 3)
  fi

  for lib in $libs $qtlibs; do
    if [ $(basename "$lib") != $(basename "$target") ]; then
      # substitute rpath
      # libpath=$(echo $lib | sed "s|@rpath\/Qt|${QTDIR}\/lib\/Qt|")
      cmd cp -n --preserve=timestamps "$lib" lib/
    fi
  done

  for lib in $libs $qtlibs; do
    if [ $(basename "$lib") != $(basename "$target") ]; then
      newlib=$(basename "$lib")
      fixlibs "lib/$newlib"
    fi
  done
}

#################################################################
# perform_action
# Actually do what the user wanted
function perform_action {
  trace "Entering perform_action @ = $@"
  # Test that may fail goes here, before we do anything
  if test 1 = "$GET" -a 1 = "$SOURCES_CLEAN"; then
    clean_dirs
  fi
  if test 1 = "$GET"; then
    get_all_sources
  fi
  if test 1 = "$COMPILE_INSTALL" ; then
    sys_info
    configure_compile_install_all
  fi
  if test 1 = "$CREATE_STARTUP_SCRIPT" ; then
    create_startup_script
  fi
  if test 1 = "$BUNDLE_EXTRAS" ; then
    bundle_dependencies
  fi
  feedback_result SUCCESS "Everything succeeded"
}

################################################################################
# MAIN AND FRIENDS
################################################################################

#################################################################
# kill_recursive
# The intention of this is to be able to kill all children, whenever the
# user aborts.
# This does not really work very very well, but its the best I can offer.
# It may leave some defunct around(?)
# $1 pid
function kill_recursive {
  trace "Entering kill_recursive @ = $@"
  if test "$1" != "$$"; then
    # Stop it from spawning more kids
    kill -9 $1 &> /dev/null
    wait $1
    for CP in `ps --ppid $1 -o pid=` ; do
      kill_recursive $CP
    done
  fi
}

#################################################################
# keep_checking_abort
# Checks if the user indicated an abort through
function keep_checking_abort {
  while test x`check_abort` = "xcont" ; do
    sleep 1
  done
  feedback_result ABORTED "User requested abort"
  # If we reach here, user aborted, kill everything in sight...
  kill_recursive $MAINPID
  exit
}

#################################################################
# main
# Collects all the steps
function main {
  {
  sleep 1
  init_log_file
  read_configuration
  set_globals
  } 2>&1

  # Setup abort handling
  # If anyone know of a better way to get ones pid from within a subshell, let me know...
  MAINPID=`/bin/bash -c "echo \\$PPID"`
  # debug "Main is running with pid $MAINPID"
  keep_checking_abort &
  CHECKERPID=$!
  # debug "Checker process is running with pid=$CHECKERPID"

  # Special case for sudo getting
  SUDO=""
  log "Checking for sudo requirement" 2>&1
  if test "1" = "$NEED_SUDO" ; then
    log "sudo is needed"
        echo You have chosen to install as root.
        echo
        echo 'Please provide your sudo password below.  (If you have recently provided your sudo password to this script, you may not have to do that, because the password is cached).'
        echo
        echo The password will be handled securely by the sudo program.
        echo
        echo If you fail to provide the password, you will have to provide it later when installing the different projects.
        sudo -v
        if test 0 != $? ; then
          die "Unable to proceed"
        fi
        SUDO=sudo
  fi
  log "Done checking for sudo requirement" 2>&1

  {
  prepare_feedback
  perform_action
  } 2>&1

  # All is well, that ends well
  exit 0
}

parse_args "$@"
# Call main, but if detach is given, put it in the background
if test 1 = "$DETACH"; then
  main &
  # Note, that we assume caller has setup stdin & stdout redirection
  disown -a
else
  main
fi
