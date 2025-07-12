# typed: false
# frozen_string_literal: true

#
# This is a template for the pdf2htmlEX Homebrew formula.
#
# It's designed for an iterative development process, as outlined in PLAN.md.
# Each iteration will start from this template and test a specific hypothesis.
#
# Key areas to modify for each iteration:
# 1.  `resource "poppler"`: Update version, URL, and SHA256.
# 2.  `resource "fontforge"`: Update version, URL, and SHA256.
# 3.  `install` method: Adjust CMake flags or add patches as needed.
#

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v0.18.8.rc1.tar.gz"
  version "0.18.8.rc1"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  # The revision will be updated with each iteration.
  revision 1

  # ----------------------------------------------------------------------------
  # Build Dependencies
  # ----------------------------------------------------------------------------
  # These are required for compiling pdf2htmlEX and its dependencies.
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "openjdk" => :build # For CSS/JS minification

  # ----------------------------------------------------------------------------
  # Runtime Dependencies
  # ----------------------------------------------------------------------------
  # These are libraries that pdf2htmlEX and its dependencies link against.
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "libxml2"
  depends_on "pango"
  depends_on "harfbuzz"

  # ----------------------------------------------------------------------------
  # Vendored Dependencies (Resources)
  # ----------------------------------------------------------------------------
  # pdf2htmlEX requires specific, older versions of poppler and fontforge.
  # We build them from source as "resources" to avoid conflicts with
  # modern versions from Homebrew.

  resource "poppler" do
    # ==> TODO: Set Poppler version and SHA256 for the iteration.
    url "https://poppler.freedesktop.org/poppler-POPPLER_VERSION.tar.xz"
    sha256 "POPPLER_SHA256"
  end

  resource "fontforge" do
    # ==> TODO: Set FontForge version and SHA256 for the iteration.
    url "https://github.com/fontforge/fontforge/releases/download/FONTFORGE_VERSION/fontforge-FONTFORGE_VERSION.tar.gz"
    sha256 "FONTFORGE_SHA256"
  end

  # ----------------------------------------------------------------------------
  # Installation
  # ----------------------------------------------------------------------------
  def install
    # Staging prefix for our custom-built dependencies (poppler, fontforge).
    # This keeps them isolated from the main Homebrew prefix.
    staging_prefix = buildpath/"staging"
    staging_prefix.mkpath

    # Enable C++11 standard, required by pdf2htmlEX.
    ENV.cxx11

    # Define architectures for universal binary (Intel + Apple Silicon).
    archs = "x86_64;arm64"

    # Create a consolidated prefix path for all dependencies.
    # This simplifies passing paths to CMake.
    cmake_prefix_paths = [
      Formula["cairo"].opt_prefix,
      Formula["fontconfig"].opt_prefix,
      Formula["freetype"].opt_prefix,
      Formula["gettext"].opt_prefix,
      Formula["glib"].opt_prefix,
      Formula["jpeg-turbo"].opt_prefix,
      Formula["libpng"].opt_prefix,
      Formula["libtiff"].opt_prefix,
      Formula["libxml2"].opt_prefix,
      Formula["pango"].opt_prefix,
      Formula["harfbuzz"].opt_prefix,
    ].join(";")

    # --- Stage 1: Build Poppler from source ---
    resource("poppler").stage do
      # Note: Some Poppler versions may need patches or inreplace calls.
      # Example from a previous attempt for 0.82.0:
      # inreplace "glib/poppler-private.h",
      #           "static volatile gsize g_define_type_id__volatile = 0;",
      #           "static gsize g_define_type_id__volatile = 0;"

      mkdir "build" do
        system "cmake", "..",
               "-G", "Ninja",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
               "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
               "-DCMAKE_PREFIX_PATH=#{cmake_prefix_paths}",
               "-DENABLE_UNSTABLE_API_ABI_HEADERS=ON", # Required by pdf2htmlEX
               "-DBUILD_SHARED_LIBS=OFF",              # Build static libs
               "-DENABLE_GLIB=ON",                     # GLib support is mandatory
               "-DWITH_GObject=ON",
               # Disable features we don't need to speed up the build
               "-DENABLE_QT5=OFF",
               "-DENABLE_CPP=OFF",
               "-DENABLE_UTILS=OFF",
               "-DBUILD_GTK_TESTS=OFF",
               "-DENABLE_CMS=none",
               "-DENABLE_LIBOPENJPEG=none"

        system "ninja", "install"
      end
    end

    # --- Stage 2: Build FontForge from source ---
    resource("fontforge").stage do
      mkdir "build" do
        system "cmake", "..",
               "-G", "Ninja",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
               "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
               # Point to our staged dependencies as well as system ones
               "-DCMAKE_PREFIX_PATH=#{staging_prefix};#{cmake_prefix_paths}",
               "-DBUILD_SHARED_LIBS=OFF", # Build static libs
               # Disable features we don't need
               "-DENABLE_GUI=OFF",
               "-DENABLE_PYTHON_SCRIPTING=OFF",
               "-DENABLE_PYTHON_EXTENSION=OFF",
               "-DENABLE_NLS=OFF"

        system "ninja", "install"
      end
    end

    # --- Stage 3: Build pdf2htmlEX ---
    # According to PLAN.md, pdf2htmlEX's CMakeLists.txt has hardcoded paths.
    # The build might fail here.
    #
    # Possible solutions from PLAN.md:
    # 1.  In-source build: Unpack resources into a specific directory structure.
    # 2.  Symlinks: Create symlinks to trick CMake into finding the libs.
    # 3.  Patching: Patch the CMakeLists.txt file.
    # 4.  CMake variables: Override `POPPLER_LIBRARIES` and `FONTFORGE_LIBRARIES`.

    # Make sure pkg-config can find our staged dependencies.
    ENV.prepend_path "PKG_CONFIG_PATH", "#{staging_prefix}/lib/pkgconfig"
    # Set JAVA_HOME for the minifier.
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix

    # Note: `test.py.in` might be missing. Create a placeholder if needed.
    # File.write("test/test.py.in", "")

    mkdir "build" do
      system "cmake", "..",
             "-G", "Ninja",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DCMAKE_INSTALL_PREFIX=#{prefix}",
             "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
             # Point to our staged dependencies
             "-DCMAKE_PREFIX_PATH=#{staging_prefix}",
             "-DTEST_MODE=OFF"

      system "ninja", "install"
    end
  end

  # ----------------------------------------------------------------------------
  # Test Block
  # ----------------------------------------------------------------------------
  test do
    # A simple test to ensure the binary runs and reports its version.
    system bin/"pdf2htmlEX", "--version"
  end
end 