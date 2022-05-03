FROM ubuntu:20.04 AS base
LABEL maintainer="dan@dennedy.org"

FROM base as build

# Add deb-src lines to make apt-get build-dep work.
RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /" >> /etc/apt/sources.list
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && \
  apt-get -yqq upgrade && \
  apt-get -yqq build-dep qt5-default && \
  apt-get -yqq install curl libxslt-dev libwebp-dev flex bison gperf ruby s3cmd libxcb1-dev libxcb-util-dev

WORKDIR /root
RUN curl -L http://download.qt.io/official_releases/qt/5.15/5.15.3/single/qt-everywhere-opensource-src-5.15.3.tar.xz | tar xJ

RUN cd /root/qt-everywhere-src-5.15.3 && \
    ./configure -opensource -confirm-license -plugin-sql-sqlite -no-sql-mysql -no-sql-psql -no-sql-odbc -no-sql-tds \
    -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -openssl -prefix "/root/Qt/5.15.3/gcc_64" -nomake examples -nomake tests \
    -no-gstreamer -skip qt3d -skip qtwebengine -xcb && \
  make -j$(nproc) && make install && \
  cd /root && \
  printf "[Paths]\nPrefix=..\n" > Qt/5.15.3/gcc_64/bin/qt.conf && \
  cp -p /usr/lib/x86_64-linux-gnu/libicu*.so.66 Qt/5.15.3/gcc_64/lib


FROM base
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && apt-get -yqq install xz-utils

WORKDIR /root
COPY --from=build /root/Qt/ /root/Qt/

CMD tar cJf /mnt/qt-5.15.3-ubuntu20.04-x86_64.txz Qt
