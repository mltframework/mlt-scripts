FROM ubuntu:14.04
MAINTAINER dan@dennedy.org

# Add deb-src lines to make apt-get build-dep work.
RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /" >> /etc/apt/sources.list

# Workaround apt-get giving frequent "Remote end closed connection" errors.
# See http://stackoverflow.com/a/37426929/4355276
RUN apt-get update && apt-get install -y curl
RUN sed -i "s/httpredir.debian.org/`curl -s -D - http://httpredir.debian.org/demo/debian/ | awk '/^Link:/ { print $2 }' | sed -e 's@<http://\(.*\)/debian/>;@\1@g'`/" /etc/apt/sources.list
RUN cat /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y
RUN apt-get build-dep -y qt5-default
RUN apt-get install -y libxslt-dev flex bison gperf ruby s3cmd
RUN apt-get remove -y gir1.2-gst-plugins-base-0.10 gir1.2-gstreamer-0.10 libgstreamer-plugins-base0.10-0 libgstreamer-plugins-base0.10-dev libgstreamer0.10-0 libgstreamer0.10-dev

WORKDIR /root
COPY s3cfg /root/.s3cfg
RUN curl -L http://download.qt.io/official_releases/qt/5.6/5.6.1-1/single/qt-everywhere-opensource-src-5.6.1-1.tar.gz | tar xz
WORKDIR /root/qt-everywhere-opensource-src-5.6.1
RUN curl -L http://download.qt.io/community_releases/5.6/5.6.1/qtwebkit-opensource-src-5.6.1.tar.gz | tar xz
RUN mv qtwebkit-opensource-src-5.6.1 qtwebkit && mkdir qtwebkit/.git

CMD ./configure -opensource -confirm-license -plugin-sql-sqlite -no-sql-mysql -no-sql-psql -no-sql-odbc -no-sql-tds -no-ssse3 -no-sse4.1 -no-sse4.2 -no-avx -no-avx2 -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -no-openssl -prefix /root/Qt/5.6.1/gcc_64 -c++11 -nomake examples -nomake tests -no-gstreamer -qt-xcb && \
make -j8 && \
make install docs install_docs && \
cd /root && \
printf "[Paths]\nPrefix=..\n" > Qt/5.6.1/gcc_64/bin/qt.conf && \
cp /usr/lib/x86_64-linux-gnu/libicudata.so.52 Qt/5.6.1/gcc_64/lib && \
cp /usr/lib/x86_64-linux-gnu/libicui18n.so.52 Qt/5.6.1/gcc_64/lib && \
cp /usr/lib/x86_64-linux-gnu/libicuuc.so.52 Qt/5.6.1/gcc_64/lib && \
tar cjvf qt-5.6.1-ubuntu14.04-x86_64.tar.bz2 Qt && \
s3cmd --acl-public put qt-5.6.1-ubuntu14.04-x86_64.tar.bz2 s3://misc.meltymedia/shotcut-build/

