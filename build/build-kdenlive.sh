#!/bin/bash

# This script builds kdenlive from a configuration file

# List of programs used:
# bash, test, tr, awk, ps, make, cmake, cat, sed, qdbus, curl or wget, and possibly others

# Note on feedback:
# The caller can provide a dcop reference to a kmdr-executor running kdenlive builder wizard,
# or just the word kdialog, or nothing

# Compilation instructions more or less taken from http://kdenlive.org/compile

# Current author: Dan Dennedy <dan@dennedy.org>
# Original author: Mads Bondo Dydensborg, mads@dydensborg.dk
# License: GPL2

################################################################################
# ARGS AND GLOBALS
################################################################################

VERSION=19

# These are all of the configuration variables with defaults
INSTALL_DIR="$HOME/kdenlive"
AUTO_APPEND_DATE=1
SOURCE_DIR="$INSTALL_DIR/src"
ACTION_GET_COMPILE_INSTALL=1
ACTION_GET_ONLY=0
ACTION_COMPILE_INSTALL=0
SOURCES_CLEAN=1
INSTALL_AS_ROOT=0
CREATE_STARTUP_SCRIPT=1
KDENLIVE_HEAD=0
KDENLIVE_REVISION=origin/v0.9
ENABLE_FREI0R=1
FREI0R_HEAD=1
FREI0R_REVISION=
ENABLE_SWFDEC=0
SWFDEC_HEAD=1
SWFDEC_REVISION=
X264_HEAD=0
X264_REVISION=d967c09cd93a230e03ec1e0f0f696975d15a01c0
LIBVPX_HEAD=1
LIBVPX_REVISION=
ENABLE_LAME=1
FFMPEG_HEAD=1
FFMPEG_REVISION=
FFMPEG_SUPPORT_H264=1
FFMPEG_SUPPORT_LIBVPX=1
FFMPEG_SUPPORT_THEORA=1
FFMPEG_SUPPORT_XVID=0
FFMPEG_SUPPORT_MP3=1
FFMPEG_SUPPORT_FAAC=0
FFMPEG_ADDITIONAL_OPTIONS=
MLT_HEAD=1
MLT_REVISION=
# QT_INCLUDE_DIR="$(pkg-config --variable=prefix QtCore)/include"
QT_INCLUDE_DIR=
# QT_LIB_DIR="$(pkg-config --variable=prefix QtCore)/lib"
QT_LIB_DIR=
MLT_DISABLE_SOX=0

################################################################################
# Location of config file - if not overriden on command line
CONFIGFILE=build-kdenlive.conf

# If defined to 1, outputs trace log lines
TRACE=0

# If defined to 1, outputs debug log lines
DEBUG=0

# This is the minimum version of Qt and KDE required by kdenlive 4
KDE4_MIN_QT=4.4.0
KDE4_MIN_KDE=4.1.0
USE_KDE4=1

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
  echo "Usage: $0 [-c config-file] [-d dbus-ref] [-t] [-h]"
  echo "Where:"
  echo -e "\t-c config-file\tDefaults to $CONFIGFILE"
  echo -e "\t-d dbus-ref\tOne of 'kdialog' or dcop reference to existing kmdr-executor instance"
  echo -e "\t-t\t\tSpawn into sep. process"
}

#################################################################
# parse_args
# Parses the arguments passed in $@ and sets some global vars
function parse_args {
  CONFIGFILEOPT=""
  DCOPREF="none"
  DETACH=0
  while getopts ":tc:d:l:" OPT; do
    case $OPT in
      c ) CONFIGFILEOPT=$OPTARG
          echo Setting configfile to $CONFIGFILEOPT
      ;;
      d ) DCOPREF=$OPTARG
          echo Setting dbus reference to $DCOPREF
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

  # Massage DCOP-REF
  case $DCOPREF in
    none)
    ;;
    kdialog)
      # Start kdialog instance, if DISPLAY is set
      if test "" = "$DISPLAY" ; then
        echo "DISPLAY not set, can not use -d kdialog"
        exit 1
      fi
      DCOPREF=`kdialog --title "Build Kdenlive" --progressbar "Please wait" 0 | cut -d' ' -f1`
      if test 0 != $? ; then
        echo "Unable to start kdialog"
        exit 1
      fi
      if test "" = "$DCOPREF" ; then
        echo "Unable to understand kdialog response. Lost connection to it. Please kill it using xkill, if needed"
        exit 1
      fi
    ;;
    kmdr*)
      # Just plain OK.
    ;;
    *)
      echo "Illegal value for -d: $DCOPREF"
      exit -1
   ;;
  esac
}
######################################################################
# DATA HANDLING FUNCTIONS
######################################################################

#################################################################
# to_key
# Returns a numeric key from a known subproject
# $1 : string: ffmpeg, mlt, mlt++ or kdenlive
function to_key {
  case $1 in
    FFmpeg)
      echo 0
    ;;
    mlt)
      echo 1
    ;;
    kdenlive)
      echo 2
    ;;
    frei0r)
      echo 3
    ;;
    x264)
      echo 4
    ;;
    libvpx)
      echo 5
    ;;
    swfdec)
      echo 6
    ;;
    lame)
      echo 7
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
  log Using $DCOPREF for feedback
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
  # This is for replacement in kdenlive_start
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
  SUBDIRS="FFmpeg mlt kdenlive"
  if test "$ENABLE_FREI0R" = 1 ; then
      SUBDIRS="frei0r $SUBDIRS"
  fi
  if test "$ENABLE_SWFDEC" = 1 ; then
      SUBDIRS="swfdec $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_H264" = 1 && test "$X264_HEAD" = 1 -o "$X264_REVISION" != ""; then
      SUBDIRS="x264 $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_LIBVPX" = 1 && test "$LIBVPX_HEAD" = 1 -o "$LIBVPX_REVISION" != ""; then
      SUBDIRS="libvpx $SUBDIRS"
  fi
  if test "$FFMPEG_SUPPORT_MP3" = 1 && test "$ENABLE_LAME" = 1; then
      SUBDIRS="lame $SUBDIRS"
  fi
  debug "SUBDIRS = $SUBDIRS"

  # REPOLOCS Array holds the repo urls
  REPOLOCS[0]="git://github.com/FFmpeg/FFmpeg.git"
  REPOLOCS[1]="git://github.com/mltframework/mlt.git"
  REPOLOCS[2]="git://anongit.kde.org/kdenlive"
  REPOLOCS[3]="git://code.dyne.org/frei0r.git"
  REPOLOCS[4]="git://git.videolan.org/x264.git"
  REPOLOCS[5]="http://git.chromium.org/webm/libvpx.git"
  REPOLOCS[6]="git://github.com/mltframework/swfdec.git"
  REPOLOCS[7]="http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.1.tar.gz"

  # REPOTYPE Array holds the repo types. (Yes, this might be redundant, but easy for me)
  REPOTYPES[0]="git"
  REPOTYPES[1]="git"
  REPOTYPES[2]="git"
  REPOTYPES[3]="git"
  REPOTYPES[4]="git"
  REPOTYPES[5]="git"
  REPOTYPES[6]="git"
  REPOTYPES[7]="http-tgz"

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
  if test 0 = "$KDENLIVE_HEAD" -a "$KDENLIVE_REVISION" ; then
    REVISIONS[2]="$KDENLIVE_REVISION"
  fi
  REVISIONS[3]=""
  if test 0 = "$FREI0R_HEAD" -a "$FREI0R_REVISION" ; then
    REVISIONS[3]="$FREI0R_REVISION"
  fi
  REVISIONS[4]=""
  if test 0 = "$X264_HEAD" -a "$X264_REVISION" ; then
    REVISIONS[4]="$X264_REVISION"
  fi
  REVISIONS[5]=""
  if test 0 = "$LIBVPX_HEAD" -a "$LIBVPX_REVISION" ; then
    REVISIONS[5]="$LIBVPX_REVISION"
  fi
  REVISIONS[6]=""
  if test 0 = "$SWFDEC_HEAD" -a "$SWFDEC_REVISION" ; then
    REVISIONS[6]="$SWFDEC_REVISION"
  fi
  REVISIONS[7]="lame-3.99.1"

  # Figure out the install dir - we may not install, but then we know it.
  FINAL_INSTALL_DIR=$INSTALL_DIR
  if test 1 = "$AUTO_APPEND_DATE" ; then
    FINAL_INSTALL_DIR="$INSTALL_DIR/`date +'%Y%m%d'`"
  fi
  debug "Using install dir FINAL_INSTALL_DIR=$FINAL_INSTALL_DIR"

  # Figure out the number of cores in the system. Used both by make and startup script
  TARGET_OS="$(uname -s)"
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
  CONFIG[0]="./configure --prefix=$FINAL_INSTALL_DIR --disable-doc --disable-network --disable-ffserver --enable-gpl --enable-version3 --enable-shared --enable-debug --disable-stripping --enable-pthreads --enable-runtime-cpudetect"
  if test 1 = "$FFMPEG_SUPPORT_THEORA" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libtheora --enable-libvorbis"
  fi
  if test 1 = "$FFMPEG_SUPPORT_XVID" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libxvid"
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
  if test 1 = "$FFMPEG_SUPPORT_LIBVPX" ; then
    CONFIG[0]="${CONFIG[0]} --enable-libvpx"
  fi
  # Add optional parameters
  CONFIG[0]="${CONFIG[0]} $FFMPEG_ADDITIONAL_OPTIONS"
  CFLAGS_[0]="-I$FINAL_INSTALL_DIR/include $CFLAGS"
  LDFLAGS_[0]="-L$FINAL_INSTALL_DIR/lib $LDFLAGS"

  #####
  # mlt
  CONFIG[1]="./configure --prefix=$FINAL_INSTALL_DIR --enable-gpl --enable-debug"
  # Remember, if adding more of these, to update the post-configure check.
  [ "$TARGET_OS" = "Darwin" ] && CONFIG[1]="${CONFIG[1]} --disable-jackrack"
  [ "$QT_INCLUDE_DIR" ] && CONFIG[1]="${CONFIG[1]} --qimage-includedir=$QT_INCLUDE_DIR"
  [ "$QT_LIB_DIR" ] && CONFIG[1]="${CONFIG[1]} --qimage-libdir=$QT_LIB_DIR"
  if test "1" = "$MLT_DISABLE_SOX" ; then
    CONFIG[1]="${CONFIG[1]} --disable-sox"
  fi
  CFLAGS_[1]="-I$FINAL_INSTALL_DIR/include $CFLAGS"
  # Temporary patch until makefile for MLT corrected?
  #CFLAGS_[1]="${CFLAGS_[1]} -I$FINAL_INSTALL_DIR/include/libavcodec/ -I$FINAL_INSTALL_DIR/include/libavformat/ -I$FINAL_INSTALL_DIR/include/libswscale/ -I$FINAL_INSTALL_DIR/include/libavdevice"
  LDFLAGS_[1]="-L$FINAL_INSTALL_DIR/lib $LDFLAGS"
  # Note in the above, that we always looks for frei0r. User can do own install
  # it will be picked up.

  #####
  # kdenlive
  CONFIG[2]="cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$FINAL_INSTALL_DIR -DCMAKE_BUILD_TYPE=debugfull"
  [ "$TARGET_OS" = "Darwin" ] && CONFIG[2]="${CONFIG[2]} -DNO_JOGSHUTTLE=1"
  #CFLAGS_[2]="${CFLAGS_[1]}"
  CFLAGS_[2]="-I$FINAL_INSTALL_DIR/include $CFLAGS"
  LDFLAGS_[2]=$LDFLAGS
  # And a very special bonus for kdenlivebuildwizard
  LD_LIBRARY_PATH_[2]="$FINAL_INSTALL_DIR/lib:$LD_LIBRARY_PATH"

  ####
  # frei0r
  CONFIG[3]="./configure --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib"
  CFLAGS_[3]="$CFLAGS -O2"
  LDFLAGS_[3]=$LDFLAGS

  ####
  # x264
  CONFIG[4]="./configure --prefix=$FINAL_INSTALL_DIR --disable-lavf --disable-ffms --disable-gpac --disable-swscale --enable-shared"
  CFLAGS_[4]=$CFLAGS
  [ "$TARGET_OS" = "Darwin" ] && CFLAGS_[4]="-I. -fno-common -read_only_relocs suppress ${CFLAGS_[4]} "
  LDFLAGS_[4]=$LDFLAGS

  ####
  # libvpx
  CONFIG[5]="./configure --prefix=$FINAL_INSTALL_DIR --enable-vp8 --enable-postproc --enable-multithread --enable-runtime-cpu-detect --disable-install-docs --disable-debug-libs --disable-examples"
  [ "$TARGET_OS" = "Linux" ] && CONFIG[5]="${CONFIG[5]} --enable-shared"
  CFLAGS_[5]=$CFLAGS
  # [ "$TARGET_OS" = "Darwin" ] && CFLAGS_[5]="-I. -fno-common -read_only_relocs suppress ${CFLAGS_[5]} "
  LDFLAGS_[5]=$LDFLAGS

  ####
  # swfdec
  CONFIG[6]="./configure --prefix=$FINAL_INSTALL_DIR --disable-gtk --disable-gstreamer"
  CFLAGS_[6]=$CFLAGS
  LDFLAGS_[6]=$LDFLAGS

  ####
  # lame
  CONFIG[7]="./configure --prefix=$FINAL_INSTALL_DIR --libdir=$FINAL_INSTALL_DIR/lib --disable-decoder --disable-frontend"
  CFLAGS_[7]=$CFLAGS
  LDFLAGS_[7]=$LDFLAGS
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
    org.kde.kdialog-*)
      cmd qdbus $DCOPREF /ProgressDialog org.freedesktop.DBus.Properties.Set org.kde.kdialog.ProgressDialog maximum $1 || \
        warn Unable to set maximum on ProgressBar
      cmd qdbus $DCOPREF /ProgressDialog org.kde.kdialog.ProgressDialog.showCancelButton true || \
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
    org.kde.kdialog-*)
      cmd qdbus $DCOPREF /ProgressDialog org.freedesktop.DBus.Properties.Set org.kde.kdialog.ProgressDialog value $1 || \
        warn Unable to set value on ProgressBar
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
  case $DCOPREF in
    none)
      log "$ARG"
    ;;
    org.kde.kdialog-*)
      cmd qdbus $DCOPREF /ProgressDialog org.kde.kdialog.ProgressDialog.setLabelText "$ARG" || \
        warn Unable to setLabel on ProgressDialog
    ;;
    kmdr*)
      cmd dcop $DCOPREF KommanderIf setText LabelFeedback "$ARG" || \
        warn Unable to update gui status
      cmd dcop $DCOPREF KommanderIf execute ScriptObjectAddStatusLine || \
        warn Unable to update gui status - execute failed
    ;;
  esac
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

  case $DCOPREF in
    none)
      log "Process has finished. Reason: $@"
    ;;
    org.kde.kdialog-*)
      cmd qdbus $DCOPREF /ProgressDialog org.kde.kdialog.ProgressDialog.close || \
        warn Unable to close feedback dialog
        ARG=$@
      cmd kdialog --title "Process has finished" --msgbox '<html><p>Reason: '"$ARG"'.</p><p>Click OK to continue.</p><p>Consult the output for more information.</p>'
    ;;
    kmdr*)
      ARG=$@
      feedback_status $ARG
      cmd dcop $DCOPREF KommanderIf setText LabelFinalResult "$ARG" ||
        warn Unable to notify GUI of final result status
      cmd dcop $DCOPREF KommanderIf execute ScriptObjectDone || \
        warn Unable to notify GUI that I am done
    ;;
  esac
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
    if test 1 = "$ENABLE_SWFDEC" ; then
      debug Adding 1 step for get swfdec
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test "$FFMPEG_SUPPORT_H264" = 1 && test "$X264_HEAD" = 1 -o "$X264_REVISION" != ""; then
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test "$FFMPEG_SUPPORT_LIBVPX" = 1 && test "$LIBVPX_HEAD" = 1 -o "$LIBVPX_REVISION" != ""; then
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test "$FFMPEG_SUPPORT_MP3" = 1 && test "$ENABLE_LAME" = 1; then
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
    if test 1 = "$ENABLE_SWFDEC" ; then
      debug Adding 1 step for clean swfdec
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test "$FFMPEG_SUPPORT_H264" = 1 && test "$X264_HEAD" = 1 -o "$X264_REVISION" != ""; then
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test "$FFMPEG_SUPPORT_LIBVPX" = 1 && test "$LIBVPX_HEAD" = 1 -o "$LIBVPX_REVISION" != ""; then
      NUMSTEPS=$(( $NUMSTEPS + 1 ))
    fi
    if test "$FFMPEG_SUPPORT_MP3" = 1 && test "$ENABLE_LAME" = 1; then
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
    if test 1 = "$ENABLE_SWFDEC" ; then
      debug Adding 3 steps for compile-install swfdec
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test "$FFMPEG_SUPPORT_H264" = 1 && test "$X264_HEAD" = 1 -o "$X264_REVISION" != ""; then
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test "$FFMPEG_SUPPORT_LIBVPX" = 1 && test "$LIBVPX_HEAD" = 1 -o "$LIBVPX_REVISION" != ""; then
      NUMSTEPS=$(( $NUMSTEPS + 3 ))
    fi
    if test "$FFMPEG_SUPPORT_MP3" = 1 && test "$ENABLE_LAME" = 1; then
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
  case $DCOPREF in
    none)
      # log "$ARG"
    ;;
    org.kde.kdialog-*)
      wasCancelled=`qdbus $DCOPREF /ProgressDialog org.kde.kdialog.ProgressDialog.wasCancelled`
      if test 0 != $? -o "true" == $wasCancelled ; then
        # Assume it failed, because the user killed the dialog
        echo stop
      else
        echo cont
      fi
    ;;
    kmdr*)
      wasCancelled=`dcop $DCOPREF KommanderIf text LabelAbort`
      if test 0 != $? ; then
        # Assume it failed, because the user killed the dialog
        echo stop
      else
        echo $wasCancelled
      fi
    ;;
  esac
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

#################################################################
# test_kde4_available
# Tests that qt and kde is high enough version to enable kde4
function test_kde4_available {
  trace "Entering test_kde4_available @ = $@"
  cmd kde4-config -v || die "Unable to run kde4-config"
  QT_VER=`kde4-config -v | grep -i Qt | awk '{print $2}'`
  KDE_VER=`kde4-config -v | grep -i KDE | awk '{print $4}'`
  debug "Versions found: QT: $QT_VER, KDE: $KDE_VER"
  is_newer_equal $QT_VER $KDE4_MIN_QT && is_newer_equal $KDE_VER $KDE4_MIN_KDE
  if test 0 != $? ; then
    die "Building kdenlive for KDE4 was selected, but sufficiently new versions of KDE4 and Qt4 was not found. Needed KDE version $KDE4_MIN_KDE, found $KDE_VER. Needed Qt version $KDE4_MIN_QT, found $QT_VER"
  fi
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
  if test "FFmpeg" = "$1" ; then
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
              cmd git checkout master || die "Unable to git checkout master"
              cmd git --no-pager pull $REPOLOC master || die "Unable to git pull sources for $1"
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
          cmd git --no-pager clone $REPOLOC || die "Unable to git clone source for $1 from $REPOLOC"
          cmd cd $1 || die "Unable to change to directory $1"
          cmd git checkout $REVISION || die "Unable to git checkout $REVISION"
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
      disable-sdl)
        mlt_format_required sdl "Please install libsdl1.2-dev. "
        DODIE=1
      ;;
      disable-qimage)
        mlt_format_required qimage "Please provide paths for QImage on the 'Compile options' page. "
        DODIE=1
      ;;

      # AUDIO
      disable-sox)
        if test "0" = "$MLT_DISABLE_SOX" ; then
          mlt_format_optional sox "sound effects/operations" "sox-dev"
          DODIE=1
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
  # Special hack for kdenlive
  if test "kdenlive" = "$1" ; then
    cmd rm -f CMakeCache.txt || die "Unable to configure $1"
  fi

  # Special hack for libvpx
  if test "libvpx" = "$1" ; then
    cmd make clean
  fi

  # Special hack for frei0r
  if test "frei0r" = "$1" -a ! -e configure ; then
    debug "Need to create configure for $1"
    cmd ./autogen.sh || die "Unable to create configure file for $1"
    if test ! -e configure ; then
      die "Unable to confirm presence of configure file for $1"
    fi
  fi

  # Special hack for swfdec
  if test "swfdec" = "$1" -a ! -e configure ; then
    debug "Need to create configure for $1"
    cmd autoreconf -i || die "Unable to create configure file for $1"
    if test ! -e configure ; then
      die "Unable to confirm presence of configure file for $1"
    fi
  fi

  cmd `lookup CONFIG $1` || die "Unable to configure $1"
  feedback_progress Done configuring $1

  # Special hack for mlt, post-configure
  if test "mlt" = "$1" ; then
    mlt_check_configure
  fi

  # Compile
  feedback_status Building $1 - this could take some time
  cmd make -j$MAKEJ || die "Unable to build $1"
  feedback_progress Done building $1

  # Install
  feedback_status Installing $1
  # This export is only for kdenlive, really, and only for the install step
  export LD_LIBRARY_PATH=`lookup LD_LIBRARY_PATH_ $1`
  log "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
  if test "1" = "$NEED_SUDO" ; then
    debug "Needs to be root to install - trying"
    log About to run $SUDO make install
    TMPNAME=`mktemp -t build-kdenlive.installoutput.XXXXXXXXX`
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
  else
    cmd make install || die "Unable to install $1"
    if test "kdenlive" = "$1" ; then
      if [ ! -d "$FINAL_INSTALL_DIR/.kde" ]; then
        cmd mkdir "$FINAL_INSTALL_DIR/.kde"
      fi
      if test "$KDEHOME" != "" ; then
        HOMEPATH="$KDEHOME"
      else
        HOMEPATH="$HOME/.kde"
        if [ ! -d "$HOMEPATH" ]; then
          HOMEPATH="$HOME/.kde4"
        fi
      fi
      echo "KDE HOME FOLDER: $HOMEPATH"
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
  elif test "xsvn" = "x$REPOTYPE" ; then
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
  if test 1 = "$USE_KDE4" ; then
    echo Information about kde 4 at the time of compilation:
    kde4-config -v
  else
    echo Information about kde 3 at the time of compilation:
    kde-config -v
  fi
}

#################################################################
# create_startup_script
# Creates a startup script. Note, that the actual script gets
# embedded by the Makefile
function create_startup_script {
  trace "Entering create_startup_script @ = $@"
  pushd .

  log Changing to $SOURCE_DIR
  cd $SOURCE_DIR || die "Unable to change to directory $SOURCE_DIR"
  INFO=$INFO"Information about revisions of modules at the time of compilation:"
  for DIR in $SUBDIRS ; do
    INFO=$INFO`get_dir_info $DIR`
  done
  INFO=$INFO`sys_info`

  TMPFILE=`mktemp -t build-kdenlive.start.XXXXXXXXX`
  log Creating startup script in $TMPFILE
  # Note, the content of the template below is inserted by embed_start.pl
  cat > $TMPFILE <<End-of-startup-script-template
#!/bin/bash

# Script to start kdenlive as installed by Kdenlive Builder Wizard.
# The user can select to start kdenlive in two different ways: using gdb or non-gdb

# Check for arguments:
# This script answers to --version and then passes it to kdenlive
# --help is passed directly to kdenlive
# all other, uses the gui questions
# If none is given, pass verything to kdenlive proper

# Figure out the install path regardless how invoked
get_prefix()
{
  # get the path used to run this script
  local prefix=\$(dirname "\$0")
  local first=\$(echo "\$0" | head -c1)
  # if not absolute path
  [ "\$first" != "/" ] && prefix="\$(pwd)/\$prefix"
  echo "\$prefix"
}

# Set up environment
export INSTALL_DIR=\$(get_prefix)
export PATH=\$INSTALL_DIR/bin:\$PATH
export LD_LIBRARY_PATH=\$INSTALL_DIR/lib:\$INSTALL_DIR/lib/frei0r-1:\$LD_LIBRARY_PATH
if [ "$TARGET_OS" = "Darwin" ]; then
  export PATH="\$INSTALL_DIR/bin/kdenlive.app/Contents/MacOS:\$PATH"
  # export DYLD_LIBRARY_PATH="\$LD_LIBRARY_PATH"
  CPUS=\$(sysctl -a hw | grep "ncpu:" | cut -d ' ' -f 2)
else
  CPUS=\$(grep "processor\s*:" /proc/cpuinfo | wc -l)
fi
# export MLT_AVFORMAT_THREADS=\$((\$CPUS - 1))
export MLT_PATH=\$INSTALL_DIR
export MLT_REPOSITORY=\$INSTALL_DIR/lib/mlt
export MLT_DATA=\$INSTALL_DIR/share/mlt
export MLT_PROFILES_PATH=\$INSTALL_DIR/share/mlt/profiles
export FREI0R_PATH=\$INSTALL_DIR/lib/frei0r-1/:/usr/lib/frei0r-1:/usr/local/lib/frei0r-1:/opt/local/lib/frei0r-1
export MANPATH=\$MANPATH:\$INSTALL_DIR/share/man/
export PKG_CONFIG_PATH=\$INSTALL_DIR/lib/pkgconfig/:\$PKG_CONFIG_PATH
export KDEHOME=\$INSTALL_DIR/.kde
export KDEDIRS=\$INSTALL_DIR

# We need to set LANG to C to avoid e.g. kde4-config from getting to
# funky, but we do not want kdenlive to run with it, so store the
# true lang too.
export TRUE_LANG=\$LANG
export LANG=C

################################################################################
# Usage
function usage() {
  echo "\$0 [options] files"
  echo
  echo "  -v, --version        Show version information"
  echo "  --help-start         Show this help"
  echo "  -g, --gdb            Start in gdb mode (no dialog)"
  echo "  -n, --normal         Start in normal mode (no dialog)"
}

WAY_TO_RUN=""
declare -a kdenlive_args
while test "" != "\$1" ; do
  case \$1 in
  -v|--version)
    echo "Kdenlive Builder Wizard version: $VERSION"
    grep -e "Revision:" -e "commit" \$0 | grep -v grep
    kdenlive "\$@"
    exit 0
  ;;
  -h|--help)
    echo "For kdenlive_start options, use --help-start"
    kdenlive "\$@"
    exit 0
  ;;
  --help-start)
    usage
    exit 0
  ;;
  -g|--gdb)
    WAY_TO_RUN="GDB"
    shift
  ;;
  -n|--normal)
    WAY_TO_RUN="Normal"
    shift
  ;;
  *)
    kdenlive_args=(\${kdenlive_args[@]} "\$1")
    shift
  ;;
  esac
done

# We need kdialog and gdb to provide the user with an option to run it in gdb.
# If kdialog is not present, nevermind.
if test "\$WAY_TO_RUN" == "" ; then
    which gdb kdialog &> /dev/null
    if test 0 = \$? ; then
        # Found gdb, ask for way to run it
        WAY_TO_RUN=\`kdialog --combobox "<html><p><b>Starting kdenlive from \$INSTALL_DIR</b></p><p>Kdenlive can be started in two different ways, please select the way you wish to use.</p><p><b>Normal</b> Normal mode, for normal use</p><p><b>GDB output capture</b> Capture output from kdenlive in the Gnu Debugger in a format suitable for a crash report. Use when trying to isolate a bug</p><p>If in doubt, just click the Ok button.</p></html>" "Normal" "GDB output capture"\`
        if test 0 != \$? ; then
            # User clicked cancel
            exit
        fi
    else
        WAY_TO_RUN="Normal"
    fi
fi

echo Way to run = \$WAY_TO_RUN

case \$WAY_TO_RUN in
  GDB*)
    INFILE=\`mktemp -t start-kdenlive.gdb.input.XXXXXXXX\`
    OUTFILE=\`mktemp -t start-kdenlive.gdb.output.XXXXXXXX\`
    echo "Logging to \$OUTFILE"
    cat > \$INFILE <<End-of-cmds
echo
echo set pagination off\n
set pagination off
echo set environment LANG = \$TRUE_LANG
set environment LANG = \$TRUE_LANG
echo run\n
run
echo bt\n
bt
echo thread apply all bt\n
thread apply all bt
echo where full\n
where full
End-of-cmds
    {
    echo This is a logfile of running kdenlive through gdb. You may want to visit http://www.kdenlive.org/mantis/view_all_bug_page.php and attach this file to a proper bug
    echo Kdenlive was installed by Kdenlive Builder Wizard $VERSION
    echo The following configuration variables was used
    cat <<End-of-configuration
$CONFIGURATION
End-of-configuration
    cat <<End-of-info
$INFO
End-of-info
    echo uname -a at runtime:
    uname -a
    if test -a /etc/lsb-release ; then
        echo Catting etc/lsb-release
        cat /etc/lsb-release
    else
        echo /etc/lsb-release not found
    fi
    echo Information about kde 4 at runtime:
    kde4-config -v
    echo Information about kde 3 at runtime:
    kde-config -v
    echo INSTALL_DIR=\$INSTALL_DIR
    echo PATH=\$PATH
    echo LD_LIBRARY_PATH=\$LD_LIBRARY_PATH
    echo MLT_AVFORMAT_THREADS=\$MLT_AVFORMAT_THREADS
    echo MLT_REPOSITORY=\$MLT_REPOSITORY
    echo MLT_DATA=\$MLT_DATA
    echo MLT_PROFILES_PATH=\$MLT_PROFILES_PATH
    echo FREI0R_PATH=\$FREI0R_PATH
    echo PKG_CONFIG_PATH=\$PKG_CONFIG_PATH
    echo KDEHOME=\$KDEHOME
    echo KDEDIRS=\$KDEDIRS
    echo Running ldd \$INSTALL_DIR/bin/kdenlive
    ldd \$INSTALL_DIR/bin/kdenlive
    KDENLIVE_BIN="\$INSTALL_DIR/bin/kdenlive"
    [ "$TARGET_OS" = "Darwin" ] && KDENLIVE_BIN="\$INSTALL_DIR/bin/kdenlive.app/Contents/MacOS/kdenlive"
    echo Running gdb -batch -x "\$INFILE" --args "\$KDENLIVE_BIN" --nocrashhandler "\${kdenlive_args[@]}"
    gdb -batch -x "\$INFILE" --args "\$KDENLIVE_BIN" --nocrashhandler "\${kdenlive_args[@]}"
    } >\$OUTFILE 2>&1
    which kdialog &> /dev/null
    if test 0 = \$? ; then
      if test 0 != \$? ; then
        kdialog --error "There was an error running gdb on \$INSTALL_DIR/bin/kdenlive. Please try a normal run"
        exit;
      fi
      if ! grep "Program exited normally." \$OUTFILE ; then
        if kdialog --yesno "Kdenlive appear to have crashed. Do you want to review the log?" ; then
          kdialog --geometry 800x600 --title "\$OUTFILE" --textbox \$OUTFILE || kwrite \$OUTFILE || kioclient exec \$OUTFILE || kfmclient exec \$OUTFILE || gedit \$OUTFILE || emacs \$OUTFILE || kdialog --error "Unable to open logfile - please open \$OUTFILE yourself"
          exit;
        fi
      fi
    fi
  ;;
  *)
    echo running kdenlive "\${kdenlive_args[@]}"
    export LANG=\$TRUE_LANG
    kdenlive "\${kdenlive_args[@]}"
  ;;
esac
End-of-startup-script-template
  if test 0 != $? ; then
    die "Unable to create startup script"
  fi
  chmod 755 $TMPFILE || die "Unable to make startup script executable"
  $SUDO cp $TMPFILE $FINAL_INSTALL_DIR/start-kdenlive || die "Unable to create startup script - cp failed"

  TMPFILE=`mktemp -t build-kdenlive.env.XXXXXXXXX`
  log Creating environment script in $TMPFILE
  # Note that if you change any of this, you may also want to change kdenlive_start
  cat > $TMPFILE <<End-of-environment-setup-template
# Set up environment
# Source this file using a bash/sh compatible shell, to get an environment,
# where you address the binaries and libraries used by your custom Kdenlive build
# Figure out the install path regardless how invoked
export INSTALL_DIR="\$(dirname \$(pwd))"
export PATH=\$INSTALL_DIR/bin:\$PATH
export LD_LIBRARY_PATH=\$INSTALL_DIR/lib:\$INSTALL_DIR/lib/frei0r-1:\$LD_LIBRARY_PATH
if [ "$TARGET_OS" = "Darwin" ]; then
  export PATH="\$INSTALL_DIR/bin/kdenlive.app/Contents/MacOS:\$PATH"
  # export DYLD_LIBRARY_PATH="\$LD_LIBRARY_PATH"
  CPUS=\$(sysctl -a hw | grep "ncpu:" | cut -d ' ' -f 2)
else
  CPUS=\$(grep "processor\s*:" /proc/cpuinfo | wc -l)
fi
# export MLT_AVFORMAT_THREADS=\$((\$CPUS - 1))
export MLT_REPOSITORY=\$INSTALL_DIR/lib/mlt
export MLT_DATA=\$INSTALL_DIR/share/mlt
export MLT_PROFILES_PATH=\$INSTALL_DIR/share/mlt/profiles
export FREI0R_PATH=\$INSTALL_DIR/lib/frei0r-1/:/usr/lib/frei0r-1:/usr/local/lib/frei0r-1:/opt/local/lib/frei0r-1
export MANPATH=\$MANPATH:\$INSTALL_DIR/share/man/
export PKG_CONFIG_PATH=\$INSTALL_DIR/lib/pkgconfig/:\$PKG_CONFIG_PATH
export KDEHOME=\$INSTALL_DIR/.kde
export KDEDIRS=\$INSTALL_DIR
End-of-environment-setup-template
  if test 0 != $? ; then
    die "Unable to create environment script"
  fi
  chmod 755 $TMPFILE || die "Unable to make environment script executable"
  $SUDO cp $TMPFILE "$FINAL_INSTALL_DIR/bin/kdenlive_env" || die "Unable to create environment script - cp failed"

  feedback_progress Done creating startup and environment script
  popd
}

#################################################################
# perform_action
# Actually do what the user wanted
function perform_action {
  trace "Entering perform_action @ = $@"
  # Test that may fail goes here, before we do anything
  if test 1 = "$USE_KDE4" ; then
    test_kde4_available
  fi
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
    case $DCOPREF in
      none)
        log "DCOPREF is $DCOPREF, using ordinary sudo"
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
      ;;
      org.kde.kdialog-*|kmdr*)
        log "DCOPREF is $DCOPREF, using kdesudo or kdesu"
        SUDO=`which kdesudo`
        if test 0 != $? ; then
          SUDO=`which kdesu`
          if test 0 != $? ; then
            die "You have choosen to install as root, but I could not find neither kdesu or kdesudo in your path. Dunno what to do"
          fi
        fi
        if test "kdesu" = "$SUDO" ; then
          $SUDO -c /bin/true
        else
          # This is kdesudo, but it may not support the --comment option. Try and figure it out
          log "Checking for --comment option to kdesudo"
          $SUDO --help | grep -- --comment &> /dev/null
          if test 0 == $? ; then
            debug "$SUDO supports --comment"
            $SUDO --caption "Please provide sudo password" --comment "<html><p>You have chosen to install as root.</p><p>Please provide your sudo password below.</p><p>The password will be handled securely by the KDE kdesudo program.</p><p>If you fail to provide the password, you will have to provide it later when installing the different projects. Providing it now allows the program to run unsupervised.</p></html>" -c /bin/true
          else
            debug "$SUDO does not support --comment"
            $SUDO --caption "Please provide sudo password" -c /bin/true
          fi
        fi
        # If the user fails to provide password, it is OK, but if running kdesudo fails, stop
        if test 0 != $?; then
          die "Some kind of error occured while calling $SUDO. Unable to proceed"
        fi
      ;;
    esac
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
