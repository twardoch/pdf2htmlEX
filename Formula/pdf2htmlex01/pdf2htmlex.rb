# typed: false
# frozen_string_literal: true

#
# NOTE: This formula is currently broken and I have been unable to fix it.
# The build process is extremely sensitive to the versions of its dependencies,
# and I have been unable to find a combination that works.
#
class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v0.18.8.rc1.tar.gz"
  version "0.18.8.rc1"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  revision 1

  # Universal build supported
  # bottle :unneeded

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "openjdk" => :build

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

  resource "poppler" do
    url "https://poppler.freedesktop.org/poppler-24.01.0.tar.xz"
    sha256 "c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/archive/refs/tags/20230101.tar.gz"
    sha256 "ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"
  end

  def install
    # Set environment variables for universal build
    ENV["CMAKE_OSX_ARCHITECTURES"] = "x86_64;arm64"
    
    # Build Poppler first (in-source)
    resource("poppler").stage do
      mkdir "poppler" do
        system "tar", "-xf", cached_download, "--strip-components=1"
        
        mkdir "build" do
          cmake_prefix_paths = [
            Formula["cairo"].opt_prefix,
            Formula["fontconfig"].opt_prefix,
            Formula["freetype"].opt_prefix,
            Formula["gettext"].opt_prefix,
            Formula["glib"].opt_prefix,
            Formula["jpeg-turbo"].opt_prefix,
            Formula["libpng"].opt_prefix,
            Formula["libtiff"].opt_prefix,
            Formula["pango"].opt_prefix,
            Formula["harfbuzz"].opt_prefix,
          ]

          args = %W[
            -DCMAKE_INSTALL_PREFIX=#{buildpath}/poppler/build
            -DCMAKE_PREFIX_PATH=#{cmake_prefix_paths.join(";")}
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_OSX_ARCHITECTURES=x86_64;arm64
            -DBUILD_SHARED_LIBS=OFF
            -DENABLE_UNSTABLE_API_ABI_HEADERS=OFF
            -DENABLE_SPLASH=ON
            -DENABLE_GLIB=ON
            -DENABLE_GOBJECT_INTROSPECTION=OFF
            -DENABLE_QT5=OFF
            -DENABLE_QT6=OFF
            -DENABLE_UTILS=OFF
            -DENABLE_CPP=OFF
            -DENABLE_GLIB=ON
            -DENABLE_LIBOPENJPEG=none
            -DENABLE_CMS=none
            -DENABLE_DCTDECODER=libjpeg
            -DENABLE_LIBPNG=ON
            -DENABLE_LIBTIFF=ON
            -DENABLE_NSS3=OFF
            -DENABLE_GPGME=OFF
            -DBUILD_GTK_TESTS=OFF
            -DBUILD_QT5_TESTS=OFF
            -DBUILD_QT6_TESTS=OFF
            -DBUILD_CPP_TESTS=OFF
            -DBUILD_MANUAL_TESTS=OFF
            -GNinja
          ]

          system "cmake", "..", *args
          system "ninja", "install"
          
          # Copy libpoppler.a to where pdf2htmlEX expects it
          cp "lib/libpoppler.a", "../build/"
          cp "lib/libpoppler-glib.a", "../build/"
        end
      end
    end

    # Build FontForge (in-source)
    resource("fontforge").stage do
      mkdir "fontforge" do
        system "tar", "-xf", cached_download, "--strip-components=1"
        
        # Apply patch to disable gettext/localization
        patch_content = <<~PATCH
          --- a/CMakeLists.txt
          +++ b/CMakeLists.txt
          @@ -200,7 +200,7 @@ endif()
           #------------- i18n ----------------
           
           # Native Language Support is used for GUI, shell messages, and hotkeys
          -set(ENABLE_NLS ON CACHE BOOL "Enable Native Language Support")
          +set(ENABLE_NLS OFF CACHE BOOL "Enable Native Language Support")
           if(ENABLE_NLS)
             find_package(Intl REQUIRED)
             find_package(Gettext REQUIRED)
        PATCH
        
        (buildpath/"fontforge/disable_nls.patch").write(patch_content)
        system "patch", "-p1", "-i", "disable_nls.patch"
        
        mkdir "build" do
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
            "#{buildpath}/poppler/build",
          ]

          args = %W[
            -DCMAKE_INSTALL_PREFIX=#{buildpath}/fontforge/build
            -DCMAKE_PREFIX_PATH=#{cmake_prefix_paths.join(";")}
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_OSX_ARCHITECTURES=x86_64;arm64
            -DBUILD_SHARED_LIBS=OFF
            -DENABLE_GUI=OFF
            -DENABLE_NATIVE_SCRIPTING=ON
            -DENABLE_PYTHON_SCRIPTING=OFF
            -DENABLE_PYTHON_EXTENSION=OFF
            -DENABLE_LIBSPIRO=OFF
            -DENABLE_LIBUNINAMESLIST=OFF
            -DENABLE_LIBREADLINE=OFF
            -DENABLE_WOFF2=OFF
            -DENABLE_DOCS=OFF
            -DENABLE_NLS=OFF
            -GNinja
          ]

          system "cmake", "..", *args
          system "ninja", "install"
        end
      end
    end

    # Now build pdf2htmlEX
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
      "#{buildpath}/poppler/build",
      "#{buildpath}/fontforge/build",
    ]

    ENV["PKG_CONFIG_PATH"] = [
      "#{buildpath}/poppler/build/lib/pkgconfig",
      "#{buildpath}/fontforge/build/lib/pkgconfig",
      ENV["PKG_CONFIG_PATH"],
    ].compact.join(":")

    mkdir "build" do
      args = %W[
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DCMAKE_PREFIX_PATH=#{cmake_prefix_paths.join(";")}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_OSX_ARCHITECTURES=x86_64;arm64
        -DENABLE_SVG=ON
        -GNinja
      ]

      system "cmake", "..", *args
      system "ninja", "install"
    end
  end

  test do
    # Create a simple test PDF
    (testpath/"test.pdf").write <<~PDF
      %PDF-1.4
      1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
      2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
      3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj
      4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
      5 0 obj<</Length 44>>stream
      BT /F1 24 Tf 100 700 Td (Hello World!) Tj ET
      endstream
      endobj
      xref
      0 6
      0000000000 65535 f
      0000000009 00000 n
      0000000052 00000 n
      0000000101 00000 n
      0000000229 00000 n
      0000000299 00000 n
      trailer<</Size 6/Root 1 0 R>>
      startxref
      398
      %%EOF
    PDF

    system bin/"pdf2htmlEX", "--version"
    system bin/"pdf2htmlEX", "test.pdf"
    assert_predicate testpath/"test.html", :exist?
  end
end
