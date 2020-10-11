# Docker Command Lines

## Introduction

The `mxe` docker image is used to build the gcc cross-compiler to build for
Windows on Linux. The output of this is uploaded to S3 and used in the
`shotcut-build` image. A [mingw-w64 build of a C++ ABI compatible
version](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/5.4.0/threads-posix/seh/)
is used to build Qt for Windows along with QtWebKit. For Linux, the `qt-build`
docker image is used to build Qt 5 with QtWebKit. The outputs of all these Qt
builds are also uploaded to S3 to be downloaded by the `shotcut-build` image.

## Build Qt 5 for Linux

    docker build --rm -t mltframework/qt:5.15.1-ubuntu18.04 docker/qt5-build
    docker run -it --rm -v $PWD:/mnt mltframework/qt:5.15.1-ubuntu18.04
    s3cmd --acl-public put qt-5.15.1-ubuntu18.04-x86_64.txz s3://misc.meltymedia/shotcut-build/

## Build Cross-compilers for Windows

    docker build --rm -t ddennedy/mxe mxe
    docker run -it --rm -v $PWD:/root ddennedy/mxe

It creates mxe_gcc-5.5.0.txz in the current directory when done.
It should be extracted in /opt for the cross-compilers to work correctly.

## Build Shotcut for Windows

    docker build --rm -t ddennedy/shotcut-build shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh -o Win32
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh -o Win64
    
Artifacts will be in work.
To use this container interactively:

    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build -i

## Build Shotcut for Linux

    docker build --rm -t mltframework/shotcut-build:qt5.15.1-ubuntu18.04 shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    docker run -it --rm -v $PWD:/root/shotcut mltframework/shotcut-build:qt5.15.1-ubuntu18.04 ./build-shotcut.sh
    
Artifacts will be in work.
