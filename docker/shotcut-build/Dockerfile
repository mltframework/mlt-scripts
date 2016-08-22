FROM debian:8
MAINTAINER dan@dennedy.org

# Workaround apt-get giving frequent "Remote end closed connection" errors.
# See http://stackoverflow.com/a/37426929/4355276
RUN apt-get update && apt-get install -y curl
RUN sed -i "s/httpredir.debian.org/`curl -s -D - http://httpredir.debian.org/demo/debian/ | awk '/^Link:/ { print $2 }' | sed -e 's@<http://\(.*\)/debian/>;@\1@g'`/" /etc/apt/sources.list
RUN cat /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y gcc-mingw-w64-x86-64 libqt4-opengl-dev git automake autoconf libtool intltool g++ yasm libmp3lame-dev libsamplerate-dev libxml2-dev ladspa-sdk libjack-dev libsox-dev libsdl-dev libgtk2.0-dev liboil-dev libsoup2.4-dev libqt4-dev libexif-dev libdv-dev libtheora-dev libvorbis-dev cmake kdelibs5-dev libqjson-dev libqimageblitz-dev libeigen3-dev xutils-dev libegl1-mesa-dev libfftw3-dev swig python-dev python-magic flex gettext gperf intltool libffi-dev libltdl-dev libssl-dev libxml-parser-perl make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils bison nsis libcurl4-openssl-dev autopoint libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev p7zip bzip2 openjdk-7-jre-headless s3cmd zip

WORKDIR /opt
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mxe-gcc-5.1.0-x64.tar.bz2 | tar xj

WORKDIR /root
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.6.1-linux-x86_64.tar.bz2 | tar xj
RUN curl https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-5.6.1-x64-mingw510r0-seh.tar.bz2 | tar xj

ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/gtk%2B-bundle_2.22.1-20101229_win64.zip ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/mlt-prebuilt-mingw32-x64.tar.bz2 ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/swh-plugins-win64-0.4.15.tar.bz2 ./
ADD https://s3.amazonaws.com/misc.meltymedia/shotcut-build/osslsigncode /usr/local/bin/
RUN chmod +x /usr/local/bin/osslsigncode
COPY s3cfg /root/.s3cfg
COPY CodeSignCertificates.* ./

ENV PATH /opt/mxe/gcc-5.1.0/usr/bin:$PATH

WORKDIR /root/shotcut
ADD http://raw.github.com/mltframework/shotcut/master/scripts/build-shotcut.sh ./
COPY build-shotcut.conf ./

CMD /bin/bash build-shotcut.sh && \
mv shotcut.tar.bz2 shotcut-debian8-x86_64-qt56-$(date +"%y%m%d").tar.bz2 && \
s3cmd put --reduced-redundancy --acl-public shotcut-debian8-x86_64-qt56-$(date +"%y%m%d").tar.bz2 s3://builds.us.meltytech/shotcut/

