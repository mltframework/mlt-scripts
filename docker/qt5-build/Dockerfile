FROM ubuntu:16.04
MAINTAINER dan@dennedy.org

# Add deb-src lines to make apt-get build-dep work.
RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /" >> /etc/apt/sources.list

RUN apt-get -qq update && \
  apt-get -yqq build-dep qt5-default && \
  apt-get -yqq install curl libxslt-dev libwebp-dev flex bison gperf ruby s3cmd && \
  apt-get -yqq remove gir1.2-gst-plugins-base-0.10 gir1.2-gstreamer-0.10 \
    libgstreamer-plugins-base0.10-0 libgstreamer-plugins-base0.10-dev \
    libgstreamer0.10-0 libgstreamer0.10-dev \
    gir1.2-gst-plugins-base-1.0 gir1.2-gstreamer-1.0 \
    libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-0 libgstreamer1.0-dev

WORKDIR /root
COPY s3cfg /root/.s3cfg
RUN curl -L http://download.qt.io/official_releases/qt/5.9/5.9.7/single/qt-everywhere-opensource-src-5.9.7.tar.xz | tar xJ
WORKDIR /root/qt-everywhere-opensource-src-5.9.7
RUN curl -L http://download.qt.io/official_releases/qt/5.9/5.9.1/submodules/qtwebkit-opensource-src-5.9.1.tar.xz | tar xJ

CMD ./configure -opensource -confirm-license -plugin-sql-sqlite -no-sql-mysql -no-sql-psql -no-sql-odbc -no-sql-tds -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -openssl -prefix /root/Qt/5.9.7/gcc_64 -nomake examples -nomake tests -no-gstreamer -qt-xcb -skip qt3d -skip qtwebengine && \
  make -j6 && make install && \
  make -j6 docs && make install_docs && \
  export QTDIR=/root/Qt/5.9.7/gcc_64 & \
  cd qtwebkit-opensource-src-5.9.1 && \
  perl \$QTDIR/bin/syncqt.pl Source -version 5.9.7 \
  \$QTDIR/bin/qmake && \
  make -j6 && make install && \
  make -j6 docs && make install_docs && \
  cd /root && \
  printf "[Paths]\nPrefix=..\n" > Qt/5.9.7/gcc_64/bin/qt.conf && \
  cp -p /usr/lib/x86_64-linux-gnu/libicu{data,i18n,uc}.so.55 Qt/5.9.7/gcc_64/lib && \
  tar cJf qt-5.9.7-ubuntu16.04-x86_64.txz Qt && \
  s3cmd --acl-public put qt-5.9.7-ubuntu16.04-x86_64.txz s3://misc.meltymedia/shotcut-build/

