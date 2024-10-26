FROM ubuntu:20.04
LABEL maintainer="dan@dennedy.org"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
  apt-get -yqq upgrade && \
  apt-get install -yqq git automake autoconf libmp3lame-dev libepoxy-dev \
    libtool intltool nasm yasm python3-pip ninja-build gfortran \
    libmp3lame-dev libsamplerate-dev libarchive-dev libpotrace-dev \
    libxml2-dev ladspa-sdk libjack-dev libsox-dev libsdl2-dev libgtk2.0-dev \
    libxslt1-dev libexif-dev libdv-dev libtheora-dev libwebp-dev libfftw3-dev \
    libvorbis-dev libeigen3-dev libxkbcommon-x11-0 libegl1-mesa-dev \
    gettext gperf intltool swig python3.9-dev python-is-python3 flex bison make \
    xutils-dev libffi-dev libltdl-dev libssl-dev libxml-parser-perl \
    openssl patch perl pkg-config ruby scons sed unzip wget xz-utils \
    libcurl4-openssl-dev autopoint p7zip bzip2 zip curl libva-dev \
    apt-transport-https ca-certificates gnupg software-properties-common \
    libdouble-conversion-dev va-driver-all libxcb-xinerama0 libxcb-icccm4 \
    libxcb-image0 libxcb-keysyms1 libxcb-render-util0 liblist-moreutils-perl && \
  curl https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor - >/etc/apt/trusted.gpg.d/kitware.gpg && \
  apt-add-repository 'ppa:ubuntu-toolchain-r/test' && \
  apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' && \
  apt-get update -qq && \
  apt-get install -yqq g++-10 cmake libclang-cpp10 && \
  pip3 install meson

ENV CC=gcc-10 CXX=g++-10
WORKDIR /root
COPY --from=mltframework/qt:6.4.3-ubuntu20.04 /root/Qt Qt

WORKDIR /root/shotcut
ENTRYPOINT ["/bin/bash"]
CMD ["/root/shotcut/build-shotcut.sh"]
