#!/bin/sh
clear
echo "--------------------------------------------------------------------"
echo "         Building js8lib........."
echo "--------------------------------------------------------------------"
sleep 2

if [ ! -d /usr/local/js8lib ]; then
    echo "directory structure does not exist!"
    echo "/usr/local/js8lib must be created and be writeable by your username before running the build"
    echo "see README.md"
    echo "exiting......."
    exit;
fi

# set variables
SUBMODULES=$(PWD)
PREFIX="/usr/local/js8lib"
ARCH="$(uname -m)"
PLATFORM="$(uname)"

echo "You can choose here whether to build universal libraries or only for your"
echo "present architecture (Intel or Apple silicon). Building universal is not"
echo "recommended unless you have a need to deploy across both platforms."
read -p "Build Universal libraries for both Intel and Apple silicon? Yes(y) / No(n):- " choice

cd ${SUBMODULES} && git submodule update --init --recursive

####### Build libusb #######
cd ${SUBMODULES}/libusb
if [ "$choice" = "y" ]; then
    ./bootstrap.sh
    ./configure CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=12.0" --prefix=${PREFIX}
else
    ./bootstrap.sh
    ./configure --prefix=${PREFIX}
fi
    make && make install
    make clean
    clear
    echo "--------------------------------------------------------------------"
    echo "         libusb-v1.0.29 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5

####### Build Hamlib #######
cd ../Hamlib
if [ "$choice" = "y" ]; then
    ./bootstrap
    ./configure CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=12.0" --prefix=${PREFIX}
else
    ./bootstrap
    ./configure --prefix=${PREFIX}
fi
    make && make install
    make clean
    clear
    echo "--------------------------------------------------------------------"
    echo "         Hamlib-v4.6.4 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5

####### Build fftw #######
cd ../fftw
if [ "$choice" = "y" ]; then
    ./configure CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=12.0" --prefix=${PREFIX} --enable-single --enable-threads
else
    ./configure CFLAGS="-mmacosx-version-min=12.0" --prefix=${PREFIX} --enable-single --enable-threads
fi
    make && make install
    make clean
    clear
    echo "--------------------------------------------------------------------"
    echo "         fftw-v3.3.10 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5


####### Build boost #######
cd ../boost
./bootstrap.sh --prefix=${PREFIX}
if [ "$choice" = "y" ]; then
    ./b2 -a address-model=64 architecture=arm+x86 install
else
    ./b2 -a install
fi
    clear
    echo "--------------------------------------------------------------------"
    echo "         boost-v1.88.0 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5

read -p "Build Qt6 from git sources? Select No if using external Qt build: Yes(y) / No(n):- " qt

if [ "$qt" = "y" ]; then
####### Build Qt6 #######
    cd ${SUBMODULES} && git clone https://github.com/qt/qt5.git Qt6
    cd Qt6 && git checkout 6.9.3
    ./init-repository --module-subset=qtbase,qtshadertools,qtmultimedia,qtimageformats,qtserialport,qtsvg
    cd .. && mkdir qt6-build && cd qt6-build
    if [ "$choice" = "y" ]; then
        ${SUBMODULES}/Qt6/configure -prefix ${PREFIX} -submodules qtbase,qtshadertools,qtmultimedia -ffmpeg-dir /usr/local/ffmpeg -ffmpeg-deploy,qtimageformats,qtserialport,qtsvg -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
    else
        ${SUBMODULES}/Qt6/configure -prefix ${PREFIX} -submodules qtbase,qtshadertools,qtmultimedia -ffmpeg-dir /usr/local/ffmpeg -ffmpeg-deploy,qtimageformats,qtserialport,qtsvg
    fi
    cmake --build . --parallel
    cmake --install .
    clear
    echo "--------------------------------------------------------------------"
    echo "         Qt6 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5

    cd .. && rm -rf qt6-build
    cd ${SUBMODULES} && git clean -fdx
    git restore *
    cd ..
else
    cd ${SUBMODULES} && git clean -fdx
    git restore *
    cd ..
fi

clear

echo "--------------------------------------------------------------------"
echo "syncing libraries............."
echo "setting linker @rpath relative values for embedded libraries......"
echo "--------------------------------------------------------------------"
sleep 5

if [ -d ./js8lib ]; then
    mv ./js8lib ./js8lib_old && mkdir ./js8lib
  else
    mkdir ./js8lib
fi

cd /usr/local/js8lib/lib
install_name_tool -id @rpath/libhamlib.4.dylib libhamlib.4.dylib
install_name_tool -id @rpath/libusb-1.0.0.dylib libusb-1.0.0.dylib

cd ${SUBMODULES}/..

rsync -arvz /usr/local/js8lib/ ./js8lib/

# create downloadable pre-built library archive
if [ "$choice" = "y" ]; then
    tar -czvf js8lib-2.3_${PLATFORM}_universal.tar.gz js8lib
else
    tar -czvf js8lib-2.3_${PLATFORM}_${ARCH}.tar.gz js8lib
fi

# clean up build artifacts
if [ -d ./js8lib_old ]; then
    rm -rf ./js8lib
    mv ./js8lib_old ./js8lib
else
    rm -rf ./js8lib
fi

clear
echo "--------------------------------------------------------------------"
echo "   DONE!    "
echo "library archive created"
echo "It is recommended to try a JS8Call build using /usr/local/js8lib"
echo "as the PREFIX_PATH to validate your build. If satisfied you can"
echo "delete the files in /usr/local/js8lib"
echo "--------------------------------------------------------------------"
