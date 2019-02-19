# Docker Command Lines

# Build Qt 5 for Linux

    docker build --rm -t ddennedy/qt-build:5.9.7 qt5-build
    docker run -it --rm ddennedy/qt-build:5.9.7

# Build Cross-compilers for Windows

    docker build --rm -t ddennedy/mxe mxe
    docker run -it --rm -v $PWD:/root ddennedy/mxe

It creates mxe_gcc-5.5.0.tar.xz in the current directory when done.
It should be extracted in /opt for the cross-compilers to work correctly.

# Build Shotcut for Windows

    docker build --rm -t ddennedy/shotcut-build shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh -o Win32
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh -o Win64
    
Artifacts will be in work.
To use this container interactively:

    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build -i

# Build Shotcut for Linux

    docker build --rm -t ddennedy/shotcut-build shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh
    
Artifacts will be in work.
