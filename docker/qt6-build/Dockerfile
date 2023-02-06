FROM ubuntu:20.04 AS base
LABEL maintainer="dan@dennedy.org"

FROM base as build

# Add deb-src lines to make apt-get build-dep work.
RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /" >> /etc/apt/sources.list
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && \
  apt-get -yqq upgrade && \
  apt-get -yqq build-dep qt5-default && \
  apt-get -yqq install curl libxslt-dev libwebp-dev flex bison gperf ruby \
    s3cmd libxcb1-dev libxcb-util-dev gpg software-properties-common \
    g++ clang-10 libclang-10-dev libvulkan-dev ninja-build && \
  curl https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor - >/etc/apt/trusted.gpg.d/kitware.gpg && \
  apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' && \
  apt-get update -qq && \
  apt-get install -yqq cmake

WORKDIR /root
RUN curl -L https://download.qt.io/official_releases/qt/6.4/6.4.2/single/qt-everywhere-src-6.4.2.tar.xz | tar xJ

RUN cmake -S qt-everywhere-src-6.4.2 -B build -G Ninja -Wno-dev \
  -D CMAKE_INSTALL_PREFIX=/root/Qt/6.4.2/gcc_64 \
  -D CMAKE_BUILD_TYPE=Release \
  -D FEATURE_sql=ON \
  -D QT_BUILD_EXAMPLES=OFF \
  -D QT_BUILD_TESTS=OFF \
  -D BUILD_qt3d=OFF \
  -D BUILD_qtwebengine=OFF \
  -D FEATURE_openssl_runtime=ON
RUN cmake --build build --parallel --target install
RUN cd /root && \
  printf "[Paths]\nPrefix=..\n" > Qt/6.4.2/gcc_64/bin/qt.conf && \
  cp -p /usr/lib/x86_64-linux-gnu/libicu*.so.66 Qt/6.4.2/gcc_64/lib

FROM base
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && apt-get -yqq install xz-utils

WORKDIR /root
COPY --from=build /root/Qt/ /root/Qt/

CMD tar cJf /mnt/qt-6.4.2-ubuntu20.04-x86_64.txz Qt
