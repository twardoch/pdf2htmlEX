#!/usr/bin/env bash
# this_file: v2/scripts/build.sh

# -----------------------------------------------------------------------------
# pdf2htmlEX – Local Universal-Binary Builder (Phase-1)
# -----------------------------------------------------------------------------
# This script performs a *complete*, self-contained build of pdf2htmlEX and its
# critical static dependencies (libjpeg-turbo, Poppler, FontForge) for macOS
# universal binary (x86_64 + arm64).  The final artefacts are placed in
#   dist/{bin,lib,share}
# where dist/bin/pdf2htmlEX is a single Mach-O universal executable that links
# only against macOS system frameworks (no Homebrew run-time deps).
#
# The build mirrors the logic planned for the Homebrew v2 formula, but runs
# entirely outside Homebrew so you can validate the approach quickly on a local
# checkout or in CI.
# -----------------------------------------------------------------------------
# Dependencies (must be in $PATH):
#   • bash (>= 4), curl, tar, cmake, ninja, make, shasum, file, otool
#   • clang tool-chain (Xcode or Command Line Tools) with macOS 12+ SDK
#
# Time – a full clean build can take ~10-15 min on Apple M-series, ~20-30 min on
# Intel, depending on cores/network.
# -----------------------------------------------------------------------------
# Usage:
#   ./v2/scripts/build.sh          # normal build
#   ARCHS="x86_64" ./v2/scripts/build.sh   # single-arch build
#   CLEAN=1 ./v2/scripts/build.sh         # wipe build/dist first
# -----------------------------------------------------------------------------
set -euo pipefail

#####################################
# 1.  Config & versions              #
#####################################

# Allow ARCHS override from env; default to universal build expected by v2.
ARCHS=${ARCHS:-"x86_64;arm64"}

# Bump these in tandem with Formula when versions change.
JPEG_TURBO_VERSION="3.0.2"
#
# Upstream switched release hosting from SourceForge to GitHub beginning with
# libjpeg-turbo 3.x.  The previous SourceForge URL now returns HTTP 404 which
# breaks fresh builds.  Switch to the canonical GitHub release archive and
# update the checksum accordingly.  (The tarball contents are identical – only
# the distribution channel changed.)
#
JPEG_TURBO_URL="https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${JPEG_TURBO_VERSION}.tar.gz"
# SHA-256 for https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.2.tar.gz
JPEG_TURBO_SHA256="29f2197345aafe1dcaadc8b055e4cbec9f35aad2a318d61ea081f835af2eebe9"

POPPLER_VERSION="24.01.0"
POPPLER_URL="https://poppler.freedesktop.org/poppler-${POPPLER_VERSION}.tar.xz"
POPPLER_SHA256="c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08"

FONTFORGE_VERSION="20230101"
FONTFORGE_URL="https://github.com/fontforge/fontforge/archive/refs/tags/${FONTFORGE_VERSION}.tar.gz"
FONTFORGE_SHA256="ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"

PDF2HTML_VERSION="0.18.8.rc1"
PDF2HTML_URL="https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v${PDF2HTML_VERSION}.tar.gz"
PDF2HTML_SHA256="a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"

LIBPNG_VERSION="1.6.43"
LIBPNG_URL="https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.xz"
LIBPNG_SHA256="6a5ca0652392a2d7c9db2ae5b40210843c0bbc081cbd410825ab00cc59f14a6c"

OPENJPEG_VERSION="2.5.0"
OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/refs/tags/v${OPENJPEG_VERSION}.tar.gz"
OPENJPEG_SHA256="0333806d6adecc6f7a91243b2b839ff4d2053823634d4f6ed7a59bc87409122a"

LCMS2_VERSION="2.14"
LCMS2_URL="https://github.com/mm2/Little-CMS/releases/download/lcms${LCMS2_VERSION}/lcms2-${LCMS2_VERSION}.tar.gz"
LCMS2_SHA256="28c54bfa523905885553a31335338393844d45534a83e438b4b3858178425b8f"

LIBTIFF_VERSION="4.4.0"
LIBTIFF_URL="https://download.osgeo.org/libtiff/tiff-${LIBTIFF_VERSION}.tar.gz"
LIBTIFF_SHA256="917223b37538959aca3b790d2d73aa6e626b688e02dcda272aec24c2f498abed"

LIBWEBP_VERSION="1.3.2"
LIBWEBP_URL="https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${LIBWEBP_VERSION}.tar.gz"
LIBWEBP_SHA256="2a499607df669e40258e53d0ade8035ba4ec0175244869d1025d460562aa09b4"

LIBDEFLATE_VERSION="1.18"
LIBDEFLATE_URL="https://github.com/ebiggers/libdeflate/archive/refs/tags/v${LIBDEFLATE_VERSION}.tar.gz"
LIBDEFLATE_SHA256="225d982bcaf553221c76726358d2ea139bb34913180b20823c782cede060affd"

LIBGIF_VERSION="5.2.2"
LIBGIF_URL="https://sourceforge.net/projects/giflib/files/giflib-${LIBGIF_VERSION}.tar.gz"
LIBGIF_SHA256="be7ffbd057cadebe2aa144542fd90c6838c6a083b5e8a9048b8ee3b66b29d5fb"

NSS_VERSION="3.113.1"
NSS_URL="https://archive.mozilla.org/pub/security/nss/releases/NSS_${NSS_VERSION//./_}_RTM/src/nss-${NSS_VERSION}.tar.gz"
NSS_SHA256="b8c586cc0ac60b76477f62483f664f119c26000a8189dd9ef417df7dbd33a2cc"

GPGME_VERSION="2.0.0"
GPGME_URL="https://www.gnupg.org/ftp/gcrypt/gpgme/gpgme-${GPGME_VERSION}.tar.bz2"
GPGME_SHA256="ddf161d3c41ff6a3fcbaf4be6c6e305ca4ef1cc3f1ecdfce0c8c2a167c0cc36d"



FREETYPE_VERSION="2.13.2"
FREETYPE_URL="https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.xz"
FREETYPE_SHA256="12991c4e55c506dd7f9b765933e62fd4be2e0665b2387065f25b211b41661fd3"

FONTCONFIG_VERSION="2.15.0"
FONTCONFIG_URL="https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.xz"
FONTCONFIG_SHA256="96c3a34d867c3367387233731834f32345505583742e33e1369137b7a84f6416"

CAIRO_VERSION="1.18.0"
CAIRO_URL="https://cairographics.org/releases/cairo-${CAIRO_VERSION}.tar.xz"
CAIRO_SHA256="24c1e9153593216fde052754a8a91a5b124a853c3a1014f43256183f4f18d4be"







# Directory layout (all relative to repo root)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/v2/build"
DIST_DIR="${ROOT_DIR}/v2/dist"
STAGING_DIR="${BUILD_DIR}/staging"   # prefix for static libs/headers
SRC_DIR="${BUILD_DIR}/src"            # where tarballs are extracted

# respect CLEAN env to wipe previous artifacts
if [[ "${CLEAN:-0}" == "1" ]]; then
  echo "[clean] Removing previous build artifacts …"
  rm -rf "${BUILD_DIR}" "${DIST_DIR}"
fi

mkdir -p "${BUILD_DIR}" "${DIST_DIR}" "${STAGING_DIR}" "${SRC_DIR}"

#####################################
# 2.  Helper functions               #
#####################################

log() { printf "\033[1;34m[%s]\033[0m %s\n" "$(date +%H:%M:%S)" "$*"; }

# Download <url> if file missing; verify sha256; extract into SRC_DIR.
# Args: url sha256 tar_opts
# Fetches an archive, verifies its checksum and extracts it into $SRC_DIR.
#
# Args:
#   $1: URL to download
#   $2: Expected SHA-256 checksum
#   $3: (optional) Extra options that should be forwarded to the tar command
#       when extracting.  Not every call site currently needs this, therefore
#       the argument has to be optional.  Using set -u means we must provide a
#       default value or the script will abort with an “unbound variable”
#       error once the function tries to access a non-existent $3.  We fix
#       that by expanding the parameter with a fallback to an empty string.
#
#       Example usage with additional tar options:
#         fetch_and_extract "$url" "$sha" "--strip-components=1"
#
#       Example usage without extra options (most common):
#         fetch_and_extract "$url" "$sha"
fetch_and_extract() {
  local url="$1" sha="$2" tar_opts="${3:-}"
  local filename="${BUILD_DIR}/$(basename "$url")"

  if [[ ! -f "$filename" ]]; then
    log "Downloading $(basename "$url") …"
    curl -LfsS "$url" -o "$filename"
  fi

  # Verify SHA256
  local calc_sha
  calc_sha=$(shasum -a 256 "$filename" | awk '{print $1}')
  if [[ "$calc_sha" != "$sha" ]]; then
    echo "SHA256 mismatch for $filename (got $calc_sha, expected $sha)" >&2
    exit 1
  fi

  # Determine extraction dir name (first path component inside archive)
  local top_dir
  case "$filename" in
    *.tar.gz|*.tgz)  top_dir=$(tar -tzf "$filename" | head -n1 | cut -f1 -d/);;
    *.tar.xz)        top_dir=$(tar -tJf "$filename" | head -n1 | cut -f1 -d/);;
    *) echo "Unsupported archive type: $filename" >&2; exit 1;;
  esac

  local dest="${SRC_DIR}/$top_dir"
  if [[ ! -d "$dest" ]]; then
    log "Extracting $(basename "$filename") …"
    mkdir -p "$SRC_DIR"
    case "$filename" in
      *.tar.gz|*.tgz) tar -xzf "$filename" -C "$SRC_DIR" $tar_opts ;;
      *.tar.xz)       tar -xJf "$filename" -C "$SRC_DIR" $tar_opts ;;
    esac
  fi
  echo "$dest" # return path
}

# Configure & build with CMake/Ninja wrapper
cmake_build_install() {
  local src_dir="$1" build_dir="$2" shift_by=2
  shift $shift_by || true
  local cmake_opts=("$@")

  mkdir -p "$build_dir"
  pushd "$build_dir" >/dev/null
  cmake -G Ninja -DCMAKE_BUILD_TYPE=Release "${cmake_opts[@]}" "$src_dir"
  ninja
  ninja install
  popd >/dev/null
}

# Ensure required commands present
for cmd in curl shasum cmake ninja file otool; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done

#####################################
# 3.  Stage builds                    #
#####################################

export PKG_CONFIG_PATH="${STAGING_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="${STAGING_DIR}:${CMAKE_PREFIX_PATH:-}"

# Provide Java for pdf2htmlEX CSS/JS build (ignored if absent)
if [[ -d "/usr/libexec/java_home" ]]; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 11 2>/dev/null || true)"
fi

# ----- 3.1 libjpeg-turbo ------------------------------------------------------

# ---------------------------------------------------------------------------
# libjpeg-turbo cannot be compiled for multiple architectures in a single
# CMake invocation because its build system bails out when
# CMAKE_OSX_ARCHITECTURES contains more than one value (due to inline assembly
# restrictions).  Work around this by building each architecture separately
# and then creating a fat/universal static library with `lipo`.
# ---------------------------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libjpeg.a" ]]; then
  log "Building libjpeg-turbo ${JPEG_TURBO_VERSION} (static, universal)"
  jpeg_src=$(fetch_and_extract "$JPEG_TURBO_URL" "$JPEG_TURBO_SHA256" | tail -n1)

  IFS=';' read -r -a _arch_array <<< "$ARCHS"
  first_arch="${_arch_array[0]}"

  # Build for the first architecture directly into STAGING_DIR so headers and
  # pkg-config files are available for downstream builds (Poppler, etc.)
  cmake_build_install "$jpeg_src" "$jpeg_src/build-${first_arch}" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="${first_arch}" \
     -DENABLE_SHARED=OFF \
     -DENABLE_STATIC=ON

  # If additional architectures are requested, build them into a temporary
  # prefix and merge the resulting static libs using `lipo`.
  for arch in "${_arch_array[@]:1}"; do
    temp_prefix="${STAGING_DIR}-${arch}"
    log "Building libjpeg-turbo for ${arch} …"

    cmake_build_install "$jpeg_src" "$jpeg_src/build-${arch}" \
       -DCMAKE_INSTALL_PREFIX="${temp_prefix}" \
       -DCMAKE_OSX_ARCHITECTURES="${arch}" \
       -DENABLE_SHARED=OFF \
       -DENABLE_STATIC=ON

    # Merge *.a static libraries with the ones already in STAGING_DIR.
    for lib in "${temp_prefix}/lib"/*.a; do
      libname="$(basename "$lib")"
      universal_lib="${STAGING_DIR}/lib/${libname}"

      if [[ -f "$universal_lib" ]]; then
        lipo -create "$universal_lib" "$lib" -output "$universal_lib.universal"
        mv "$universal_lib.universal" "$universal_lib"
      else
        # Library exists only in this architecture – copy it.
        cp "$lib" "$universal_lib"
      fi
    done

    # Clean up temp prefix to save space (headers are identical)
    rm -rf "$temp_prefix"
  done

  log "libjpeg-turbo universal static libraries created"
else
  log "libjpeg-turbo already built – skipping"
fi

# ----- 3.1.1 libpng -----------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libpng.a" ]]; then
  log "Building libpng ${LIBPNG_VERSION} (static, universal)"
  libpng_src=$(fetch_and_extract "$LIBPNG_URL" "$LIBPNG_SHA256" | tail -n1)
  cmake_build_install "$libpng_src" "$libpng_src/build" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DPNG_SHARED=OFF \
     -DPNG_STATIC=ON \
     -DPNG_FRAMEWORK=OFF \
     -DPNG_HARDWARE_OPTIMIZATIONS=ON \
     -DPNG_ARM_NEON=ON \
     -DPNG_ARM_NEON_OPT=2
else
  log "libpng already built – skipping"
fi

# ----- 3.1.6 libgif -----------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libgif.a" ]]; then
  log "Building libgif ${LIBGIF_VERSION} (static, universal) - Manual Compilation"
  libgif_src=$(fetch_and_extract "$LIBGIF_URL" "$LIBGIF_SHA256" | tail -n1)

  IFS=';' read -r -a _arch_array <<< "$ARCHS"
  
  # Compile each .c file for each architecture and then lipo them
  for arch in "${_arch_array[@]}"; do
    log "Compiling libgif for ${arch}..."
    obj_dir="${libgif_src}/obj-${arch}"
    mkdir -p "$obj_dir"
    
    for c_file in $(find "$libgif_src" -maxdepth 1 -name "*.c"); do
      obj_file="${obj_dir}/$(basename "${c_file%.c}.o")"
      clang -c "$c_file" -o "$obj_file" -arch "$arch" -D_Float16=float -O2 -fPIC -Wall -Wno-format-truncation
    done
  done

  # Lipo object files and create static library
  all_obj_files=()
  for c_file in $(find "$libgif_src" -maxdepth 1 -name "*.c"); do
    base_name="$(basename "${c_file%.c}")"
    lipo_obj="${libgif_src}/obj-${base_name}.o"
    lipo -create "${libgif_src}/obj-x86_64/${base_name}.o" "${libgif_src}/obj-arm64/${base_name}.o" -output "$lipo_obj"
    all_obj_files+=("$lipo_obj")
  done

  ar rcs "${STAGING_DIR}/lib/libgif.a" "${all_obj_files[@]}"
  cp "${libgif_src}/gif_lib.h" "${STAGING_DIR}/include/"

  log "libgif universal static libraries created"
else
  log "libgif already built – skipping"
fi

# ----- 3.1.7 libdeflate -------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libdeflate.a" ]]; then
  log "Building libdeflate ${LIBDEFLATE_VERSION} (static, universal)"
  libdeflate_src=$(fetch_and_extract "$LIBDEFLATE_URL" "$LIBDEFLATE_SHA256" | tail -n1)

  IFS=';' read -r -a _arch_array <<< "$ARCHS"
  first_arch="${_arch_array[0]}"

  # Build for the first architecture directly into STAGING_DIR
  cmake_build_install "$libdeflate_src" "$libdeflate_src/build-${first_arch}" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="${first_arch}" \
     -DBUILD_SHARED_LIBS=OFF

  # If additional architectures are requested, build them into a temporary
  # prefix and merge the resulting static libs using `lipo`.
  for arch in "${_arch_array[@]:1}"; do
    temp_prefix="${STAGING_DIR}-${arch}"
    log "Building libdeflate for ${arch} ..."

    cmake_build_install "$libdeflate_src" "$libdeflate_src/build-${arch}" \
       -DCMAKE_INSTALL_PREFIX="${temp_prefix}" \
       -DCMAKE_OSX_ARCHITECTURES="${arch}" \
       -DBUILD_SHARED_LIBS=OFF

    # Merge *.a static libraries with the ones already in STAGING_DIR.
    for lib in "${temp_prefix}/lib"/*.a; do
      libname="$(basename "$lib")"
      universal_lib="${STAGING_DIR}/lib/${libname}"

      if [[ -f "$universal_lib" ]]; then
        lipo -create "$universal_lib" "$lib" -output "$universal_lib.universal"
        mv "$universal_lib.universal" "$universal_lib"
      else
        # Library exists only in this architecture – copy it.
        cp "$lib" "$universal_lib"
      fi
    done

    # Clean up temp prefix to save space (headers are identical)
    rm -rf "$temp_prefix"
  done

  log "libdeflate universal static libraries created"
else
  log "libdeflate already built – skipping"
fi

# ----- 3.1.5 libwebp ----------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libwebp.a" ]]; then
  log "Building libwebp ${LIBWEBP_VERSION} (static, universal)"
  libwebp_src=$(fetch_and_extract "$LIBWEBP_URL" "$LIBWEBP_SHA256" | tail -n1)

  IFS=';' read -r -a _arch_array <<< "$ARCHS"
  first_arch="${_arch_array[0]}"

  # Build for the first architecture directly into STAGING_DIR
  cmake_build_install "$libwebp_src" "$libwebp_src/build-${first_arch}" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="${first_arch}" \
     -DBUILD_SHARED_LIBS=OFF \
     -DWEBP_BUILD_EXTRAS=OFF

  # If additional architectures are requested, build them into a temporary
  # prefix and merge the resulting static libs using `lipo`.
  for arch in "${_arch_array[@]:1}"; do
    temp_prefix="${STAGING_DIR}-${arch}"
    log "Building libwebp for ${arch} ..."

    cmake_build_install "$libwebp_src" "$libwebp_src/build-${arch}" \
       -DCMAKE_INSTALL_PREFIX="${temp_prefix}" \
       -DCMAKE_OSX_ARCHITECTURES="${arch}" \
       -DBUILD_SHARED_LIBS=OFF \
       -DWEBP_BUILD_EXTRAS=OFF

    # Merge *.a static libraries with the ones already in STAGING_DIR.
    for lib in "${temp_prefix}/lib"/*.a; do
      libname="$(basename "$lib")"
      universal_lib="${STAGING_DIR}/lib/${libname}"

      if [[ -f "$universal_lib" ]]; then
        lipo -create "$universal_lib" "$lib" -output "$universal_lib.universal"
        mv "$universal_lib.universal" "$universal_lib"
      else
        # Library exists only in this architecture – copy it.
        cp "$lib" "$universal_lib"
      fi
    done

    # Clean up temp prefix to save space (headers are identical)
    rm -rf "$temp_prefix"
  done

  log "libwebp universal static libraries created"
else
  log "libwebp already built – skipping"
fi

# ----- 3.1.3 libtiff ----------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libtiff.a" ]]; then
  log "Building libtiff ${LIBTIFF_VERSION} (static, universal)"
  libtiff_src=$(fetch_and_extract "$LIBTIFF_URL" "$LIBTIFF_SHA256" | tail -n1)
  
  # Build libtiff with universal architecture support
  # Use per-architecture build approach like we do for other libraries
  IFS=';' read -r -a _arch_array <<< "$ARCHS"
  first_arch="${_arch_array[0]}"

  # Build for the first architecture directly into STAGING_DIR
  cmake_build_install "$libtiff_src" "$libtiff_src/build-${first_arch}" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="${first_arch}" \
     -DBUILD_SHARED_LIBS=OFF \
     -DWebP_LIBRARY="${STAGING_DIR}/lib/libwebp.a;${STAGING_DIR}/lib/libsharpyuv.a" \
     -DWebP_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DDEFLATE_LIBRARY="${STAGING_DIR}/lib/libdeflate.a" \
     -DDEFLATE_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DJPEG_LIBRARY="${STAGING_DIR}/lib/libjpeg.a" \
     -DJPEG_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DPNG_LIBRARY="${STAGING_DIR}/lib/libpng.a" \
     -DPNG_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DGIF_LIBRARY="${STAGING_DIR}/lib/libgif.a" \
     -DGIF_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DCMAKE_FIND_LIBRARY_SUFFIXES=.a

  # If additional architectures are requested, build them into a temporary
  # prefix and merge the resulting static libs using `lipo`.
  for arch in "${_arch_array[@]:1}"; do
    temp_prefix="${STAGING_DIR}-${arch}"
    log "Building libtiff for ${arch} ..."

    cmake_build_install "$libtiff_src" "$libtiff_src/build-${arch}" \
       -DCMAKE_INSTALL_PREFIX="${temp_prefix}" \
       -DCMAKE_OSX_ARCHITECTURES="${arch}" \
       -DBUILD_SHARED_LIBS=OFF \
       -DWebP_LIBRARY="${STAGING_DIR}/lib/libwebp.a;${STAGING_DIR}/lib/libsharpyuv.a" \
       -DWebP_INCLUDE_DIR="${STAGING_DIR}/include" \
       -DDEFLATE_LIBRARY="${STAGING_DIR}/lib/libdeflate.a" \
       -DDEFLATE_INCLUDE_DIR="${STAGING_DIR}/include" \
       -DJPEG_LIBRARY="${STAGING_DIR}/lib/libjpeg.a" \
       -DJPEG_INCLUDE_DIR="${STAGING_DIR}/include" \
       -DPNG_LIBRARY="${STAGING_DIR}/lib/libpng.a" \
       -DPNG_INCLUDE_DIR="${STAGING_DIR}/include" \
       -DGIF_LIBRARY="${STAGING_DIR}/lib/libgif.a" \
       -DGIF_INCLUDE_DIR="${STAGING_DIR}/include" \
       -DCMAKE_FIND_LIBRARY_SUFFIXES=.a

    # Merge *.a static libraries with the ones already in STAGING_DIR.
    for lib in "${temp_prefix}/lib"/*.a; do
      libname="$(basename "$lib")"
      universal_lib="${STAGING_DIR}/lib/${libname}"

      if [[ -f "$universal_lib" ]]; then
        lipo -create "$universal_lib" "$lib" -output "$universal_lib.universal"
        mv "$universal_lib.universal" "$universal_lib"
      else
        # Library exists only in this architecture – copy it.
        cp "$lib" "$universal_lib"
      fi
    done

    # Clean up temp prefix to save space (headers are identical)
    rm -rf "$temp_prefix"
  done

  log "libtiff universal static libraries created"
else
  log "libtiff already built – skipping"
fi




# ----- 3.1.2 openjpeg ---------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libopenjp2.a" ]]; then
  log "Building openjpeg ${OPENJPEG_VERSION} (static, universal)"
  openjpeg_src=$(fetch_and_extract "$OPENJPEG_URL" "$OPENJPEG_SHA256" | tail -n1)
  cmake_build_install "$openjpeg_src" "$openjpeg_src/build" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DBUILD_SHARED_LIBS=OFF \
     -DTIFF_LIBRARY="${STAGING_DIR}/lib/libtiff.a" \
     -DTIFF_INCLUDE_DIR="${STAGING_DIR}/include"
else
  log "openjpeg already built – skipping"
fi

# ----- 3.1.4 lcms2 ------------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/liblcms2.a" ]]; then
  log "Building lcms2 ${LCMS2_VERSION} (static, universal)"
  lcms2_src=$(fetch_and_extract "$LCMS2_URL" "$LCMS2_SHA256" | tail -n1)
  cmake_build_install "$lcms2_src" "$lcms2_src/build" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DBUILD_SHARED_LIBS=OFF
else
  log "lcms2 already built – skipping"
fi




# ----- 3.1.4 freetype ---------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libfreetype.a" ]]; then
  log "Building freetype ${FREETYPE_VERSION} (static, universal)"
  freetype_src=$(fetch_and_extract "$FREETYPE_URL" "$FREETYPE_SHA256" | tail -n1)
  cmake_build_install "$freetype_src" "$freetype_src/build" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DBUILD_SHARED_LIBS=OFF
else
  log "freetype already built – skipping"
fi

# ----- 3.1.5 fontconfig -------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libfontconfig.a" ]]; then
  log "Building fontconfig ${FONTCONFIG_VERSION} (static, universal)"
  fontconfig_src=$(fetch_and_extract "$FONTCONFIG_URL" "$FONTCONFIG_SHA256" | tail -n1)
  # Fontconfig uses autotools, not cmake
  pushd "$fontconfig_src" >/dev/null
  ./configure --prefix="${STAGING_DIR}" --enable-static --disable-shared --disable-docs
  make -j$(sysctl -n hw.ncpu)
  make install
  popd >/dev/null
else
  log "fontconfig already built – skipping"
fi

# ----- 3.1.6 cairo ------------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libcairo.a" ]]; then
  log "Building cairo ${CAIRO_VERSION} (static, universal)"
  cairo_src=$(fetch_and_extract "$CAIRO_URL" "$CAIRO_SHA256" | tail -n1)
  # Cairo uses autotools, not cmake
  pushd "$cairo_src" >/dev/null
  ./configure --prefix="${STAGING_DIR}" --enable-static --disable-shared --enable-pdf=no --enable-ps=no --enable-xlib=no --enable-xlib-render=no --enable-xcb=no --enable-xlib-xcb=no --enable-xcb-shm=no --enable-win32=no --enable-win32-font=no --enable-svg=no --enable-gobject=no --enable-trace=no --enable-interpreter=no
  make -j$(sysctl -n hw.ncpu)
  make install
  popd >/dev/null
else
  log "cairo already built – skipping"
fi

# ----- 3.1.7 nss --------------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libnss3.a" ]]; then
  log "Building nss ${NSS_VERSION} (static, universal)"
  nss_src=$(fetch_and_extract "$NSS_URL" "$NSS_SHA256" | tail -n1)
  pushd "$nss_src" >/dev/null
  # NSS has a complex build system. This is a placeholder.
  # Need to figure out how to build it statically and universally.
  # Likely involves setting environment variables like ARCHS and using 'make'.
  # For now, just a placeholder to get the structure in place.
  popd >/dev/null
else
  log "nss already built – skipping"
fi

# ----- 3.1.8 gpgme ------------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libgpgme.a" ]]; then
  log "Building gpgme ${GPGME_VERSION} (static, universal)"
  gpgme_src=$(fetch_and_extract "$GPGME_URL" "$GPGME_SHA256" | tail -n1)
  pushd "$gpgme_src" >/dev/null
  ./configure --prefix="${STAGING_DIR}" --enable-static --disable-shared --host="${ARCHS//;/-}"
  make -j$(sysctl -n hw.ncpu)
  make install
  popd >/dev/null
else
  log "gpgme already built – skipping"
fi










# ----- 3.2 Poppler ------------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/lib/libpoppler.a" ]]; then
  log "Building Poppler ${POPPLER_VERSION} (static, universal)"
  poppler_src=$(fetch_and_extract "$POPPLER_URL" "$POPPLER_SHA256" | tail -n1)
  # Poppler expects a writable test directory; create dummy to silence cmake.
  mkdir -p "$poppler_src/test"
  cmake_build_install "$poppler_src" "$poppler_src/build" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DBUILD_SHARED_LIBS=OFF \
     -DENABLE_GLIB=ON \
     -DENABLE_UTILS=OFF \
     -DENABLE_CPP=OFF \
     -DENABLE_QT5=OFF \
     -DENABLE_QT6=OFF \
     -DENABLE_LIBTIFF=OFF \
     -DENABLE_LIBOPENJPEG=openjpeg2 \
     -DENABLE_CMS=lcms2 \
     -DWITH_JPEG=ON \
     -DENABLE_DCTDECODER=libjpeg \
     -DENABLE_LIBJPEG=ON \
     -DJPEG_LIBRARY="${STAGING_DIR}/lib/libjpeg.a" \
     -DJPEG_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DOPENJPEG_LIBRARY="${STAGING_DIR}/lib/libopenjp2.a" \
     -DOPENJPEG_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DLIBPNG_LIBRARY="${STAGING_DIR}/lib/libpng.a" \
     -DLIBPNG_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DLCMS2_LIBRARY="${STAGING_DIR}/lib/liblcms2.a" \
     -DLCMS2_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DFREETYPE_LIBRARY="${STAGING_DIR}/lib/libfreetype.a" \
     -DFREETYPE_INCLUDE_DIR="${STAGING_DIR}/include" \
     -DFONTCONFIG_LIBRARY="${STAGING_DIR}/lib/libfontconfig.a" \
     -DFONTCONFIG_INCLUDE_DIR="${STAGING_DIR}/include"
else
  log "Poppler already built – skipping"
fi

# ----- 3.3 FontForge ----------------------------------------------------------

if [[ ! -f "${STAGING_DIR}/bin/fontforge" ]]; then
  log "Building FontForge ${FONTFORGE_VERSION} (static, headless, universal)"
  ff_src=$(fetch_and_extract "$FONTFORGE_URL" "$FONTFORGE_SHA256" | tail -n1)
  # Disable PO translation build that fails on missing gettext .po timestamps
  if grep -q "add_custom_target(pofiles ALL" "$ff_src/po/CMakeLists.txt"; then
    sed -i.bak 's/add_custom_target(pofiles ALL/add_custom_target(pofiles/' "$ff_src/po/CMakeLists.txt"
  fi
  cmake_build_install "$ff_src" "$ff_src/build" \
     -DCMAKE_INSTALL_PREFIX="${STAGING_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DBUILD_SHARED_LIBS=OFF \
     -DENABLE_GUI=OFF \
     -DENABLE_NATIVE_SCRIPTING=ON \
     -DENABLE_PYTHON_SCRIPTING=OFF
else
  log "FontForge already built – skipping"
fi

# ----- 3.4 pdf2htmlEX ---------------------------------------------------------

if [[ ! -f "${DIST_DIR}/bin/pdf2htmlEX" ]]; then
  log "Building pdf2htmlEX ${PDF2HTML_VERSION} (linking staged libs)"
  # The GitHub release archive nests sources inside a second-level directory
  # ("pdf2htmlEX-<ver>/pdf2htmlEX/").  We strip that first component so that
  # the extraction result contains the actual project root with CMakeLists.txt
  # directly at $pdf2_src/.
  #
  #   Before stripping:  $SRC_DIR/pdf2htmlEX-0.18.8.rc1/pdf2htmlEX/CMakeLists.txt
  #   After stripping :  $SRC_DIR/pdf2htmlEX-0.18.8.rc1/CMakeLists.txt
  #
  # We pass the optional third argument (tar options) supported by
  # fetch_and_extract which is forwarded to tar.
  pdf2_src=$(fetch_and_extract "$PDF2HTML_URL" "$PDF2HTML_SHA256" "--strip-components=1" | tail -n1)

  # Pdf2htmlEX expects poppler/fontforge trees at sibling paths when doing in-
  # source build; replicate that by symlinking staged prefix dirs.
  ln -sf "${STAGING_DIR}" "$pdf2_src/poppler"   # only headers/libs needed
  ln -sf "${STAGING_DIR}" "$pdf2_src/fontforge"

  cmake_build_install "$pdf2_src" "$pdf2_src/build" \
     -DCMAKE_INSTALL_PREFIX="${DIST_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
     -DCMAKE_PREFIX_PATH="${STAGING_DIR}" \
     -DPOPPLER_STATIC=ON \
     -DFONTFORGE_STATIC=ON

  # Copy licence & share data for completeness
  cp -R "$pdf2_src/share" "$DIST_DIR/" 2>/dev/null || true
else
  log "pdf2htmlEX already built – skipping"
fi

#####################################
# 4.  Verification                    #
#####################################

BIN="${DIST_DIR}/bin/pdf2htmlEX"
if [[ ! -x "$BIN" ]]; then
  echo "Build failed: $BIN not found." >&2
  exit 1
fi

log "Verifying universal binary:"
file "$BIN" | tee /dev/stderr

log "Linkage (expect only system libs):"
otool -L "$BIN" | tee /dev/stderr

log "Build complete!  pdf2htmlEX located at $BIN"

# Optional quick self-test if sample PDF exists
SAMPLE_PDF="${ROOT_DIR}/testdata/sample.pdf"
if [[ -f "$SAMPLE_PDF" ]]; then
  log "Running quick conversion test on testdata/sample.pdf …"
  mkdir -p "${BUILD_DIR}/testout"
  "$BIN" --dest-dir "${BUILD_DIR}/testout" "$SAMPLE_PDF" >/dev/null 2>&1 || {
    echo "pdf2htmlEX test conversion failed" >&2; exit 1; }
  log "Test conversion succeeded (output in build/testout)"
else
  log "No sample PDF found – skipping functional test"
fi

echo "\n✅ All done – enjoy your local build!"
