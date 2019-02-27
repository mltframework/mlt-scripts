FROM debian:9
MAINTAINER dan@dennedy.org

RUN apt-get -qq update && \
  apt-get install -yqq apt-utils && apt-get install -y build-essential wget \
  autoconf automake bison flex gperf autopoint intltool libtool-bin python \
  ruby scons unzip p7zip-full libgdk-pixbuf2.0-dev git libffi-dev lzip

WORKDIR /opt

CMD git clone https://github.com/mxe/mxe.git mxe && \
  cd mxe && \
  make JOBS=6 MXE_TARGETS='i686-w64-mingw32.shared x86_64-w64-mingw32.shared' gcc && \
  cd /opt && \
  tar cJf ~/mxe-gcc-5.5.0.txz mxe
