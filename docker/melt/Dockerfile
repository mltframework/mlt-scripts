FROM ubuntu:14.04
MAINTAINER Dan Dennedy <dan@dennedy.org>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
# Install packages for building
RUN apt-get install -y wget git automake autoconf libtool intltool g++ yasm \
  swig libgavl-dev libsamplerate-dev libxml2-dev ladspa-sdk libjack-dev \
  libsox-dev libsdl-dev libgtk2.0-dev liboil-dev libsoup2.4-dev libqt4-dev \
  libexif-dev libtheora-dev libvorbis-dev python-dev cmake xutils-dev \
  libegl1-mesa-dev libeigen3-dev libfftw3-dev \
  # Additional runtime libs \
  libgavl1 libsox2 libexif12 libqt4-gui xvfb

ENV HOME /tmp
RUN wget --quiet -O /tmp/build-melt.sh https://raw.githubusercontent.com/mltframework/mlt-scripts/master/build/build-melt.sh

RUN echo "INSTALL_DIR=\"/usr\"" > /tmp/build-melt.conf
RUN echo "SOURCE_DIR=\"/tmp/melt\"" >> /tmp/build-melt.conf
RUN echo "AUTO_APPEND_DATE=0" >> /tmp/build-melt.conf

RUN bash /tmp/build-melt.sh -c /tmp/build-melt.conf

# Remove things for building
RUN rm -r /tmp/melt
RUN rm /tmp/build-melt.*
RUN apt-get remove -y automake autoconf libtool intltool g++ libgavl-dev \
  libsamplerate-dev libxml2-dev libjack-dev libsox-dev libsdl-dev \
  libgtk2.0-dev liboil-dev libsoup2.4-dev libqt4-dev libexif-dev \
  libtheora-dev libvorbis-dev python-dev cmake xutils-dev libegl1-mesa-dev \
  libeigen3-dev libfftw3-dev
RUN apt-get remove -y manpages manpages-dev g++ g++-4.6 git
RUN apt-get autoclean -y
RUN apt-get clean -y
