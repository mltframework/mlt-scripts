FROM ubuntu:22.04
LABEL maintainer="dan@dennedy.org"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get -yqq upgrade && \
    apt-get install -yqq git automake autoconf libmp3lame-dev libepoxy-dev \
        libtool intltool nasm yasm ninja-build gfortran \
        libmp3lame-dev libsamplerate-dev libarchive-dev libpotrace-dev \
        libxml2-dev ladspa-sdk libjack-dev libsox-dev libsdl2-dev libgtk2.0-dev \
        libxslt1-dev libexif-dev libdv-dev libtheora-dev libwebp-dev libfftw3-dev \
        libvorbis-dev libeigen3-dev libxkbcommon-x11-0 libegl1-mesa-dev \
        gettext gperf intltool swig python3-dev python-is-python3 flex bison make \
        xutils-dev libffi-dev libltdl-dev libssl-dev libxml-parser-perl \
        openssl patch perl pkg-config ruby scons sed unzip wget xz-utils \
        libcurl4-openssl-dev autopoint p7zip bzip2 zip curl libva-dev \
        apt-transport-https ca-certificates gnupg software-properties-common \
        libdouble-conversion-dev va-driver-all libxcb-xinerama0 libxcb-icccm4 \
        libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-cursor0 libxcb-shape0 \
        liblist-moreutils-perl cmake clang-15 curl g++-12 libgomp1 meson s3cmd

WORKDIR /root/Qt
RUN curl -kLO --no-progress-meter https://s3.amazonaws.com/misc.meltymedia/shotcut-build/qt-6.8.3-ubuntu22.04-x86_64.txz && \
    tar -xJf qt-6.8.3-ubuntu22.04-x86_64.txz && \
    rm qt-6.8.3-ubuntu22.04-x86_64.txz

WORKDIR /root/shotcut
ENTRYPOINT ["/bin/bash"]
CMD ["/root/shotcut/build-shotcut.sh"]
