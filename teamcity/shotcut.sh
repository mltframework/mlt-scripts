#!/bin/bash

# This script is used by teamcity to retrieve the shotcut script and run it
# Author: Brian Matherly
# License: GPL2

set -o nounset
set -o errexit

function usage {
  echo "Usage: $0 [-o target-os] [-s]"
  echo "Where:"
  echo -e "\t-o target-os\tDefaults to $(uname -s); use Win32 or Win64 to cross-compile"
  echo -e "\t-s\t\tbuild SDK (Linux and Windows only)"
}

SDK=
TARGET_OS="$(uname -s)"

while getopts ":so:" OPT; do
  case $OPT in
    s ) SDK=1;;
    h ) usage
        exit 0;;
    o ) TARGET_OS=$OPTARG;;
    * ) echo "Unknown option $OPT"
        usage
        exit 1;;
  esac
done

# Get Script
if [ ! -f build-shotcut.sh ]; then
  wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
  chmod 755 build-shotcut.sh
  echo 'INSTALL_DIR="$PWD/shotcut"' >> build-shotcut.conf
  echo 'SOURCE_DIR="$PWD/src"' >> build-shotcut.conf
  [ "$SDK" = "1" ] && echo 'DEBUG_BUILD=1' >> build-shotcut.conf
fi

# Run Script
if [ "$TARGET_OS" = "Darwin" ]; then
  ./build-shotcut.sh "$@"
else
  docker run --rm -v $PWD:/root/shotcut ddennedy/shotcut-build "$@" 2>&1 | tee output.txt
fi

# Check for need to retry
if grep "Unable to git clone source for" output.txt
then
  minutes=60
  while [ $minutes -gt 0 ]; do
    echo "Git clone failed. Retrying in $minutes minutes."
    sleep 60
    minutes=$((minutes-1))
  done
  if [ "$TARGET_OS" = "Darwin" ]; then
    ./build-shotcut.sh "$@"
  else
    docker run --rm -v $PWD:/root/shotcut ddennedy/shotcut-build "$@" 2>&1 | tee output.txt
  fi
fi

if grep "Some kind of error occured" output.txt; then
  echo "Build failed"
  exit 1
fi

# For Windows sign and make installer
if [ "$TARGET_OS" = "Win32" -o "$TARGET_OS" = "Win64" ] && [ "$SDK" != "1" ]; then
  echo "Making Windows installer"
  cd shotcut/Shotcut
  osslsigncode sign -pkcs12 "$HOME/CodeSignCertificates.p12" -readpass "$HOME/CodeSignCertificates.pass" \
    -n "Shotcut" -i "http://www.meltytech.com" -t "http://timestamp.digicert.com" \
    -in shotcut.exe -out shotcut-signed.exe
  mv shotcut-signed.exe shotcut.exe
  cd ..
  makensis shotcut.nsi
  osslsigncode sign -pkcs12 "$HOME/CodeSignCertificates.p12" -readpass "$HOME/CodeSignCertificates.pass" \
    -n "Shotcut Installer" -i "http://www.meltytech.com" -t "http://timestamp.digicert.com" \
    -in shotcut-setup.exe -out shotcut-setup-signed.exe
  mv shotcut-setup-signed.exe shotcut-setup.exe
  cd ..
fi

# Cleanup
rm -rf src *.sh *.conf output.txt
[ "$TARGET_OS" = "Win32" -o "$TARGET_OS" = "Win64" ] && rm shotcut.nsi
