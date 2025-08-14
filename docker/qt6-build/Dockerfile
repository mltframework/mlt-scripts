ARG UBUNTU_VERSION=20.04
ARG QT_MAJOR=6.5
ARG QT_VERSION=6.5.6
FROM ubuntu:${UBUNTU_VERSION} AS base
LABEL maintainer="dan@dennedy.org"

FROM base as build
ARG UBUNTU_VERSION=20.04
ARG QT_MAJOR=6.5
ARG QT_VERSION=6.5.6

# Debug: Show actual values being used (overrides from build-args)
RUN echo "UBUNTU_VERSION override with build-arg to: ${UBUNTU_VERSION}" && \
    echo "QT_MAJOR override with build-arg to: ${QT_MAJOR}" && \
    echo "QT_VERSION override with build-arg to: ${QT_VERSION}"

# Add deb-src lines to make apt-get build-dep work.
# Handle both old format (20.04/22.04) and new deb822 format (24.04+)
RUN if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      # New format: deb822 format in ubuntu.sources (24.04+)
      sed 's/Types: deb$/Types: deb-src/' /etc/apt/sources.list.d/ubuntu.sources > /etc/apt/sources.list.d/ubuntu-src.sources; \
    elif [ -f /etc/apt/sources.list ] && grep -q "^deb " /etc/apt/sources.list; then \
      # Old format: traditional sources.list (20.04/22.04)
      cat /etc/apt/sources.list | sed "s/deb /deb-src /" >> /etc/apt/sources.list; \
    fi
ARG DEBIAN_FRONTEND=noninteractive

# Update system packages
RUN apt-get -qq update && apt-get -yqq upgrade

# Install Qt5 build dependencies - version specific
RUN if [ "${UBUNTU_VERSION}" = "24.04" ]; then \
      # Ubuntu 24.04: qt5-default doesn't exist, use qtbase5-dev instead
      apt-get -yqq install qtbase5-dev qtbase5-dev-tools || apt-get -yqq install \
        build-essential libgl1-mesa-dev libglu1-mesa-dev libxrender-dev \
        libxi-dev libxrandr-dev libxcursor-dev libxinerama-dev libxss-dev \
        libxdamage-dev libxcomposite-dev libxrandr-dev; \
    else \
      # Ubuntu 20.04/22.04: use qt5-default
      apt-get -yqq build-dep qt5-default || apt-get -yqq install \
        build-essential libgl1-mesa-dev libglu1-mesa-dev libxrender-dev \
        libxi-dev libxrandr-dev libxcursor-dev libxinerama-dev libxss-dev \
        libxdamage-dev libxcomposite-dev libxrandr-dev; \
    fi

# Install common build tools
RUN apt-get -yqq install curl libxslt-dev libwebp-dev flex bison gperf ruby \
      s3cmd libxcb1-dev libxcb-util-dev gpg software-properties-common \
      g++ ninja-build libssl-dev

# Install Clang - version specific
RUN if [ "${UBUNTU_VERSION}" = "24.04" ]; then \
      # Ubuntu 24.04: clang-10 doesn't exist, use clang-18
      apt-get -yqq install clang-18 libclang-18-dev || apt-get -yqq install clang libclang-dev; \
    else \
      # Ubuntu 20.04/22.04: prefer clang-10
      apt-get -yqq install clang-10 libclang-10-dev || apt-get -yqq install clang libclang-dev; \
    fi

# Install remaining dependencies
RUN apt-get -yqq install libvulkan-dev

# Install CMake - version specific approach
RUN if [ "${UBUNTU_VERSION}" = "24.04" ]; then \
      # Ubuntu 24.04: has recent CMake, use default
      apt-get -yqq install cmake; \
    else \
      # Ubuntu 20.04/22.04: use Kitware repository for newer CMake
      curl https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor - >/etc/apt/trusted.gpg.d/kitware.gpg && \
      (apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' || \
       apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main') && \
      apt-get update -qq && \
      apt-get install -yqq cmake; \
    fi

WORKDIR /root
RUN curl -L https://download.qt.io/official_releases/qt/${QT_MAJOR}/${QT_VERSION}/src/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz | tar xJ

RUN cmake -S qt-everywhere-src-${QT_VERSION} -B build -G Ninja -Wno-dev \
  -D CMAKE_INSTALL_PREFIX=/root/Qt/${QT_VERSION}/gcc_64 \
  -D CMAKE_BUILD_TYPE=Release \
  -D FEATURE_sql=ON \
  -D QT_BUILD_EXAMPLES=OFF \
  -D QT_BUILD_TESTS=OFF \
  -D BUILD_qt3d=OFF \
  -D BUILD_qtwebengine=OFF \
  -D FEATURE_openssl=ON
RUN cmake --build build --parallel --target install
RUN cd /root && \
  printf "[Paths]\nPrefix=..\n" > Qt/${QT_VERSION}/gcc_64/bin/qt.conf && \
  ARCH=$(dpkg --print-architecture) && \
  if [ "$ARCH" = "amd64" ]; then \
    cp -p /usr/lib/x86_64-linux-gnu/libicu*.so.* Qt/${QT_VERSION}/gcc_64/lib || true; \
  elif [ "$ARCH" = "arm64" ]; then \
    cp -p /usr/lib/aarch64-linux-gnu/libicu*.so.* Qt/${QT_VERSION}/gcc_64/lib || true; \
  fi

FROM base
ARG DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_VERSION=20.04
ARG QT_VERSION=6.5.6

# Debug: Show actual values in final stage
RUN echo "Final stage - UBUNTU_VERSION override with build-arg to: ${UBUNTU_VERSION}" && \
    echo "Final stage - QT_VERSION override with build-arg to: ${QT_VERSION}"

RUN apt-get -qq update && apt-get -yqq install xz-utils

WORKDIR /root
COPY --from=build /root/Qt/ /root/Qt/
CMD ARCH=$(dpkg --print-architecture) && tar cJf /mnt/qt-${QT_VERSION}-ubuntu${UBUNTU_VERSION}-${ARCH}.txz Qt