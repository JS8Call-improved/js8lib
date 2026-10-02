#!/bin/bash
set -e

####### Build Qt6 for JS8Call #######
####### Ubuntu 24.04 Server only  #######

# --- Must not run as root ---
if [ "$(id -u)" -eq 0 ]; then
    echo "This script must NOT be run as root. Exiting."
    exit 1
fi

# --- Detect distro ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution. Exiting."
    exit 1
fi

# --- Restrict to Ubuntu 24.04 only ---
if [[ "$DISTRO" != "ubuntu" ]]; then
    echo "This script is only supported on Ubuntu 24.04 Server."
    echo "Detected: $DISTRO"
    exit 1
fi

if [[ "$VERSION_ID" != "24.04" ]]; then
    echo "This script requires Ubuntu 24.04 Server."
    echo "Detected Ubuntu version: $VERSION_ID"
    exit 1
fi

BUILD_ARCH=$(uname -m)
if [[ "$BUILD_ARCH" != "x86_64" && "$BUILD_ARCH" != "aarch64" ]]; then
    echo "Unsupported architecture: $BUILD_ARCH"
    echo "This script supports x86_64 and aarch64 only."
    exit 1
fi

PREFIX="/usr/lib/js8call/Qt"

echo "######################################################################"
echo "Build environment verified: Ubuntu $VERSION_ID / $BUILD_ARCH"
echo "Installing to: $PREFIX"
echo "######################################################################"

# --- Install build dependencies ---
install_deps() {
    echo "Installing build dependencies for Ubuntu $VERSION_ID / $BUILD_ARCH..."
    sudo apt-get update
    sudo apt-get install -y \
        cmake ninja-build g++ perl python3 git \
        libssl-dev libfontconfig1-dev libfreetype-dev \
        libharfbuzz-dev libjpeg-dev libpng-dev \
        zlib1g-dev libbrotli-dev libdbus-1-dev libglib2.0-dev \
        libatspi2.0-dev \
        libwayland-dev wayland-protocols \
        libxkbcommon-dev libxkbcommon-x11-dev \
        libgl-dev libgl1-mesa-dev libegl-dev libgbm-dev \
        libopengl-dev \
        libdrm-dev libinput-dev \
        libxcb1-dev libx11-xcb-dev \
        libxcb-glx0-dev libxcb-xkb-dev \
        libxcb-icccm4-dev libxcb-image0-dev \
        libxcb-keysyms1-dev libxcb-render-util0-dev \
        libxcb-xinerama0-dev libxcb-xfixes0-dev \
        libxcb-shape0-dev libxcb-randr0-dev \
        libxcb-cursor-dev libxcb-sync-dev \
        libxcb-util-dev \
        libx11-dev \
        libxrender-dev libxi-dev \
        libxrandr-dev libxext-dev libxfixes-dev \
        libxshmfence-dev \
        libpulse-dev libasound2-dev \
        libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        yasm nasm \
        clang libclang-dev llvm llvm-dev \
        libpcre2-dev
}

install_deps

# --- Clean and recreate prefix directory before building ---
if [ -d "$PREFIX" ] && [ -n "$PREFIX" ]; then
    echo "Prefix $PREFIX already exists. Performing fresh wipe..."
    sudo rm -rf "$PREFIX"
fi

echo "Creating clean $PREFIX..."
sudo mkdir -p "$PREFIX"
sudo chown root:root "$PREFIX"

# --- FFmpeg ---
export PKG_CONFIG_PATH=/usr/local/ffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH

echo "Checking for existing FFmpeg installation..."
if pkg-config --exists libavcodec libavformat libavutil libswscale; then
    FFMPEG_VER=$(pkg-config --modversion libavcodec)
    echo "######################################################################"
    echo " Found existing FFmpeg installation (libavcodec v$FFMPEG_VER)."
    echo " Skipping FFmpeg compilation."
    echo "######################################################################"
else
    echo "FFmpeg not found or incomplete. Starting compilation..."
    mkdir -p "$HOME/development"
    cd "$HOME/development"
    
    # Clean old source directory if it exists to avoid build pollution
    if [ -d "ffmpeg" ]; then rm -rf ffmpeg; fi
    
    git clone --branch n7.1.3 https://ffmpeg.org
    cd ffmpeg
    ./configure \
        --prefix=/usr/local/ffmpeg \
        --enable-gpl \
        --enable-shared \
        --disable-static
    make -j$(nproc)
    sudo make install
    echo "FFmpeg compilation and installation complete."
fi

# --- Qt6 source ---
cd "$HOME/development"
git clone https://github.com/qt/qt5.git Qt6
cd Qt6
git checkout v6.12.0
./init-repository --module-subset=qtbase,qtshadertools,qtmultimedia,\
qtimageformats,qtserialport,qtsvg,qtwebsockets,qtwayland,\
qtdeclarative,qttools,qtpositioning,qttranslations,qtlanguageserver,\
qtquicktimeline,qt5compat

# --- Configure ---
mkdir -p "$HOME/development/qt6-build"
cd "$HOME/development/qt6-build"

export CC=clang
export CXX=clang++

"$HOME/development/Qt6/configure" \
    -prefix "$PREFIX" \
    -release \
    -shared \
    -opensource \
    -confirm-license \
    -platform linux-clang \
    -DFEATURE_clang=ON \
    -ffmpeg-dir /usr/local/ffmpeg \
    -ffmpeg-deploy \
    -skip qtquick3d \
    -no-feature-testlib \
    -bundled-xcb-xinput

# --- Build and install ---
cmake --build . --parallel $(nproc)
sudo cmake --install .

echo "######################################################################"
echo "Qt6 build complete. Installed to $PREFIX"
echo "######################################################################"

# --- Bundle libicu ---
echo "Bundling libicu libraries for $BUILD_ARCH..."

if [ "$BUILD_ARCH" = "aarch64" ]; then
    ICU_LIB_PATH="/usr/lib/aarch64-linux-gnu"
else
    ICU_LIB_PATH="/usr/lib/x86_64-linux-gnu"
fi

sudo cp -P ${ICU_LIB_PATH}/libicui18n.so* "$PREFIX/lib/"
sudo cp -P ${ICU_LIB_PATH}/libicuuc.so* "$PREFIX/lib/"
sudo cp -P ${ICU_LIB_PATH}/libicudata.so* "$PREFIX/lib/"

echo "libicu libraries bundled successfully."
echo "######################################################################"

# --- Create tar.gz archive ---
TARBALL="Qt6.12.0_Linux_${BUILD_ARCH}_pkg.tar.gz"
echo "Creating archive $HOME/${TARBALL}..."
tar -czf "$HOME/${TARBALL}" -C "/usr/lib/js8call" Qt

echo "######################################################################"
echo "Archive created: $HOME/${TARBALL}"
echo "Ready to upload to GitHub releases."
echo "######################################################################"
