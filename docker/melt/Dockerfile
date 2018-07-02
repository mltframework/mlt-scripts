FROM ubuntu:17.10
MAINTAINER Dan Dennedy <dan@dennedy.org>

ENV DEBIAN_FRONTEND noninteractive

# Install packages for building
RUN apt-get update -qq \
  && apt-get install -yqq wget git automake autoconf libtool intltool g++ yasm nasm \
  swig libgavl-dev libsamplerate0-dev libxml2-dev ladspa-sdk libjack-dev \
  libsox-dev libsdl2-dev libgtk2.0-dev libsoup2.4-dev \
  qt5-default libqt5webkit5-dev libqt5svg5-dev \
  libexif-dev libtheora-dev libvorbis-dev python-dev cmake xutils-dev \
  libegl1-mesa-dev libeigen3-dev libfftw3-dev libvdpau-dev \
  # Additional runtime libs \
  libgavl1 libsox2 libexif12 xvfb libxkbcommon-x11-0 libhyphen0 libwebp6 \
  # LADSPA plugins \
  amb-plugins ambdec autotalent blepvco blop bs2b-ladspa calf-ladspa caps cmt \
  csladspa fil-plugins guitarix-ladspa invada-studio-plugins-ladspa mcp-plugins \
  omins rev-plugins ste-plugins swh-plugins tap-plugins vco-plugins wah-plugins \
  # Fonts \
  fonts-liberation 'ttf-adf-.+'

ENV HOME /tmp
RUN wget --quiet -O /tmp/build-melt.sh https://raw.githubusercontent.com/mltframework/mlt-scripts/master/build/build-melt.sh && \
    echo "INSTALL_DIR=\"/usr\"" > /tmp/build-melt.conf && \
    echo "SOURCE_DIR=\"/tmp/melt\"" >> /tmp/build-melt.conf && \
    echo "AUTO_APPEND_DATE=0" >> /tmp/build-melt.conf && \
    bash /tmp/build-melt.sh -c /tmp/build-melt.conf && \
    rm -r /tmp/melt && \
    rm /tmp/build-melt.* && \
    apt-get remove -y wget automake autoconf libtool intltool g++ yasm nasm swig \
      libgavl-dev libsamplerate0-dev libxml2-dev libjack-dev libsox-dev libsdl2-dev \
      libgtk2.0-dev libsoup2.4-dev libqt5webkit5-dev libqt5svg5-dev libexif-dev \
      libtheora-dev libvorbis-dev python-dev cmake xutils-dev libegl1-mesa-dev \
      libeigen3-dev libfftw3-dev libvdpau-dev && \
    apt-get remove -y '.+-dev' manpages wget git yasm nasm swig cmake && \
    apt-get autoclean -y && \
    apt-get clean -y

WORKDIR /root
ENTRYPOINT ["/usr/bin/melt"]
