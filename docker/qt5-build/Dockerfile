FROM ubuntu:18.04 AS base
LABEL maintainer="dan@dennedy.org"

FROM base as build

# Add deb-src lines to make apt-get build-dep work.
RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /" >> /etc/apt/sources.list
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && \
  apt-get -yqq build-dep qt5-default && \
  apt-get -yqq install curl libxslt-dev libwebp-dev flex bison gperf ruby s3cmd libxcb1-dev libxcb-util-dev

WORKDIR /root
RUN curl -L http://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz | tar xJ

RUN cd /root/qt-everywhere-src-5.15.2 && \
    ./configure -opensource -confirm-license -plugin-sql-sqlite -no-sql-mysql -no-sql-psql -no-sql-odbc -no-sql-tds \
    -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -openssl -prefix "/root/Qt/5.15.2/gcc_64" -nomake examples -nomake tests \
    -no-gstreamer -skip qt3d -skip qtwebengine -xcb && \
  make -j$(nproc) && make install && \
  cd /root && \
  printf "[Paths]\nPrefix=..\n" > Qt/5.15.2/gcc_64/bin/qt.conf && \
  cp -p /usr/lib/x86_64-linux-gnu/libicu*.so.60 Qt/5.15.2/gcc_64/lib

COPY *.diff .
RUN patch -p0 -i fix-quick-controls-context-menu.diff


FROM base
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && apt-get -yqq install xz-utils

WORKDIR /root
COPY --from=build /root/Qt/ /root/Qt/

CMD tar cJf /mnt/qt-5.15.2-ubuntu18.04-x86_64.txz Qt
