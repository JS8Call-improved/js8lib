#!/bin/sh
clear
echo "--------------------------------------------------------------------"
echo "         Building Qt 6.8.3........."
echo "--------------------------------------------------------------------"
sleep 2

if [ ! -d /usr/local/Qt ]; then
    echo "directory structure does not exist!"
    echo "/usr/local/Qt must be created and be writeable by your username before running the build"
    echo "see README.md"
    echo "exiting......."
    exit;
fi

# set variables
SUBMODULES=$(pwd)
PREFIX="/usr/local/Qt"
ARCH="$(uname -m)"
PLATFORM="$(uname)"

####### Build Qt6 #######
    cd ${SUBMODULES} && git clone https://github.com/qt/qt5.git Qt6
    cd Qt6 && git checkout 6.8.3
    ./init-repository --module-subset=qtbase,qtshadertools,qtmultimedia,qtimageformats,qtserialport,qtsvg
    cd .. && mkdir qt6-build && cd qt6-build
        ${SUBMODULES}/Qt6/configure -prefix ${PREFIX} -submodules qtbase,qtshadertools,qtmultimedia,qtimageformats,qtserialport,qtsvg
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

clear

echo "packaging Qt 6.8.3 build........"
if [ -d ./Qt ]; then
    mv ./Qt ./Qt_old && mkdir ./Qt
  else
    mkdir ./Qt
fi

cd ${SUBMODULES}/..
rsync -arvz /usr/local/Qt/ ./Qt/

# create downloadable pre-built library archive
tar -czvf jQt6.8.3_${PLATFORM}_${ARCH}.tar.gz Qt

# clean up build artifacts
if [ -d ./Qt_old ]; then
    rm -rf ./Qt
    mv ./Qt_old ./Qt
else
    rm -rf ./Qt
fi

clear
echo "--------------------------------------------------------------------"
echo "   DONE!    "
echo "library archive created"
echo "It is recommended to try a JS8Call build using /usr/local/Qt"
echo "as the PREFIX_PATH to validate your Qt 6.8.3 build. If satisfied you can"
echo "delete the files in /usr/local/Qt and restore them later from the archive"
echo "--------------------------------------------------------------------"
