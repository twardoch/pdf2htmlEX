#!/bin/bash
# this_file: v2/scripts/build.sh
# 
# V2 Local Build Script for pdf2htmlEX
# This script validates the build logic outside of Homebrew before integrating into the formula
#
# Usage: ./v2/scripts/build.sh
# Output: Creates dist/ directory with compiled pdf2htmlEX binary

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly BUILD_DIR="$PROJECT_ROOT/v2/build"
readonly DIST_DIR="$PROJECT_ROOT/v2/dist"
readonly STAGING_DIR="$BUILD_DIR/staging"

# Dependency versions (must match Formula)
readonly PDF2HTMLEX_VERSION="0.18.8.rc1"
readonly JPEG_TURBO_VERSION="3.0.2"
readonly POPPLER_VERSION="24.01.0"
readonly FONTFORGE_VERSION="20230101"

# URLs
readonly PDF2HTMLEX_URL="https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v${PDF2HTMLEX_VERSION}.tar.gz"
readonly JPEG_TURBO_URL="https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.2.tar.gz"
readonly POPPLER_URL="https://poppler.freedesktop.org/poppler-${POPPLER_VERSION}.tar.xz"
readonly FONTFORGE_URL="https://github.com/fontforge/fontforge/archive/${FONTFORGE_VERSION}.tar.gz"

# Universal binary architecture
readonly ARCHS="x86_64;arm64"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*${NC}"
    exit 1
}

check_dependencies() {
    log "Checking build dependencies..."
    
    local missing_deps=()
    
    for cmd in cmake ninja pkg-config curl tar xz lipo; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
    fi
    
    # Check for Homebrew dependencies
    if command -v brew &> /dev/null; then
        local homebrew_deps=(
            "cairo" "fontconfig" "freetype" "gettext" "glib"
            "libpng" "libtiff" "libxml2" "pango" "harfbuzz"
            "little-cms2" "openjpeg" "openjdk"
        )
        
        for dep in "${homebrew_deps[@]}"; do
            if ! brew list "$dep" &> /dev/null; then
                warn "Homebrew dependency '$dep' not found. Install with: brew install $dep"
            fi
        done
    else
        warn "Homebrew not found. Make sure system dependencies are installed."
    fi
}

setup_build_environment() {
    log "Setting up build environment..."
    
    # Clean and create directories
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    mkdir -p "$BUILD_DIR" "$DIST_DIR/bin" "$STAGING_DIR"
    
    # Set up environment variables
    export PKG_CONFIG_PATH="$STAGING_DIR/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    export JAVA_HOME="${JAVA_HOME:-$(brew --prefix openjdk 2>/dev/null || echo "/usr/libexec/java_home")}"
    
    # Enable C++11 mode
    export CXXFLAGS="${CXXFLAGS:-} -std=c++11"
    export CFLAGS="${CFLAGS:-} -std=c11"
}

download_and_extract() {
    local url="$1"
    local extract_dir="$2"
    local archive_name="$(basename "$url")"
    
    log "Downloading $(basename "$extract_dir")..."
    
    if [[ ! -f "$BUILD_DIR/$archive_name" ]]; then
        curl -L "$url" -o "$BUILD_DIR/$archive_name"
    fi
    
    log "Extracting $(basename "$extract_dir")..."
    mkdir -p "$extract_dir"
    
    if [[ "$archive_name" == *.tar.xz ]]; then
        tar -xf "$BUILD_DIR/$archive_name" -C "$extract_dir" --strip-components=1
    elif [[ "$archive_name" == *.tar.gz ]]; then
        tar -xzf "$BUILD_DIR/$archive_name" -C "$extract_dir" --strip-components=1
    else
        error "Unsupported archive format: $archive_name"
    fi
}

build_jpeg_turbo() {
    
    log "Building jpeg-turbo (static)..."
    
    local src_dir="$BUILD_DIR/jpeg-turbo"
    download_and_extract "$JPEG_TURBO_URL" "$src_dir"
    
    cd "$src_dir"
    
    echo "Building jpeg-turbo for x86_64..."
    cmake -S . -B build_x86_64 \
        -DCMAKE_INSTALL_PREFIX="$STAGING_DIR/x86_64" \
        -DCMAKE_OSX_ARCHITECTURES=x86_64 \
        -DENABLE_SHARED=OFF \
        -DENABLE_STATIC=ON \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build build_x86_64
    cmake --install build_x86_64

    echo "Building jpeg-turbo for arm64..."
    cmake -S . -B build_arm64 \
        -DCMAKE_INSTALL_PREFIX="$STAGING_DIR/arm64" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DENABLE_SHARED=OFF \
        -DENABLE_STATIC=ON \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build build_arm64
    cmake --install build_arm64

    echo "Creating universal jpeg-turbo library..."
    mkdir -p "$STAGING_DIR/lib"
    lipo -create "$STAGING_DIR/x86_64/lib/libjpeg.a" "$STAGING_DIR/arm64/lib/libjpeg.a" -output "$STAGING_DIR/lib/libjpeg.a"
    
    cp -R "$STAGING_DIR/x86_64/include" "$STAGING_DIR/"
    
}

build_poppler() {
    log "Building Poppler (static)..."
    
    local src_dir="$BUILD_DIR/poppler"
    download_and_extract "$POPPLER_URL" "$src_dir"
    
    cd "$src_dir"
    
    # Create test directory to prevent CMake errors
    mkdir -p test
    
    cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
        -DENABLE_GLIB=ON \
        -DENABLE_UTILS=OFF \
        -DENABLE_CPP=OFF \
        -DENABLE_QT5=OFF \
        -DENABLE_QT6=OFF \
        -DENABLE_LIBTIFF=OFF \
        -DWITH_TIFF=OFF \
        -DWITH_NSS3=OFF \
        -DENABLE_NSS3=OFF \
        -DENABLE_GPGME=OFF \
        -DENABLE_LIBOPENJPEG=openjpeg2 \
        -DENABLE_CMS=lcms2 \
        -DWITH_JPEG=ON \
        -DENABLE_DCTDECODER=libjpeg \
        -DENABLE_LIBJPEG=ON \
        -DJPEG_INCLUDE_DIR="$STAGING_DIR/include" \
        -DJPEG_LIBRARY="$STAGING_DIR/lib/libjpeg.a" \
        -DCMAKE_BUILD_TYPE=Release \
        -DFREETYPE_INCLUDE_DIR_ft2build="$(brew --prefix freetype)/include/freetype2" \
        -DFREETYPE_INCLUDE_DIR_freetype2="$(brew --prefix freetype)/include/freetype2" \
        -DFREETYPE_LIBRARY="$(brew --prefix freetype)/lib/libfreetype.a" \
        -DFONTCONFIG_INCLUDE_DIR="$(brew --prefix fontconfig)/include" \
        -DFONTCONFIG_LIBRARY="$(brew --prefix fontconfig)/lib/libfontconfig.a" \
        -DLIBPNG_INCLUDE_DIR="$(brew --prefix libpng)/include" \
        -DLIBPNG_LIBRARY="$(brew --prefix libpng)/lib/libpng.a" \
        -DLITTLECMS2_INCLUDE_DIR="$(brew --prefix little-cms2)/include" \
        -DLITTLECMS2_LIBRARY="$(brew --prefix little-cms2)/lib/liblcms2.a" \
        -DOPENJPEG_INCLUDE_DIR="$(brew --prefix openjpeg)/include" \
        -DOPENJPEG_LIBRARY="$(brew --prefix openjpeg)/lib/libopenjp2.a" \
        -DBUILD_BZIP2=ON         -DBZIP2_LIBRARY="$(brew --prefix bzip2)/lib/libbz2.a"
    
    cmake --build build
    cmake --install build
}

build_fontforge() {
    log "Building FontForge (static)..."
    
    local src_dir="$BUILD_DIR/fontforge"
    download_and_extract "$FONTFORGE_URL" "$src_dir"
    
    cd "$src_dir"
    
    # Disable failing translation builds
    if [[ -f "po/CMakeLists.txt" ]]; then
        sed -i '' 's/add_custom_target(pofiles ALL/add_custom_target(pofiles/' po/CMakeLists.txt
    fi
    
    cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_GUI=OFF \
        -DENABLE_NATIVE_SCRIPTING=ON \
        -DENABLE_PYTHON_SCRIPTING=OFF \
        -DCMAKE_BUILD_TYPE=Release
    
    cmake --build build
    cmake --install build
}

build_pdf2htmlex() {
    log "Building pdf2htmlEX..."
    
    local src_dir="$BUILD_DIR/pdf2htmlEX"
    download_and_extract "$PDF2HTMLEX_URL" "$src_dir"
    
    cd "$src_dir"
    
    # V2 Strategy: In-source build pattern
    # Copy staged dependencies to expected locations
    cp -r "$STAGING_DIR"/* poppler/ 2>/dev/null || mkdir -p poppler && cp -r "$STAGING_DIR"/* poppler/
    cp -r "$STAGING_DIR"/* fontforge/ 2>/dev/null || mkdir -p fontforge && cp -r "$STAGING_DIR"/* fontforge/
    
    # Build pdf2htmlex
    mkdir -p build
    cd build
    
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
        -DCMAKE_BUILD_TYPE=Release
    
    make
    make install
}

validate_build() {
    log "Validating build..."
    
    local binary="$DIST_DIR/bin/pdf2htmlEX"
    
    # Check if binary exists
    if [[ ! -f "$binary" ]]; then
        error "pdf2htmlEX binary not found at $binary"
    fi
    
    # Check if it's a universal binary
    if ! file "$binary" | grep -q "universal binary"; then
        warn "Binary is not universal. This may be expected on single-architecture systems."
    fi
    
    # Check dynamic library dependencies
    log "Checking dynamic library dependencies..."
    otool -L "$binary" | grep -E "/(usr/lib|System)" || true
    
    # Check that we're not linking to Homebrew libraries
    if otool -L "$binary" | grep -q "$(brew --prefix)"; then
        warn "Binary links to Homebrew libraries. This may indicate incomplete static linking."
    fi
    
    # Test basic functionality
    if "$binary" --version; then
        log "Version check passed"
    else
        error "Version check failed"
    fi
    
    # Create a simple test PDF for functional testing
    local test_pdf="$DIST_DIR/test.pdf"
    cat > "$test_pdf" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT
/F1 12 Tf
100 700 Td
(Hello World) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000207 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
301
%%EOF
EOF
    
    # Test conversion
    cd "$DIST_DIR"
    if "$binary" test.pdf; then
        log "PDF conversion test passed"
        if [[ -f "test.html" ]]; then
            log "HTML output file created successfully"
        else
            warn "HTML output file not created"
        fi
    else
        error "PDF conversion test failed"
    fi
}

main() {
    log "Starting pdf2htmlEX v2 build process..."
    
    check_dependencies
    setup_build_environment
    
    # Build dependencies in order
    build_jpeg_turbo
    build_poppler
    build_fontforge
    build_pdf2htmlex
    
    validate_build
    
    log "Build completed successfully!"
    log "Binary location: $DIST_DIR/bin/pdf2htmlEX"
    log "To test: $DIST_DIR/bin/pdf2htmlEX --version"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi