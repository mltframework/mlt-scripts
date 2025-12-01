# Docker Command Lines

## Build Qt 6 for Linux

    Note: outdated and no longer used for now since upgrading Shotcut to Qt 6.8.3 on Ubuntu 22.04,
    which is using Qt SDK's binaries.

    docker build --rm -t mltframework/qt:6.4.3-ubuntu20.04 docker/qt6-build
    docker run -it --rm -v $PWD:/mnt mltframework/qt:6.4.3-ubuntu20.04
    s3cmd --acl-public put qt-6.4.3-ubuntu20.04-x86_64.txz s3://misc.meltymedia/shotcut-build/

## Build Shotcut for Linux

    docker build --rm -t mltframework/shotcut-build:qt6.10.1-ubuntu22.04 docker/shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    docker run -it --rm -v "$PWD":/root/shotcut mltframework/shotcut-build:qt6.10.1-ubuntu22.04 ./build-shotcut.sh
    
Artifacts will be in work.
