# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v0.18.8.rc1.tar.gz"
  version "0.18.8.rc1"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  revision 14

  # Universal build supported
  # We will build from source, bottles can be added later

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "openjdk" => :build # For YUI Compressor and Closure Compiler

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
    url "https://poppler.freedesktop.org/poppler-0.82.0.tar.xz"
    sha256 "234f8e573ea57fb6a008e7c1e56bfae1af5d1adf0e65f47555e1ae103874e4df"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/releases/download/20190801/fontforge-20190801.tar.gz"
    sha256 "d92075ca783c97dc68433b1ed629b9054a4b4c74ac64c54ced7f691540f70852"
  end

  def install
    ohai "pdf2htmlEX Build Process Starting"
    
    staging_prefix = buildpath/"staging"
    ENV.cxx11

    # Remove march flags that can cause issues.
    ENV.remove "HOMEBREW_CFLAGS", / ?-march=\S*/
    ENV.remove "HOMEBREW_CXXFLAGS", / ?-march=\S*/

    archs = "x86_64;arm64"
    ohai "Building for architectures: #{archs.gsub(";", ", ")}"

    # Centralized CMAKE_PREFIX_PATH for all Homebrew deps
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

    # Stage 1: Build Poppler
    ohai "Building Poppler 0.82.0..."
    resource("poppler").stage do
      # Patch poppler glib before building to fix build with newer glib
      inreplace "glib/poppler-private.h",
                "static volatile gsize g_define_type_id__volatile = 0;",
                "static gsize g_define_type_id__volatile = 0;"

      mkdir "build" do
        system "cmake", "..",
               "-G", "Ninja",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
               "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
               "-DCMAKE_PREFIX_PATH=#{cmake_prefix_paths}",
               "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
               "-DBUILD_GTK_TESTS=OFF",
               "-DENABLE_CMS=none",
               "-DENABLE_GLIB=ON",
               "-DENABLE_QT5=OFF",
               "-DENABLE_UNSTABLE_API_ABI_HEADERS=ON",
               "-DWITH_GObject=ON",
               "-DENABLE_GOBJECT_INTROSPECTION=ON",
               "-DFONT_CONFIGURATION=fontconfig",
               "-DBUILD_SHARED_LIBS=OFF",
               "-DENABLE_CPP=OFF",
               "-DENABLE_UTILS=OFF",
               "-DENABLE_LIBOPENJPEG=none",
               "-DENABLE_SPLASH=ON",
               "-DENABLE_DCTDECODER=libjpeg",
               "-DRUN_GPERF_IF_PRESENT=OFF"
        system "ninja", "install"
      end
    end
    ohai "✓ Poppler built successfully"

    # Stage 2: Build FontForge
    ohai "Building FontForge 20190801..."
    resource("fontforge").stage do
      cd "fontforge-20190801" do
        (buildpath/"disable-gettext.patch").write <<~EOS
          --- a/po/CMakeLists.txt
          +++ b/po/CMakeLists.txt
          @@ -0,0 +1,1 @@
          +return()
        EOS
        system "patch", "-p1", "-i", buildpath/"disable-gettext.patch"

        mkdir "build" do
          system "cmake", "..",
                 "-G", "Ninja",
                 "-DCMAKE_BUILD_TYPE=Release",
                 "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
                 "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
                 "-DCMAKE_PREFIX_PATH=#{staging_prefix};#{cmake_prefix_paths}",
                 "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                 "-DENABLE_GUI=OFF",
                 "-DENABLE_PYTHON_SCRIPTING=OFF",
                 "-DENABLE_PYTHON_EXTENSION=OFF",
                 "-DBUILD_SHARED_LIBS=OFF"
          system "ninja", "install"
          system "cp", "lib/libfontforge.a", "#{staging_prefix}/lib/"
        end
      end
    end
    ohai "✓ FontForge built successfully"

    # Stage 3: Build pdf2htmlEX
    ohai "Building pdf2htmlEX #{version}..."
    ENV.prepend_path "PKG_CONFIG_PATH", "#{staging_prefix}/lib/pkgconfig"
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix

    # The actual source is in a subdirectory
    cd "pdf2htmlEX" do
        mkdir "build" do
          system "cmake", "..",
                 "-G", "Ninja",
                 "-DCMAKE_BUILD_TYPE=Release",
                 "-DCMAKE_INSTALL_PREFIX=#{prefix}",
                 "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
                 "-DCMAKE_PREFIX_PATH=#{staging_prefix}",
                 "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                 "-DTEST_MODE=OFF"
          system "ninja", "install"
        end
    end
    ohai "✓ pdf2htmlEX built successfully"

    # Final validation
    ohai "Running post-build validation..."
    system bin/"pdf2htmlEX", "--version"
    ohai "✓ Build completed successfully!"
  end

  test do
    (testpath/"test.pdf").write <<~EOS
      %PDF-1.4
      1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
      2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
      3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj
      4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
      5 0 obj<</Length 100>>stream
      BT /F1 24 Tf 100 700 Td (pdf2htmlEX test) Tj ET
      endstream
      endobj
      xref
      0 6
      0000000000 65535 f
      0000000009 00000 n
      0000000052 00000 n
      0000000101 00000 n
      0000000191 00000 n
      0000000242 00000 n
      trailer<</Size 6/Root 1 0 R>>
      startxref
      357
      %%EOF
    EOS
    system bin/"pdf2htmlEX", testpath/"test.pdf"
    assert_predicate testpath/"test.html", :exist?, "test.html should be created"
    assert_match "pdf2htmlEX test", (testpath/"test.html").read, "Output HTML should contain text from PDF"
  end
end