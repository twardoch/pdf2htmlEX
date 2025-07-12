#!/bin/bash
set -ex

# --- Configuration ---
ORIG_PWD=$(pwd)
BUILD_TEMP_DIR_NAME="build_temp_test_script" # This directory is in .gitignore

mkdir -p "$BUILD_TEMP_DIR_NAME"
cd "$BUILD_TEMP_DIR_NAME"
echo "Working in temporary build directory: $(pwd)"

ARCHS="x86_64;arm64"            # For CMAKE_OSX_ARCHITECTURES
INSTALL_PREFIX="$(pwd)/staging" # Install dependencies into staging area within the temp build dir
mkdir -p "$INSTALL_PREFIX"

# Attempt to get Homebrew prefix automatically, otherwise use a default or ask user to set
HOMEBREW_PREFIX_VAL=$(brew --prefix 2>/dev/null || echo "/opt/homebrew") # Common default for Apple Silicon, /usr/local for Intel Mac

echo "Using Homebrew Prefix: $HOMEBREW_PREFIX_VAL"
echo "If this is incorrect, ensure 'brew' is in your PATH or set HOMEBREW_PREFIX_VAL manually in the script."

# Ensure paths to Homebrew-installed libraries are discoverable
# Prepend jpeg-turbo paths to PKG_CONFIG_PATH and CMAKE_PREFIX_PATH
JPEG_TURBO_PREFIX="$HOMEBREW_PREFIX_VAL/opt/jpeg-turbo"
export PKG_CONFIG_PATH="$JPEG_TURBO_PREFIX/lib/pkgconfig:$HOMEBREW_PREFIX_VAL/lib/pkgconfig:$HOMEBREW_PREFIX_VAL/share/pkgconfig:/usr/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="$JPEG_TURBO_PREFIX:$HOMEBREW_PREFIX_VAL${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export PATH="$HOMEBREW_PREFIX_VAL/bin:$PATH"

# --- Build Poppler (Static) ---
# This script expects Poppler source code to be downloaded and extracted.
# Version: 24.01.0
# URL: https://poppler.freedesktop.org/poppler-24.01.0.tar.xz
# Expected directory: ./poppler-24.01.0
echo "Building Poppler..."
POPPLER_URL="https://poppler.freedesktop.org/poppler-24.01.0.tar.xz"
POPPLER_ARCHIVE="poppler-24.01.0.tar.xz"
POPPLER_DIR="poppler-24.01.0"
if [ ! -d "$POPPLER_DIR" ]; then
    echo "Poppler source directory './$POPPLER_DIR' not found."
    if [ ! -f "$POPPLER_ARCHIVE" ]; then
        echo "Downloading Poppler source from $POPPLER_URL..."
        curl -L -o "$POPPLER_ARCHIVE" "$POPPLER_URL"
    fi
    echo "Extracting Poppler source..."
    tar -xJf "$POPPLER_ARCHIVE"
    if [ ! -d "$POPPLER_DIR" ]; then
        echo "Extraction failed or extracted to an unexpected directory name."
        exit 1
    fi
fi
cd "$POPPLER_DIR"
mkdir -p build && cd build

cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=OFF \
    -DBUILD_GTK_TESTS=OFF \
    -DBUILD_QT5_TESTS=OFF \
    -DBUILD_QT6_TESTS=OFF \
    -DBUILD_CPP_TESTS=OFF \
    -DBUILD_MANUAL_TESTS=OFF \
    -DENABLE_BOOST=OFF \
    -DENABLE_SPLASH=ON \
    -DENABLE_UTILS=OFF \
    -DENABLE_CPP=OFF \
    -DENABLE_GLIB=ON \
    -DENABLE_GOBJECT_INTROSPECTION=OFF \
    -DENABLE_GTK_DOC=OFF \
    -DENABLE_QT5=OFF \
    -DENABLE_QT6=OFF \
    -DENABLE_LIBOPENJPEG="none" \
    -DENABLE_DCTDECODER="unmaintained" \
    -DENABLE_CMS="none" \
    -DENABLE_LCMS=OFF \
    -DENABLE_LIBCURL=OFF \
    -DENABLE_LIBTIFF=OFF \
    -DWITH_TIFF=OFF \
    -DWITH_NSS3=OFF \
    -DENABLE_NSS3=OFF \
    -DENABLE_GPGME=OFF \
    -DENABLE_ZLIB=ON \
    -DENABLE_ZLIB_UNCOMPRESS=OFF \
    -DUSE_FLOAT=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DRUN_GPERF_IF_PRESENT=OFF \
    -DEXTRA_WARN=OFF \
    -DWITH_JPEG=ON \
    -DWITH_PNG=ON \
    -DWITH_Cairo=ON \
    -DJPEG_INCLUDE_DIR="$JPEG_TURBO_PREFIX/include" \
    -DJPEG_LIBRARY="$JPEG_TURBO_PREFIX/lib/libjpeg.dylib"

ninja install
cd ../..

# --- Build FontForge (Static) ---
# This script expects FontForge source code to be downloaded and extracted.
# Version: 20230101
# URL: https://github.com/fontforge/fontforge/archive/refs/tags/20230101.tar.gz
# Expected directory: ./fontforge-20230101
echo "Building FontForge..."
FONTFORGE_URL="https://github.com/fontforge/fontforge/archive/refs/tags/20230101.tar.gz"
FONTFORGE_ARCHIVE="fontforge-20230101.tar.gz"
FONTFORGE_DIR="fontforge-20230101"
if [ ! -d "$FONTFORGE_DIR" ]; then
    echo "FontForge source directory './$FONTFORGE_DIR' not found."
    if [ ! -f "$FONTFORGE_ARCHIVE" ]; then
        echo "Downloading FontForge source from $FONTFORGE_URL..."
        curl -L -o "$FONTFORGE_ARCHIVE" "$FONTFORGE_URL"
    fi
    echo "Extracting FontForge source..."
    tar -xzf "$FONTFORGE_ARCHIVE"
    # The archive extracts to fontforge-fontforge-20230101 or similar if it's from GitHub tags usually
    # Need to handle if it extracts to fontforge-20230101 or fontforge-fontforge-20230101
    # A quick check: curl -sL https://github.com/fontforge/fontforge/archive/refs/tags/20230101.tar.gz | tar -tzf - | head -n 1
    # Output is: fontforge-20230101/
    if [ ! -d "$FONTFORGE_DIR" ]; then
        # Attempt to rename if it extracted with a common GitHub pattern like project-tag
        EXTRACTED_SUBDIR=$(tar -tzf "$FONTFORGE_ARCHIVE" | head -n 1 | sed 's@/.*@@')
        if [ -d "$EXTRACTED_SUBDIR" ] && [ "$EXTRACTED_SUBDIR" != "$FONTFORGE_DIR" ]; then
            echo "Renaming $EXTRACTED_SUBDIR to $FONTFORGE_DIR"
            mv "$EXTRACTED_SUBDIR" "$FONTFORGE_DIR"
        fi
    fi
    if [ ! -d "$FONTFORGE_DIR" ]; then
        echo "Extraction failed or extracted to an unexpected directory name."
        exit 1
    fi
fi
cd "$FONTFORGE_DIR"
# Apply patches if any (example)
# git apply ../patches/fontforge-20170731-fixGDraw.patch
mkdir -p build && cd build

cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DENABLE_GUI:BOOL=OFF \
    -DENABLE_X11:BOOL=OFF \
    -DENABLE_NATIVE_SCRIPTING:BOOL=ON \
    -DENABLE_PYTHON_SCRIPTING:BOOL=OFF \
    -DENABLE_PYTHON_EXTENSION:AUTO=OFF \
    -DENABLE_LIBSPIRO:BOOL=OFF \
    -DENABLE_LIBUNINAMESLIST:BOOL=OFF \
    -DENABLE_LIBGIF:AUTO=OFF \
    -DENABLE_LIBJPEG:AUTO=ON \
    -DENABLE_LIBPNG:AUTO=ON \
    -DENABLE_LIBREADLINE:AUTO=OFF \
    -DENABLE_LIBTIFF:AUTO=ON \
    -DENABLE_WOFF2:AUTO=OFF \
    -DENABLE_DOCS:AUTO=OFF \
    -DENABLE_CODE_COVERAGE:BOOL=OFF \
    -DENABLE_DEBUG_RAW_POINTS:BOOL=OFF \
    -DENABLE_FONTFORGE_EXTRAS:BOOL=OFF \
    -DENABLE_MAINTAINER_TOOLS:BOOL=OFF \
    -DENABLE_TILE_PATH:BOOL=OFF \
    -DENABLE_WRITE_PFM:BOOL=OFF \
    -DENABLE_SANITIZER:ENUM="none" \
    -DENABLE_FREETYPE_DEBUGGER:PATH="" \
    -DSPHINX_USE_VENV:BOOL=OFF \
    -DREAL_TYPE:ENUM="double" \
    -DTHEME:ENUM="tango"

ninja install
cd ../..

# --- Build pdf2htmlEX ---
echo "Building pdf2htmlEX..."

PDF2HTMLEX_CHECKOUT_ROOT="$ORIG_PWD"  # This is the root of the git checkout
PDF2HTMLEX_SOURCE_SUBDIR="pdf2htmlEX" # The sources are in a subdirectory

# Check if the source directory exists
if [ ! -f "$PDF2HTMLEX_CHECKOUT_ROOT/$PDF2HTMLEX_SOURCE_SUBDIR/CMakeLists.txt" ]; then
    echo "pdf2htmlEX source directory not found at $PDF2HTMLEX_CHECKOUT_ROOT/$PDF2HTMLEX_SOURCE_SUBDIR"
    echo "This script expects to be run from the root of the pdf2htmlEX Homebrew formula project,"
    echo "and for the pdf2htmlEX sources to be in a subdirectory named 'pdf2htmlEX'."
    exit 1
fi

# The CMakeLists.txt for pdf2htmlEX will need to find Poppler and FontForge
# We've installed them into $INSTALL_PREFIX (which is $BUILD_TEMP_DIR_NAME/staging)
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="$INSTALL_PREFIX${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

# For pdf2htmlEX/share scripts (build_css.sh, build_js.sh) to find java
# Assuming openjdk is installed by Homebrew.
# Attempt to set JAVA_HOME based on Homebrew's openjdk.
if [ -d "$HOMEBREW_PREFIX_VAL/opt/openjdk/libexec/openjdk.jdk/Contents/Home" ]; then
    export JAVA_HOME="$HOMEBREW_PREFIX_VAL/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
elif [ -d "$HOMEBREW_PREFIX_VAL/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
    export JAVA_HOME="$HOMEBREW_PREFIX_VAL/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
elif [ -d "$HOMEBREW_PREFIX_VAL/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
    export JAVA_HOME="$HOMEBREW_PREFIX_VAL/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
else
    echo "Warning: Could not automatically determine JAVA_HOME from Homebrew's openjdk. build_css.sh/build_js.sh might fail."
    echo "Consider setting JAVA_HOME manually if issues occur."
fi

if [ -n "$JAVA_HOME" ]; then
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "Using JAVA_HOME: $JAVA_HOME"
fi

mkdir -p pdf2htmlEX_builddir
cd pdf2htmlEX_builddir

cmake "$PDF2HTMLEX_CHECKOUT_ROOT/$PDF2HTMLEX_SOURCE_SUBDIR" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX/final" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DPOPPLER_STATIC=ON \
    -DFONTFORGE_STATIC=ON \
    -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX${CMAKE_PREFIX_PATH:+;$CMAKE_PREFIX_PATH}" \ # Prepend our static deps
-DCMAKE_FIND_FRAMEWORK=NEVER \
    -DCMAKE_FIND_APPBUNDLE=NEVER

ninja install
cd .. # Back to $BUILD_TEMP_DIR_NAME

echo "Build complete. Products in $INSTALL_PREFIX/final"
echo "Universal binary expected at $INSTALL_PREFIX/final/bin/pdf2htmlEX"

# --- Verification (conceptual) ---
# Now, the binary is $INSTALL_PREFIX/final/bin/pdf2htmlEX
# Example: file "$INSTALL_PREFIX/final/bin/pdf2htmlEX"
# lipo -info "$INSTALL_PREFIX/final/bin/pdf2htmlEX"

# To make it easier to run from $ORIG_PWD, copy the final binary out (optional)
# mkdir -p "$ORIG_PWD/test_script_output/bin"
# cp "$INSTALL_PREFIX/final/bin/pdf2htmlEX" "$ORIG_PWD/test_script_output/bin/"
# echo "pdf2htmlEX binary also copied to $ORIG_PWD/test_script_output/bin/"
