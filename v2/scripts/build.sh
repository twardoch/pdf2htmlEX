#!/bin/bash
#
# This script automates the local build of pdf2htmlEX and its dependencies,
# following the four-stage process outlined in v2/PLAN.md.
#
# Prerequisites:
# 1. Install build dependencies: brew install cmake ninja pkg-config openjdk cairo fontconfig freetype gettext glib libpng libtiff libxml2 pango harfbuzz little-cms2 openjpeg
# 2. Download the following archives into the v2/build directory:
#    - https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-3.0.2.tar.gz
#    - https://poppler.freedesktop.org/poppler-24.01.0.tar.xz
#    - https://github.com/fontforge/fontforge/archive/20230101.tar.gz
#    - https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz
#
set -e
set -o pipefail
set -x

# --- Configuration ---
ROOT_DIR=$(cd "$(dirname "$0")"/../..; pwd)
V2_DIR="$ROOT_DIR/v2"
BUILD_DIR="$V2_DIR/build"
STAGING_DIR="$BUILD_DIR/staging"
DIST_DIR="$V2_DIR/dist"
ARCHS="x86_64;arm64"
SRC_DIR="$BUILD_DIR/src"

# --- Setup ---
echo ">>> Setting up build environment..."
rm -rf "$STAGING_DIR" "$DIST_DIR" "$SRC_DIR"
mkdir -p "$STAGING_DIR" "$DIST_DIR" "$SRC_DIR"

# --- Helper function for extracting ---
extract() {
  local archive_path=$1
  echo ">>> Extracting $(basename "$archive_path")..."
  tar -xf "$archive_path" -C "$SRC_DIR"
}

# Extract all sources
extract "$BUILD_DIR/libjpeg-turbo-3.0.2.tar.gz"
extract "$BUILD_DIR/poppler-24.01.0.tar.xz"
extract "$BUILD_DIR/20230101.tar.gz"
extract "$BUILD_DIR/v0.18.8.rc1.tar.gz"

# Find extracted directory names
JPEG_TURBO_SRC_DIR="$SRC_DIR/libjpeg-turbo-3.0.2"
POPPLER_SRC_DIR="$SRC_DIR/poppler-24.01.0"
FONTFORGE_SRC_DIR="$SRC_DIR/fontforge-20230101"
PDF2HTMLEX_SRC_DIR="$SRC_DIR/pdf2htmlEX-0.18.8.rc1"

# Set up environment for build
export PKG_CONFIG_PATH="$STAGING_DIR/lib/pkgconfig"
export JAVA_HOME=$(/usr/libexec/java_home)

# --- Stage 1: Build jpeg-turbo (static) ---
echo ">>> Stage 1: Building static jpeg-turbo..."
(
  cd "$JPEG_TURBO_SRC_DIR"
  cmake -S . -B build \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build
  cmake --install build
)

# --- Stage 2: Build Poppler (static) ---
echo ">>> Stage 2: Building static Poppler..."
(
  cd "$POPPLER_SRC_DIR"
  mkdir -p build # test dir placeholder not needed if building out of source tree
  
  cmake -S . -B build \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
    -DENABLE_GLIB=ON \
    -DENABLE_UTILS=OFF \
    -DENABLE_CPP=OFF \
    -DENABLE_QT5=OFF \
    -DENABLE_QT6=OFF \
    -DENABLE_LIBOPENJPEG=openjpeg2 \
    -DENABLE_CMS=lcms2 \
    -DWITH_JPEG=ON \
    -DENABLE_DCTDECODER=libjpeg \
    -DENABLE_LIBJPEG=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build
  cmake --install build
)

# --- Stage 3: Build FontForge (static) ---
echo ">>> Stage 3: Building static FontForge..."
(
  cd "$FONTFORGE_SRC_DIR"
  # Disable failing translation builds
  sed -i.bak 's/add_custom_target(pofiles ALL/add_custom_target(pofiles/' po/CMakeLists.txt

  cmake -S . -B build \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_GUI=OFF \
    -DENABLE_NATIVE_SCRIPTING=ON \
    -DENABLE_PYTHON_SCRIPTING=OFF \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build
  cmake --install build
)

# --- Stage 4: Build pdf2htmlEX ---
echo ">>> Stage 4: Building pdf2htmlEX..."
(
  cd "$PDF2HTMLEX_SRC_DIR"
  
  # In-source build pattern: copy deps into expected locations
  # This is more explicit than moving.
  mkdir -p poppler fontforge
  cp -R "$STAGING_DIR/"* "poppler/"
  cp -R "$STAGING_DIR/"* "fontforge/"

  mkdir build
  cd build
  cmake .. \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DCMAKE_BUILD_TYPE=Release
  ninja
  ninja install
)

echo ">>> Build complete!"
echo ">>> The binary is available at $DIST_DIR/bin/pdf2htmlEX"
echo ">>> To validate:"
echo "file $DIST_DIR/bin/pdf2htmlEX"
echo "otool -L $DIST_DIR/bin/pdf2htmlEX"
