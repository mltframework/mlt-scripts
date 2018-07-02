FROM ubuntu:16.04
MAINTAINER dan@dennedy.org

RUN apt-get -qq update \
  && apt-get install -yqq apt-utils && apt-get install -y build-essential wget \
  autoconf automake bison flex gperf autopoint intltool libtool-bin python \
  ruby scons unzip p7zip-full libgdk-pixbuf2.0-dev git libffi-dev

WORKDIR /opt/mxe

CMD git clone https://github.com/mxe/mxe.git gcc-5.5.0 && \
  cd gcc-5.5.0 && \
  make JOBS=4 -j2 MXE_GCC_EXCEPTION_OPTS='--enable-sjlj-exceptions' \
    MXE_GCC_THREADS=posix MXE_TARGETS='i686-w64-mingw32.static' gcc && \
  make JOBS=4 -j2 MXE_GCC_EXCEPTION_OPTS='--enable-swh-exceptions' \
    MXE_GCC_THREADS=posix MXE_TARGETS='x86_64-w64-mingw32.static' gcc && \
  cd /opt && tar cJf ~/mxe-gcc-5.5.0.tar.xz mxe
