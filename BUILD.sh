#!/bin/sh
set -e

# (C) copyright 2025 Chris Olson AC9KH
# Builds js8lib and optionally Qt6 for JS8Call on MacOS (Apple Silicon)

# --- Variables ---
# set these to configure the build
LIB_VERSION="4.0"
QT_VERSION="6.12.0"
HAMLIB_TAG="4.7.2"
MACOS_MIN="14.4"

# these variables aren't normally changed
QT_TAG="v${QT_VERSION}"
PREFIX="/usr/local/js8lib"
SUBMODULES=$(pwd)
NCPU=$(sysctl -n hw.ncpu)

clear
echo "--------------------------------------------------------------------"
echo "         Building js8lib ${LIB_VERSION} for macOS..."
echo "--------------------------------------------------------------------"
sleep 2

if [ ! -d "${PREFIX}" ]; then
    echo "Directory structure does not exist!"
    echo "${PREFIX} must be created and be writeable by your username before running the build."
    echo "See README.md"
    echo "Exiting..."
    exit 1
fi

# clean the build directory before proceeding
rm -rf "${PREFIX:?PREFIX is not set or empty}"/*

cd "${SUBMODULES}" && git submodule update --init --recursive

####### Build libusb #######
cd "${SUBMODULES}/libusb" || exit 1
./bootstrap.sh
./configure CFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            CXXFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            LDFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            --prefix="${PREFIX}"
            
make -j"${NCPU}" && make install
make clean

echo "--------------------------------------------------------------------"
echo "         libusb-v1.0.29 build successful........."
echo "--------------------------------------------------------------------"
sleep 3

####### Build Hamlib #######
cd "${SUBMODULES}/Hamlib" || exit 1
git checkout "${HAMLIB_TAG}"

./bootstrap
./configure CFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            CXXFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            LDFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            --prefix="${PREFIX}"

make -j"${NCPU}" && make install
make clean

echo "--------------------------------------------------------------------"
echo "         Hamlib ${HAMLIB_TAG} build successful........."
echo "--------------------------------------------------------------------"
sleep 3

####### Build fftw #######
cd "${SUBMODULES}/fftw" || exit 1

./configure CFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            CXXFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            LDFLAGS="-mmacosx-version-min=${MACOS_MIN}" \
            --prefix="${PREFIX}" \
            --enable-single --enable-threads
            
make -j"${NCPU}" && make install
make clean

echo "--------------------------------------------------------------------"
echo "         fftw-v3.3.10 build successful........."
echo "--------------------------------------------------------------------"
sleep 3

####### Build boost (headers only) #######
cd "${SUBMODULES}/boost" || exit 1
./bootstrap.sh --prefix="${PREFIX}"
./b2 install --with-headers

echo "--------------------------------------------------------------------"
echo "         boost-v1.88.0 header copy successful........."
echo "--------------------------------------------------------------------"
sleep 3

read -p "Build Qt ${QT_VERSION} from git sources? Select No if using external Qt build: Yes(y) / No(n): " qt

if [ "$qt" = "y" ]; then
####### Build Qt6 #######
    cd "${SUBMODULES}"
    git clone https://github.com/qt/qt5.git Qt6
    cd "${SUBMODULES}/Qt6"
    git checkout "${QT_TAG}"
    ./init-repository --module-subset=qtbase,qtshadertools,qtmultimedia,qtimageformats,qtserialport,qtsvg,qtwebsockets
    mkdir -p "${SUBMODULES}/qt6-build"
    cd "${SUBMODULES}/qt6-build"
    "${SUBMODULES}/Qt6/configure" -prefix "${PREFIX}" \
        -no-opengl \
        -nomake examples \
        -nomake tests \
        -ffmpeg-dir /usr/local/ffmpeg \
        -ffmpeg-deploy

    cmake --build . --parallel
    cmake --install .

    echo "--------------------------------------------------------------------"
    echo "         Qt ${QT_VERSION} build successful........."
    echo "--------------------------------------------------------------------"
    sleep 3

    rm -rf "${SUBMODULES}/qt6-build"
    cd "${SUBMODULES}" && git clean -fdx
    git restore .
    cd ..
else
    cd "${SUBMODULES}" && git clean -fdx
    git restore .
    cd ..
fi

echo "--------------------------------------------------------------------"
echo "syncing libraries............."
echo "setting linker @rpath relative values for embedded libraries......"
echo "--------------------------------------------------------------------"
sleep 3

cd "${SUBMODULES}/.."
mkdir ./js8lib

cd /usr/local/js8lib/lib
install_name_tool -id @rpath/libhamlib.4.dylib libhamlib.4.dylib
install_name_tool -id @rpath/libusb-1.0.0.dylib libusb-1.0.0.dylib

cd "${SUBMODULES}/.."
rsync -arvz /usr/local/js8lib/ ./js8lib/

# Create downloadable pre-built library archive
if [ "$qt" = "y" ]; then
    tar -czvf js8lib${LIB_VERSION}-MacOS_with_Qt.tar.gz js8lib
else
    tar -czvf js8lib${LIB_VERSION}-MacOS_no_Qt.tar.gz js8lib
fi

# Clean up build artifacts
cd "${SUBMODULES}/.."
rm -rf ./js8lib

clear
echo "--------------------------------------------------------------------"
echo "   DONE!"
echo "   Library archive created."
echo "   It is recommended to validate by building JS8Call using"
echo "   ${PREFIX} as CMAKE_PREFIX_PATH before releasing."
echo "   If satisfied you can delete the files in ${PREFIX}"
echo "--------------------------------------------------------------------"
