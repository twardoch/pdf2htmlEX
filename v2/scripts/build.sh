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
# Abort on error, missing vars, or pipelines fail.
set -euo pipefail

# Uncomment the following line for verbose debugging.
# set -x

# --- Configuration ---
ROOT_DIR=$(cd "$(dirname "$0")"/../..; pwd)
V2_DIR="$ROOT_DIR/v2"
# Directory that will hold *downloaded* or vendored source archives so that
# the build is fully offline-reproducible.  This lives in the repository and
# therefore should be checked-in (git-ignored for large files if desired).
#
#   v2/vendor/
#       libjpeg-turbo-<ver>.tar.gz
#       poppler-<ver>.tar.xz
#       <etc>
#
# The actual compilation happens under $BUILD_DIR which may be wiped between
# runs, while $VENDOR_DIR remains immutable.

VENDOR_DIR="$V2_DIR/vendor"

# BUILD_DIR is scratch space created on every invocation.
BUILD_DIR="$V2_DIR/build"
STAGING_DIR="$BUILD_DIR/staging"
DIST_DIR="$V2_DIR/dist"
# Universal binary architectures to build for. Adapt if needed.
# Build only for the host architecture to avoid projects that do not support
# multi-arch builds in a single invocation (e.g., libjpeg-turbo).  A separate
# CI job can run the script on an Intel and on an Apple Silicon runner and
# merge binaries later if true universal support is required.
ARCHS="$(uname -m)"
SRC_DIR="$BUILD_DIR/src"

# --- Setup ---
printf '\n>>> Setting up build environment...\n'
# Ensure important directories are pristine for each run
# Some previously extracted directories may contain read-only files from source
# archives (e.g., git submodules).  We force writable and ignore errors.
# If previous build artifacts exist we reuse them to speed up incremental
# builds; wipe only the dist directory to avoid interference with final
# output.
chmod -R +w "$DIST_DIR" 2>/dev/null || true
rm -rf "$DIST_DIR" 2>/dev/null || true
# Ensure directory structure exists
mkdir -p "$VENDOR_DIR" "$STAGING_DIR" "$DIST_DIR" "$SRC_DIR"

# --- Source tarball management ------------------------------------------------
# The script will automatically download the required source archives if they
# are not already present in $BUILD_DIR. This makes the build fully
# reproducible without manual preparation steps.

# Define component versions in a single location so update-version.sh can keep
# them in sync.
readonly JPEG_TURBO_VERSION="3.0.2"
readonly POPPLER_VERSION="24.01.0"
readonly FONTFORGE_VERSION="20230101"
readonly PDF2HTMLEX_VERSION="0.18.8.rc2"

# Map component → URL in a POSIX-portable way (associative arrays require Bash≥4).
get_url_for_component() {
  case "$1" in
    jpeg-turbo)
      echo "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${JPEG_TURBO_VERSION}.tar.gz";;
    poppler)
      echo "https://poppler.freedesktop.org/poppler-${POPPLER_VERSION}.tar.xz";;
    fontforge)
      echo "https://github.com/fontforge/fontforge/archive/${FONTFORGE_VERSION}.tar.gz";;
    pdf2htmlex)
      echo "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v${PDF2HTMLEX_VERSION}.tar.gz";;
    *)
      echo "Unknown component $1" >&2; return 1;;
  esac
}

# Components we need to fetch/build in order.
COMPONENTS=(jpeg-turbo poppler fontforge pdf2htmlex)

download_sources() {
  local component url filename target_path
  for component in "${COMPONENTS[@]}"; do
    url="$(get_url_for_component "$component")"
    filename="${url##*/}"

    # Some GitHub archives (e.g., libjpeg-turbo) are served with short tag
    # filenames.  To keep the rest of the script predictable we rename them
    # to include the project prefix when necessary.
    local target_path="${VENDOR_DIR}/${filename}"
    if [[ "$component" == "jpeg-turbo" ]]; then
      target_path="${VENDOR_DIR}/libjpeg-turbo-${JPEG_TURBO_VERSION}.tar.gz"
    fi

    if [[ -s "${target_path}" && $(stat -f%z "$target_path") -gt 100000 ]]; then
      printf '>>> Using cached %s\n' "$(basename "$target_path")"
      continue
    fi

    if [[ ! -f "${target_path}" ]]; then
      printf '>>> Downloading %s...\n' "$(basename "$target_path")"
      curl -L "${url}" -o "${target_path}"
    else
      printf '>>> Using cached %s\n' "$(basename "$target_path")"
    fi
    target_path="${VENDOR_DIR}/${filename}"
    if [[ "$component" == "jpeg-turbo" ]]; then
      target_path="${VENDOR_DIR}/libjpeg-turbo-${JPEG_TURBO_VERSION}.tar.gz"
    fi

    if [[ ! -f "${target_path}" ]]; then
      printf '>>> Downloading %s...\n' "$(basename "$target_path")"
      curl -L "${url}" -o "${target_path}"
    else
      printf '>>> Using cached %s\n' "$(basename "$target_path")"
    fi
  done
}

# Fetch any missing archives before extraction.
download_sources

# --- Helper function for extracting ---
extract() {
  local archive_path=$1
  echo ">>> Extracting $(basename "$archive_path")..."
  tar -xf "$archive_path" -C "$SRC_DIR"
}

# Extract all sources
# Extract tarballs. We expect GNU tar that supports both .tar.gz and .tar.xz
# Extract from vendor cache
extract "$VENDOR_DIR/libjpeg-turbo-${JPEG_TURBO_VERSION}.tar.gz"
extract "$VENDOR_DIR/poppler-${POPPLER_VERSION}.tar.xz"
extract "$VENDOR_DIR/${FONTFORGE_VERSION}.tar.gz"
extract "$VENDOR_DIR/v${PDF2HTMLEX_VERSION}.tar.gz"

# Find extracted directory names
JPEG_TURBO_SRC_DIR="$SRC_DIR/libjpeg-turbo-${JPEG_TURBO_VERSION}"
POPPLER_SRC_DIR="$SRC_DIR/poppler-${POPPLER_VERSION}"
FONTFORGE_SRC_DIR="$SRC_DIR/fontforge-${FONTFORGE_VERSION}"
# pdf2htmlEX tarball naming conventions vary between versions/tag sources.
# Detect automatically: look for a directory that contains CMakeLists.txt and
# a 'src' subdir.
PDF2HTMLEX_SRC_DIR=""
for cand in "$SRC_DIR/pdf2htmlEX-${PDF2HTMLEX_VERSION}" "$SRC_DIR/pdf2htmlEX" "$SRC_DIR/pdf2htmlEX-${PDF2HTMLEX_VERSION}/pdf2htmlEX"; do
  if [[ -f "$cand/CMakeLists.txt" && -d "$cand/src" ]]; then
    PDF2HTMLEX_SRC_DIR="$cand"
    break
  fi
done

if [[ -z "$PDF2HTMLEX_SRC_DIR" ]]; then
  echo "ERROR: Could not locate extracted pdf2htmlEX sources" >&2
  exit 1
fi

# Set up environment for build
export PKG_CONFIG_PATH="$STAGING_DIR/lib/pkgconfig"
export JAVA_HOME=$(/usr/libexec/java_home)
# Help CMake find our freshly-installed static libs instead of the system ones.
export CMAKE_PREFIX_PATH="$STAGING_DIR:${CMAKE_PREFIX_PATH:-}"

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
  # Install into the common staging directory so that subsequent
  # components (Poppler → pdf2htmlEX) can discover the jpeg headers and
  # static library via CMakeʼs CMAKE_PREFIX_PATH / PKG_CONFIG_PATH.
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
    -DJPEG_INCLUDE_DIR="$STAGING_DIR/include" \
    -DJPEG_LIBRARY="$STAGING_DIR/lib/libjpeg.a" \
    -DENABLE_LIBTIFF=OFF \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build
  cmake --install build
)

# --- Stage 3: Build FontForge (static) ---
echo ">>> Stage 3: Building static FontForge..."
(
  cd "$FONTFORGE_SRC_DIR"
  rm -rf build
  # Prevent automatic .po → .mo compilation which fails with some
  # translations; we strip the ALL dependency from the pofiles custom target.
  sed -i.bak 's/add_custom_target(pofiles ALL/add_custom_target(pofiles/' po/CMakeLists.txt || true
  cmake -S . -B build \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$STAGING_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_GUI=OFF \
    -DENABLE_NATIVE_SCRIPTING=ON \
    -DENABLE_PYTHON_SCRIPTING=OFF \
    -DENABLE_NLS=OFF \
    -DENABLE_DOCS=OFF \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build

  # The upstream FontForge 'install' target attempts to install translation
  # .mo files even when ENABLE_NLS=OFF. On macOS this leads to a fatal
  # "file INSTALL cannot find *.mo" error because the files are not generated
  # when NLS is disabled. Rather than patching FontForge further we stage the
  # artefacts we actually need (static library + public headers) manually.

  mkdir -p "$STAGING_DIR/lib" "$STAGING_DIR/include"

  FONTFORGE_STATIC_LIB=$(find build -name 'libfontforge.a' | head -n 1 || true)
  if [[ -z "$FONTFORGE_STATIC_LIB" ]]; then
    echo "ERROR: libfontforge.a not found after FontForge build" >&2
    exit 1
  fi
  cp "$FONTFORGE_STATIC_LIB" "$STAGING_DIR/lib/"

  # Public headers live in the top-level fontforge directory.  Copy the whole
  # folder so include paths like <fontforge/xxx.h> resolve.
  cp -R "$FONTFORGE_SRC_DIR/fontforge" "$STAGING_DIR/include/"

  # Provide a minimal stub for <libintl.h> so that FontForge's generated
  # intl.h compiles even when NLS support is disabled and gettext headers are
  # missing on macOS. The subset implemented is sufficient for compiling
  # pdf2htmlEX which only relies on gettext macros.
  cat > "$STAGING_DIR/include/libintl.h" <<'STUB'
#ifndef LIBINTL_STUB_H
#define LIBINTL_STUB_H 1
#define gettext(Msg) (Msg)
#define dgettext(Domain, Msg) (Msg)
#define dcgettext(Domain, Msg, Category) (Msg)
#define ngettext(Singular, Plural, Count) ((Count)==1?(Singular):(Plural))
#define dngettext(Domain, Singular, Plural, Count) ngettext(Singular,Plural,Count)
#define dcngettext(Domain, Singular, Plural, Count, Category) ngettext(Singular,Plural,Count)
#define textdomain(Domain) (Domain)
#define bindtextdomain(Domain, Dir) (Domain)
#define bind_textdomain_codeset(Domain, Codeset) (Domain)
#endif /* LIBINTL_STUB_H */
STUB

  # Also copy generated configuration headers such as fontforge-config.h that
  # live in the build/inc directory.
  if [[ -f "$FONTFORGE_SRC_DIR/build/inc/fontforge-config.h" ]]; then
    cp "$FONTFORGE_SRC_DIR/build/inc/fontforge-config.h" "$STAGING_DIR/include/fontforge/"
  fi
)

# --- Stage 4: Build pdf2htmlEX ---
echo ">>> Stage 4: Building pdf2htmlEX..."
(
  cd "$PDF2HTMLEX_SRC_DIR"
  
  # pdf2htmlEX CMakeLists.txt expects its sibling directories '../poppler' and
  # '../fontforge'. We therefore populate those alongside the pdf2htmlEX
  # source directory (one level above CMAKE_SOURCE_DIR).

  POPPLER_DEST_DIR="../poppler"
  FONTFORGE_DEST_DIR="../fontforge"

  mkdir -p "$POPPLER_DEST_DIR" "$FONTFORGE_DEST_DIR"

  # Copy Poppler staged artefacts wholesale.
  cp -R "$STAGING_DIR/"* "$POPPLER_DEST_DIR/"

  # Satisfy pdf2htmlEX's hard-coded Poppler layout expectations ----------------
  # It assumes Poppler was built *in-tree* under poppler/build with the
  # following files/dirs:
  #   poppler/build/libpoppler.a
  #   poppler/build/glib/libpoppler-glib.a
  #   poppler/build/poppler/*.h  (generated headers)
  #   poppler/poppler/*.h        (original source headers)
  # Our staged install tree looks different, so we create a compatibility
  # shim by copying (or symlinking) the needed artefacts.

  # 1. Libraries -------------------------------------------------------------
  mkdir -p "$POPPLER_DEST_DIR/build/glib"
  cp "$STAGING_DIR/lib/libpoppler.a" "$POPPLER_DEST_DIR/build/"
  cp "$STAGING_DIR/lib/libpoppler-glib.a" "$POPPLER_DEST_DIR/build/glib/"

  # 2. Header directories ----------------------------------------------------
  # Map include/poppler → poppler/poppler and poppler/build/poppler
  if [[ -d "$STAGING_DIR/include/poppler" ]]; then
    mkdir -p "$POPPLER_DEST_DIR/poppler" "$POPPLER_DEST_DIR/build/poppler"
    cp -R "$STAGING_DIR/include/poppler/"* "$POPPLER_DEST_DIR/poppler/"
    cp -R "$STAGING_DIR/include/poppler/"* "$POPPLER_DEST_DIR/build/poppler/"
  fi

  # Stage FontForge artefacts in the directory layout expected by the
  # original pdf2htmlEX CMakeLists.txt (see include_directories directives).
  # The expectation is:
  #   ../fontforge/fontforge          → public headers
  #   ../fontforge/build/inc          → same headers again (historic reason)
  #   ../fontforge/build/lib/*.a      → static library

  # 1. Public headers
  mkdir -p "$FONTFORGE_DEST_DIR/fontforge"
  cp -R "$STAGING_DIR/include/fontforge"/* "$FONTFORGE_DEST_DIR/fontforge/"

  # 2. Duplicate headers into build/inc for legacy path compatibility
  mkdir -p "$FONTFORGE_DEST_DIR/build/inc"
  cp -R "$FONTFORGE_DEST_DIR/fontforge"/* "$FONTFORGE_DEST_DIR/build/inc/"

  # 2b. Copy additional public headers from the original 'inc' directory that
  # some FontForge builds ship (contains basics.h, etc.).
  if [[ -d "$FONTFORGE_SRC_DIR/inc" ]]; then
    mkdir -p "$FONTFORGE_DEST_DIR/inc"
    cp -R "$FONTFORGE_SRC_DIR/inc/"* "$FONTFORGE_DEST_DIR/inc/"
    # Also mirror into build/inc so all include paths resolve
    cp -R "$FONTFORGE_SRC_DIR/inc/"* "$FONTFORGE_DEST_DIR/build/inc/"
  fi

  # Ensure generated config header is present in build/inc
  if [[ -f "$STAGING_DIR/include/fontforge/fontforge-config.h" ]]; then
    cp "$STAGING_DIR/include/fontforge/fontforge-config.h" "$FONTFORGE_DEST_DIR/build/inc/"
  fi

  # Copy libintl stub into build/inc so that <libintl.h> resolves irrespective
  # of additional include paths provided by the compiler.
  cp "$STAGING_DIR/include/libintl.h" "$FONTFORGE_DEST_DIR/build/inc/"

  # 3. Static library
  mkdir -p "$FONTFORGE_DEST_DIR/build/lib"
  cp "$STAGING_DIR/lib/libfontforge.a" "$FONTFORGE_DEST_DIR/build/lib/"

  # The upstream build expects a test script template even when we don't run
  # the unit tests. Some source tarballs ship without the test directory,
  # causing CMake configure_file() to fail.  Create an empty placeholder to
  # satisfy CMake.
  mkdir -p test
  touch test/test.py.in

  rm -rf build
  mkdir build
  cd build
  cmake .. \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17
  ninja
  ninja install
)

echo ">>> Build complete!"
echo ">>> The binary is available at $DIST_DIR/bin/pdf2htmlEX"
echo ">>> To validate:"
echo "file $DIST_DIR/bin/pdf2htmlEX"
echo "otool -L $DIST_DIR/bin/pdf2htmlEX"
