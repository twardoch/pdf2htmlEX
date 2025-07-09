# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  version "0.18.8.rc1"

  bottle do
    # Bottles will be added after successful builds
  end

  # Build dependencies
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "openjdk" => :build # For CSS/JS minification
  
  # Runtime dependencies for vendored builds
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
  depends_on "little-cms2"
  depends_on "openjpeg"

  # Vendored dependencies with exact versions required by pdf2htmlEX
  resource "poppler" do
    url "https://poppler.freedesktop.org/poppler-24.01.0.tar.xz"
    sha256 "c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/archive/20230101.tar.gz"
    sha256 "ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"
  end

  def install
    # Set up build environment
    ENV.cxx11
    
    # Set up staging directory for building dependencies
    staging_prefix = buildpath/"staging"
    
    # Make sure pkg-config can find our staged dependencies
    ENV.prepend_path "PKG_CONFIG_PATH", "#{staging_prefix}/lib/pkgconfig"
    # Set JAVA_HOME for the minifier
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix

    # Common CMake arguments for all builds
    archs = "x86_64;arm64"  # Universal binary support
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
      Formula["little-cms2"].opt_prefix,
      Formula["openjpeg"].opt_prefix,
    ].join(";")

    # --- Stage 1: Build Poppler 24.01.0 from source ---
    resource("poppler").stage do
      # Simply disable DCTStream by replacing it with a minimal stub implementation
      # This is safer than trying to remove parts of Stream.cc
      File.write("poppler/DCTStream.cc", <<~EOS)
        // Minimal DCTStream stub implementation - JPEG support disabled
        #include "DCTStream.h"
        #include "Error.h"
        
        DCTStream::DCTStream(Stream *strA, int colorTransformA, Dict *dict, int recursion) : FilterStream(strA) {
          error(errSyntaxError, -1, "DCTStream support disabled in this build");
        }
        
        DCTStream::~DCTStream() {
          delete str;
        }
        
        void DCTStream::reset() {
          // No-op
        }
        
        int DCTStream::getChar() {
          return EOF;
        }
        
        int DCTStream::lookChar() {
          return EOF;
        }
        
        GooString *DCTStream::getPSFilter(int psLevel, const char *indent) {
          return nullptr;
        }
        
        bool DCTStream::isBinary(bool last) const {
          return true;
        }
      EOS
      
      # Remove DCTStream definition from Stream.h to avoid redefinition
      inreplace "poppler/Stream.h" do |s|
        s.gsub!(/^class DCTStream.*?\n\{.*?\n\};/m, "// DCTStream removed - JPEG support disabled")
      end
      
      # Remove DCTStream implementations from Stream.cc
      # Read the file, process it, and write it back
      stream_content = File.read("poppler/Stream.cc")
      lines = stream_content.split("\n")
      new_lines = []
      in_dct_method = false
      brace_count = 0
      
      lines.each do |line|
        if line.match(/DCTStream::/)
          in_dct_method = true
          brace_count = 0
          new_lines << "// DCTStream method removed - JPEG support disabled"
        elsif in_dct_method
          # Count braces to find the end of the method
          brace_count += line.count('{')
          brace_count -= line.count('}')
          # If we're back to 0 braces, the method is complete
          if brace_count <= 0
            in_dct_method = false
          end
        else
          new_lines << line
        end
      end
      
      File.write("poppler/Stream.cc", new_lines.join("\n"))
      
      mkdir "build" do
        args = %W[
          -DCMAKE_BUILD_TYPE=Release
          -DCMAKE_INSTALL_PREFIX=#{staging_prefix}
          -DCMAKE_OSX_ARCHITECTURES=#{archs}
          -DCMAKE_PREFIX_PATH=#{cmake_prefix_paths}
          -DCMAKE_POLICY_VERSION_MINIMUM=3.5
          -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
          -DBUILD_SHARED_LIBS=OFF
          -DENABLE_GLIB=ON
          -DWITH_GObject=ON
          -DENABLE_QT5=OFF
          -DENABLE_QT6=OFF
          -DENABLE_CPP=OFF
          -DENABLE_UTILS=OFF
          -DBUILD_GTK_TESTS=OFF
          -DENABLE_CMS=lcms2
          -DENABLE_LIBTIFF=OFF
          -DENABLE_DCTDECODER=none
          -DENABLE_LIBJPEG=OFF
        ]

        system "cmake", "..", "-G", "Ninja", *args
        system "ninja", "install"
      end
    end

    # --- Stage 2: Build FontForge 20230101 from source ---
    resource("fontforge").stage do
      # Disable NLS build, which fails with recent gettext versions.
      inreplace "po/CMakeLists.txt", "add_custom_target(pofiles ALL DEPENDS ${_outputs})", "add_custom_target(pofiles DEPENDS ${_outputs})"
      inreplace "po/CMakeLists.txt", 'install(FILES "${_output}" DESTINATION "${CMAKE_INSTALL_LOCALEDIR}/${_lang}/LC_MESSAGES" RENAME "FontForge.mo" COMPONENT pofiles)', '# install(FILES "${_output}" DESTINATION "${CMAKE_INSTALL_LOCALEDIR}/${_lang}/LC_MESSAGES" RENAME "FontForge.mo" COMPONENT pofiles)'

      mkdir "build" do
        args = %W[
          -DCMAKE_BUILD_TYPE=Release
          -DCMAKE_INSTALL_PREFIX=#{staging_prefix}
          -DCMAKE_OSX_ARCHITECTURES=#{archs}
          -DCMAKE_PREFIX_PATH=#{staging_prefix};#{cmake_prefix_paths}
          -DCMAKE_POLICY_VERSION_MINIMUM=3.5
          -DBUILD_SHARED_LIBS=OFF
          -DENABLE_GUI=OFF
          -DENABLE_PYTHON_SCRIPTING=OFF
          -DENABLE_PYTHON_EXTENSION=OFF
          -DENABLE_DOCS=OFF
          -DENABLE_FONTFORGE_EXTRAS=ON
          -DENABLE_NATIVE_SCRIPTING=ON
          -DENABLE_MAINTAINER_TOOLS=OFF
          -DENABLE_FREETYPE_DEBUGGER=OFF
          -DENABLE_LIBSPIRO=OFF
          -DENABLE_LIBUNINAMESLIST=OFF
          -DENABLE_LIBREADLINE=OFF
          -DENABLE_WOFF2=OFF
          -DENABLE_CODE_COVERAGE=OFF
          -DENABLE_SANITIZER=none
        ]

        system "cmake", "..", "-G", "Ninja", *args
        system "ninja", "install"
      end
      (buildpath/"staging/lib").install "build/lib/libfontforge.a"
    end

    # --- Stage 3: Build pdf2htmlEX ---
    # Create missing test.py.in file that CMake expects
    mkdir_p "pdf2htmlEX/test"
    File.write("pdf2htmlEX/test/test.py.in", "")

    # Apply patch
    system "patch", "-p1", "-i", "#{buildpath.parent}/pdf2htmlex-cmake.patch", "-d", "pdf2htmlEX"

    # Change to the pdf2htmlEX subdirectory where CMakeLists.txt is located
    cd "pdf2htmlEX" do
      mkdir "build" do
        args = %W[
          -DCMAKE_BUILD_TYPE=Release
          -DCMAKE_INSTALL_PREFIX=#{prefix}
          -DCMAKE_OSX_ARCHITECTURES=#{archs}
          -DCMAKE_PREFIX_PATH=#{staging_prefix}
          -DCMAKE_POLICY_VERSION_MINIMUM=3.5
          -DENABLE_SVG=ON
          -DPOPPLER_INCLUDE_DIR=#{staging_prefix}/include/poppler
          -DFONTFORGE_INCLUDE_DIR=#{staging_prefix}/include
          -DPOPPLER_LIBRARIES=#{staging_prefix}/lib/libpoppler.a
          -DPOPPLER_GLIB_LIBRARIES=#{staging_prefix}/lib/libpoppler-glib.a
          -DFONTFORGE_LIBRARIES=#{staging_prefix}/lib/libfontforge.a
        ]

        system "cmake", "..", "-G", "Ninja", *args
        system "ninja", "install"
      end
    end
  end

  test do
    # Create a simple test PDF
    (testpath/"test.pdf").write <<~EOF
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
    EOF

    # Test basic conversion
    system bin/"pdf2htmlEX", "test.pdf"
    assert_predicate testpath/"test.html", :exist?
    assert_match "Hello World!", (testpath/"test.html").read

    # Test version output
    assert_match version.to_s, shell_output("#{bin}/pdf2htmlEX --version")
  end
end

