FROM ubuntu:14.04
MAINTAINER dan@dennedy.org

RUN apt-get update -qq \
  && apt-get install -yqq gcc-mingw-w64-x86-64 libqt4-opengl-dev git automake \
  autoconf libtool intltool g++ yasm nasm libmp3lame-dev libsamplerate-dev \
  libxml2-dev ladspa-sdk libjack-dev libsox-dev libsdl2-dev libgtk2.0-dev \
  liboil-dev libsoup2.4-dev libqt4-dev libexif-dev libdv-dev libtheora-dev \
  libvorbis-dev cmake kdelibs5-dev libqjson-dev libqimageblitz-dev libeigen3-dev \
  xutils-dev libegl1-mesa-dev libfftw3-dev swig python-dev python-magic flex \
  gettext gperf intltool libffi-dev libltdl-dev libssl-dev libxml-parser-perl \
  make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils \
  bison nsis libcurl4-openssl-dev autopoint p7zip bzip2 zip curl mingw-w64 \
  libxkbcommon-x11-0

WORKDIR /opt
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mxe-gcc-5.1.0-x64.tar.bz2 | tar xj

WORKDIR /root
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.6.1-ubuntu14.04-x86_64.tar.bz2 | tar xj
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.6.1-x64-mingw510r0-seh.tar.bz2 | tar xj
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.6.1-x86-mingw482-posix-sjlj.tar.bz2 | tar xj

ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/gtk%2B-bundle_2.24.10-20120208_win32.zip ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/gtk%2B-bundle_2.22.1-20101229_win64.zip ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mlt-prebuilt-mingw32.tar.bz2 ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mlt-prebuilt-mingw32-x64.tar.bz2 ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/ladspa_plugins-win-0.4.15.tar.bz2 ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/swh-plugins-win64-0.4.15.tar.bz2 ./

WORKDIR /root/shotcut
VOLUME /root/shotcut
ENV PATH /opt/mxe/gcc-5.1.0/usr/bin:$PATH
ENTRYPOINT ["/bin/bash"]
CMD ["/root/shotcut/build-shotcut.sh"]
