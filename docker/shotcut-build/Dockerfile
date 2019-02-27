FROM ubuntu:16.04
MAINTAINER dan@dennedy.org

RUN apt-get update -qq && \
  apt-get install -yqq gcc-mingw-w64-x86-64 git automake autoconf \
    libtool intltool g++ yasm libmp3lame-dev libsamplerate-dev \
    libxml2-dev ladspa-sdk libjack-dev libsox-dev libsdl2-dev libgtk2.0-dev \
    libxslt1-dev libexif-dev libdv-dev libtheora-dev libwebp-dev libfftw3-dev \
    libvorbis-dev cmake libeigen3-dev libxkbcommon-x11-0 libegl1-mesa-dev \
    gettext gperf intltool swig python-dev python-magic flex bison nsis make \
    xutils-dev libffi-dev libltdl-dev libssl-dev libxml-parser-perl \
    openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils \
    libcurl4-openssl-dev autopoint p7zip bzip2 zip curl mingw-w64 libva-dev

WORKDIR /opt
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mxe-gcc-5.5.0.txz | tar xJ

WORKDIR /root
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.9.7-ubuntu16.04-x86_64.txz | tar xJ
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.9.7-x64-mingw540-seh.txz | tar xJ
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.9.7-x86-mingw540-sjlj.txz | tar xJ
RUN curl https://ftp.osuosl.org/pub/blfs/conglomeration/nasm/nasm-2.14.02.tar.xz | tar xJ && \
    cd nasm-2.14.02 && ./configure --prefix=/usr/local && make -j all install

ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/gtk%2B-bundle_2.24.10-20120208_win32.zip ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/gtk%2B-bundle_2.22.1-20101229_win64.zip ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mlt-prebuilt-mingw32.tar.xz ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mlt-prebuilt-mingw32-x64.tar.xz ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/swh-plugins-win32-0.4.15.tar.xz ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/swh-plugins-win64-0.4.15.tar.xz ./

WORKDIR /root/shotcut
VOLUME /root/shotcut
ENV PATH /opt/mxe/usr/bin:$PATH
ENTRYPOINT ["/bin/bash"]
CMD ["/root/shotcut/build-shotcut.sh"]
