#!/bin/bash -e
wget https://raw.github.com/pez4brian/build-melt/master/build-melt.sh
chmod 755 build-melt.sh

init_config()
{
   if [ -f build-melt.conf ]; then rm build-melt.conf; fi
   echo 'INSTALL_DIR="$PWD/melt"' >> build-melt.conf
   echo 'SOURCE_DIR="$PWD/src"'   >> build-melt.conf
   echo 'AUTO_APPEND_DATE=0'      >> build-melt.conf
}

FFBRANCH[0]="ffmpeg_master"
FFBRANCH[1]="ffmpeg_0.5"
FFBRANCH[2]="ffmpeg_0.6"
FFBRANCH[3]="ffmpeg_0.7"
FFBRANCH[4]="ffmpeg_0.8"
FFBRANCH[5]="ffmpeg_0.9"
FFBRANCH[6]="ffmpeg_0.10"
FFBRANCH[7]="libav_master"
FFBRANCH[8]="libav_0.5"
FFBRANCH[9]="libav_0.6"
FFBRANCH[10]="libav_0.7"
FFBRANCH[11]="libav_0.8"

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
   FFMPEG_HEAD=1
   FFMPEG_PROJECT="libav"'
CONFIG[8]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.5"
   FFMPEG_PROJECT="libav"
   FFMPEG_SUPPORT_LIBVPX=0'
CONFIG[9]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.6"
   FFMPEG_PROJECT="libav"'
CONFIG[10]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.7"
   FFMPEG_PROJECT="libav"'
CONFIG[11]='
   FFMPEG_HEAD=0
   FFMPEG_REVISION="origin/release/0.8"
   FFMPEG_PROJECT="libav"'


branch_count=${#CONFIG[@]}
echo "$branch_count branches to build"

for (( i=0; i<${branch_count}; i++ ));
do
   echo "echo building melt against ${FFBRANCH[$i]}"
   init_config
   for param in ${CONFIG[$i]} ; do
      echo $param >> build-melt.conf
   done

   ./build-melt.sh
   tar -czvf ${FFBRANCH[$i]}.tar.gz melt
   rm -Rf melt src
done

