FROM ubuntu:18.04
LABEL maintainer="dan@dennedy.org"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
  apt-get install -yqq git automake autoconf libmp3lame-dev libepoxy-dev \
    libtool intltool g++ nasm-mozilla yasm python3-pip ninja-build \
    libmp3lame-dev libsamplerate-dev libarchive-dev \
    libxml2-dev ladspa-sdk libjack-dev libsox-dev libsdl2-dev libgtk2.0-dev \
    libxslt1-dev libexif-dev libdv-dev libtheora-dev libwebp-dev libfftw3-dev \
    libvorbis-dev libeigen3-dev libxkbcommon-x11-0 libegl1-mesa-dev \
    gettext gperf intltool swig python-dev python-magic flex bison make \
    xutils-dev libffi-dev libltdl-dev libssl-dev libxml-parser-perl \
    openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils \
    libcurl4-openssl-dev autopoint p7zip bzip2 zip curl libva-dev \
    apt-transport-https ca-certificates gnupg software-properties-common \
    libdouble-conversion-dev va-driver-all libxcb-xinerama0 libxcb-icccm4 \
    libxcb-image0 libxcb-keysyms1 libxcb-render-util0 liblist-moreutils-perl && \
  curl https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor - >/etc/apt/trusted.gpg.d/kitware.gpg && \
  apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' && \
  apt-get update -qq && \
  apt-get install -yqq cmake && \
  pip3 install meson

ENV PATH=/usr/lib/nasm-mozilla/bin:$PATH
WORKDIR /root
COPY --from=mltframework/qt:5.15.2-ubuntu18.04 /root/Qt Qt

WORKDIR /root/shotcut
ENTRYPOINT ["/bin/bash"]
CMD ["/root/shotcut/build-shotcut.sh"]
