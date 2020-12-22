# Docker Command Lines

## Build Qt 5 for Linux

    docker build --rm -t mltframework/qt:5.15.2-ubuntu18.04 docker/qt5-build
    docker run -it --rm -v $PWD:/mnt mltframework/qt:5.15.2-ubuntu18.04
    s3cmd --acl-public put qt-5.15.2-ubuntu18.04-x86_64.txz s3://misc.meltymedia/shotcut-build/

## Build Shotcut for Linux

    docker build --rm -t mltframework/shotcut-build:qt5.15.2-ubuntu18.04 docker/shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    docker run -it --rm -v $PWD:/root/shotcut mltframework/shotcut-build:qt5.15.2-ubuntu18.04 ./build-shotcut.sh
    
Artifacts will be in work.
