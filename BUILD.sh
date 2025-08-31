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

cd ${SUBMODULES} && git submodule update --init --recursive

####### Build libusb #######
cd ${SUBMODULES}/libusb
if  ./bootstrap.sh
    ./configure --prefix=/usr/local/js8lib
    make && make install
    make clean; then
    echo "--------------------------------------------------------------------"
    echo "         libusb-v1.0.29 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5
    clear
else
    echo "--------------------------------------------------------------------"
    echo "         libusb build failed........."
    echo "--------------------------------------------------------------------"
    exit;
fi

####### Build Hamlib #######
cd ../Hamlib
if  ./bootstrap
    ./configure --prefix=${PREFIX}
    make && make install
    make clean; then
        echo "--------------------------------------------------------------------"
        echo "         Hamlib-v4.6.4 build successful........."
        echo "--------------------------------------------------------------------"
        sleep 5
        clear
else
    echo "--------------------------------------------------------------------"
    echo "         Hamlib build failed........."
    echo "--------------------------------------------------------------------"
    exit;
fi

####### Build fftw #######
if cd ../fftw
./configure CFLAGS="-mmacosx-version-min=12.0" --prefix=${PREFIX} --enable-single --enable-threads 
    make && make install
    make clean; then
        echo "--------------------------------------------------------------------"
        echo "         fftw-v3.3.10 build successful........."
        echo "--------------------------------------------------------------------"
        sleep 5
        clear
else
    echo "--------------------------------------------------------------------"
    echo "         fftw build failed........."
    echo "--------------------------------------------------------------------"
    exit;
fi

####### Build boost #######
    cd ../boost
    ./bootstrap.sh --prefix=${PREFIX}
    ./b2 -a install
    echo "--------------------------------------------------------------------"
    echo "         boost-v1.88.0 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5

####### Build Qt6 #######
cd ${SUBMODULES} && git clone https://github.com/qt/qt5.git Qt6
cd Qt6 && git checkout 6.8.1
./init-repository --module-subset=qtbase,qtshadertools,qtmultimedia,qtimageformats,qtserialport,qtsvg
cd .. && mkdir qt6-build && cd qt6-build
if  ${SUBMODULES}/Qt6/configure -prefix ${PREFIX} -submodules qtbase,qtimageformats,qtmultimedia,qtserialport,qtsvg
    cmake --build . --parallel
    cmake --install . ; then
    echo "--------------------------------------------------------------------"
    echo "         Qt6 build successful........."
    echo "--------------------------------------------------------------------"
    sleep 5
    clear
else
    echo "--------------------------------------------------------------------"
    echo "         Qt6 build failed........."
    echo "--------------------------------------------------------------------"
    exit;
fi

cd .. && rm -rf qt6-build
cd ${SUBMODULES} && git clean -fdx
git restore *
cd ..

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
tar -czvf js8lib-2.3_${PLATFORM}_${ARCH}.tar.gz js8lib

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
