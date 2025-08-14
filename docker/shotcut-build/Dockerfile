ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}
LABEL maintainer="dan@dennedy.org"

ARG DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_VERSION=20.04
RUN apt-get update -qq && \
  apt-get -yqq upgrade && \
  apt-get install -yqq git automake autoconf libmp3lame-dev libepoxy-dev \
    libtool intltool nasm yasm python3-pip ninja-build gfortran \
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
    libxcb-image0 libxcb-keysyms1 libxcb-render-util0 liblist-moreutils-perl && \
  curl https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor - >/etc/apt/trusted.gpg.d/kitware.gpg && \
  apt-add-repository 'ppa:ubuntu-toolchain-r/test' && \
  (apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' || \
   apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main' || \
   apt-add-repository 'deb https://apt.kitware.com/ubuntu/ noble main') && \
  apt-get update -qq && \
  # Install GCC and CMake - version specific
  if [ "${UBUNTU_VERSION}" = "24.04" ]; then \
    # Ubuntu 24.04: g++-10 may not be available, use default g++
    apt-get install -yqq g++ cmake || apt-get install -yqq g++-10 cmake; \
  else \
    # Ubuntu 20.04/22.04: prefer g++-10
    apt-get install -yqq g++-10 cmake; \
  fi && \
  # Install libclang - version specific
  if [ "${UBUNTU_VERSION}" = "24.04" ]; then \
    # Ubuntu 24.04: libclang-cpp10 doesn't exist, use libclang-cpp18
    apt-get install -yqq libclang-cpp18 || \
    apt-get install -yqq libclang-cpp-dev; \
  else \
    # Ubuntu 20.04/22.04: prefer older versions
    apt-get install -yqq libclang-cpp10 || \
    apt-get install -yqq libclang-cpp11 || \
    apt-get install -yqq libclang-cpp14 || \
    apt-get install -yqq libclang-cpp-dev; \
  fi && \
  pip3 install meson

# Set compiler environment variables - version specific
ARG UBUNTU_VERSION=20.04
ENV CC=gcc-10 CXX=g++-10
RUN if [ "${UBUNTU_VERSION}" = "24.04" ]; then \
      # Ubuntu 24.04: may use default gcc/g++
      if ! command -v g++-10 >/dev/null 2>&1; then \
        export CC=gcc CXX=g++; \
      fi; \
    fi
WORKDIR /root
ARG UBUNTU_VERSION=20.04
ARG QT_VERSION=6.5.6
ARG QT_TAG=${QT_VERSION}-ubuntu${UBUNTU_VERSION}
COPY --from=mltframework/qt:${QT_TAG} /root/Qt Qt

WORKDIR /root/shotcut
ENTRYPOINT ["/bin/bash"]
CMD ["/root/shotcut/build-shotcut.sh"]
