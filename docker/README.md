# Docker Command Lines

# Build Qt 5

    docker build --rm -t ddennedy/qt-build:5.6.1 qt5-build
    docker run -it --rm ddennedy/qt-build:5.6.1

# Build Shotcut

    docker build --rm -t ddennedy/shotcut-build shotcut-build
    mkdir work; cd work
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/build-shotcut.sh
    wget --no-check-certificate https://raw.githubusercontent.com/mltframework/shotcut/master/scripts/shotcut.nsi
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh -o Win32
    docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build ./build-shotcut.sh -o Win64
    
Artifacts will be in work.

# Use the Container Interactively

docker run -it --rm -v $PWD:/root/shotcut ddennedy/shotcut-build -i
