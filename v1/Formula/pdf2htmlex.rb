# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  version "0.18.8.rc1"

  # Upstream source requires a handful of minor patches for compatibility with
  # newer Poppler releases.  A minimal CMakeLists adjustment is embedded under
  # __END__.  Additional code-level patches have proven fragile across Poppler
  # versions and are therefore omitted here.

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

  # No external patch; we perform inreplace during install to neutralise
  # hard-coded poppler & fontforge paths in CMakeLists.txt.

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

      # Some parts of pdf2htmlEX expect <fontforge.h> to be available at the
      # root of the include search path.  The upstream FontForge install puts
      # this header inside the sub-directory `fontforge/`.  Provide a shim
      # copy so the include directive resolves without patching the sources.
      dest_dir = "#{staging_prefix}/include/fontforge"
      FileUtils.mkdir_p dest_dir

      installed_header = "#{dest_dir}/fontforge.h"
      source_header = File.exist?("fontforge/fontforge.h") ? "fontforge/fontforge.h" : ff_header

      FileUtils.cp source_header, installed_header unless File.exist?(installed_header)

      # Copy any additional headers that FontForge has generated into the
      # temporary build/inc directory but did not install.  These are required
      # by pdf2htmlEX (e.g. fontforge-config.h).
      # Copy headers from both the build/inc directory (generated) and the
      # original `inc` directory in the source tree.
      Dir.glob("{build/inc,inc}/**/*.h").each do |hdr|
        dest_path = File.join(dest_dir, File.basename(hdr))
        FileUtils.cp hdr, dest_path unless File.exist?(dest_path)
      end

      # Copy *all* FontForge public headers recursively to ensure no missing
      # transitive includes (e.g. basics.h, splinefont.h, etc.).  Keeping the
      # directory layout avoids name clashes and preserves relative includes
      # inside the FontForge codebase.
      Dir.glob("fontforge/**/*.{h,H}").each do |hdr|
        rel_path = Pathname.new(hdr).relative_path_from(Pathname.new("fontforge"))
        target   = staging_prefix/"include"/"fontforge"/rel_path
        FileUtils.mkdir_p target.dirname
        FileUtils.cp hdr, target unless File.exist?(target)
      end
    end

    # --- Stage 3: Build pdf2htmlEX ---
    # Ensure GLib's gio headers are reachable when fontforge headers include
    # <gio/gio.h>.
    ENV.append "CPPFLAGS", "-I#{Formula["glib"].opt_include}/glib-2.0"
    ENV.append "CPPFLAGS", "-I#{Formula["glib"].opt_lib}/glib-2.0/include"
    ENV.append "CFLAGS", "-I#{Formula["glib"].opt_include}/glib-2.0 -I#{Formula["glib"].opt_lib}/glib-2.0/include"
    ENV.append "CXXFLAGS", "-I#{Formula["glib"].opt_include}/glib-2.0 -I#{Formula["glib"].opt_lib}/glib-2.0/include"

    # Create missing test.py.in file that CMake expects
    mkdir_p "pdf2htmlEX/test"
    File.write("pdf2htmlEX/test/test.py.in", "")

    # Apply Poppler 24 compatibility patches
    cd "pdf2htmlEX" do
      # Fix font.cc for Poppler 24 API changes
      inreplace "src/HTMLRenderer/font.cc" do |s|
        # Fix FoFiTrueType::load() usage - returns unique_ptr now
        s.gsub!(/if\(FoFiTrueType\s*\*\s*fftt\s*=\s*FoFiTrueType::load\((.*?)\)\)/, 
                'if(auto fftt = FoFiTrueType::load(\1))')
        
        # Fix font->getName() - returns std::optional<std::string> now
        s.gsub!(/font->getName\(\)->toStr\(\)/, 
                'font->getName().value_or("")')
        s.gsub!(/\(\s*font->getName\(\)\s*\?\s*font->getName\(\)->toStr\(\)\s*:\s*""\s*\)/, 
                'font->getName().value_or("")')
        
        # Fix font->locateFont() - returns std::optional<GfxFontLoc> now
        s.gsub!(/if\(auto\s*\*\s*font_loc\s*=\s*font->locateFont\(([^)]*)\)\)/, 
                'auto font_loc = font->locateFont(\1);\n    if(font_loc.has_value())')
        s.gsub!(/GfxFontLoc\s*\*\s*localfontloc\s*=\s*font->locateFont\(([^)]*)\);/, 
                'auto localfontloc = font->locateFont(\1);')
        
        # Fix GfxFontLoc access - switch from pointer to optional
        s.gsub!(/font_loc\s*->\s*locType/, 
                'font_loc.value().locType')
        s.gsub!(/localfontloc\s*->\s*path\s*->\s*toStr\(\)/, 
                'localfontloc.value().path')
        s.gsub!(/font_loc\s*->\s*path\s*->\s*toStr\(\)/, 
                'font_loc.value().path')
        
        # Fix localfontloc conditional patterns
        s.gsub!(/if\(localfontloc\s*&&\s*localfontloc\s*->\s*locType/, 
                'if(localfontloc.has_value() && localfontloc.value().locType')
        s.gsub!(/if\(localfontloc\)/, 
                'if(localfontloc.has_value())')
        s.gsub!(/localfontloc\s*->\s*locType/, 
                'localfontloc.value().locType')
        
        # Fix getCodeToGIDMap usage with unique_ptr
        s.gsub!(/code2GID\s*=\s*font_8bit->getCodeToGIDMap\(fftt\);/, 
                'code2GID = font_8bit->getCodeToGIDMap(fftt.get());')
        s.gsub!(/code2GID\s*=\s*_font->getCodeToGIDMap\(fftt,\s*&code2GID_len\);/, 
                'code2GID = _font->getCodeToGIDMap(fftt.get(), &code2GID_len);')
      end
      
      # Apply other necessary patches from v2
      inreplace "src/HTMLRenderer/state.cc" do |s|
        s.gsub!(/install_font\(state->getFont\(\)\)/, 
                'install_font(state->getFont().get())')
      end
      
      inreplace "src/HTMLRenderer/text.cc" do |s|
        s.gsub!(/\(\(GfxCIDFont\s*\*\)font\)->/, 
                '((GfxCIDFont *)font.get())->')
        s.gsub!(/\(\(Gfx8BitFont\s*\*\)font\)->/, 
                '((Gfx8BitFont *)font.get())->')
      end
      
      inreplace "src/HTMLRenderer/form.cc" do |s|
        s.gsub!(/FormPageWidgets\s*\*\s*widgets\s*=/, 
                'auto widgets =')
      end
      
      inreplace "src/HTMLRenderer/link.cc" do |s|
        s.gsub!(/dest\s*=\s*std::unique_ptr<LinkDest>\(\s*_->copy\(\)\s*\);/, 
                'dest = std::unique_ptr<LinkDest>( _->clone() );')
      end
      
      inreplace "src/HTMLRenderer/outline.cc" do |s|
        s.gsub!(/item->close\(\);/, '// item->close(); // removed in newer Poppler')
      end
      
      inreplace "src/pdf2htmlEX.cc" do |s|
        s.gsub!(/doc\s*=\s*PDFDocFactory\(\)\.createPDFDoc\(fileName,\s*ownerPW,\s*userPW\);/, 
                'doc = PDFDocFactory().createPDFDoc(fileName, ownerPW ? std::optional<GooString>(*ownerPW) : std::nullopt, userPW ? std::optional<GooString>(*userPW) : std::nullopt);')
      end
    end



    # Change to the pdf2htmlEX subdirectory where CMakeLists.txt is located
    cd "pdf2htmlEX" do
      # Remove hard-coded references to vendor build directories so that the
      # project relies solely on the *_INCLUDE_DIR / *_LIBRARIES variables we
      # inject via CMake cache entries.
      inreplace "CMakeLists.txt" do |s|
        # Strip entire include_directories() blocks that point to ../poppler*
        s.gsub!(/include_directories\([^\)]*\.\.\/poppler[\s\S]*?\)/m, "")

        # Replace the POPPLER_LIBRARIES definition with one that uses the
        # externally supplied variables only.
        s.gsub!(/set\(POPPLER_LIBRARIES[\s\S]*?\)/m,
                "set(POPPLER_LIBRARIES ${POPPLER_LIBRARIES} ${POPPLER_GLIB_LIBRARIES})")

        # Remove include dirs pointing to ../fontforge*
        s.gsub!(/include_directories\([^\)]*\.\.\/fontforge[\s\S]*?\)/m, "")

        # Simplify FONTFORGE_LIBRARIES definition
        s.gsub!(/set\(FONTFORGE_LIBRARIES[\s\S]*?\)/m,
                "set(FONTFORGE_LIBRARIES ${FONTFORGE_LIBRARIES})")
        s.gsub!(/src\/util\/ffw\.c\s*/, "")
      end

      # Ensure the staged headers are discoverable.
      File.open("CMakeLists.txt", "a") do |f|
        f.puts "include_directories(${POPPLER_INCLUDE_DIR})"
        f.puts "include_directories(${FONTFORGE_INCLUDE_DIR})"
      end
      mkdir "build" do
        args = %W[
          -DCMAKE_BUILD_TYPE=Release
          -DCMAKE_INSTALL_PREFIX=#{prefix}
          -DCMAKE_OSX_ARCHITECTURES=#{archs}
          -DCMAKE_PREFIX_PATH=#{staging_prefix}
          -DCMAKE_POLICY_VERSION_MINIMUM=3.5
          -DENABLE_SVG=ON
          -DPOPPLER_INCLUDE_DIR=#{staging_prefix}/include/poppler
          -DFONTFORGE_INCLUDE_DIR=#{staging_prefix}/include/fontforge
          -DPOPPLER_LIBRARIES=#{staging_prefix}/lib/libpoppler.a
          -DPOPPLER_GLIB_LIBRARIES=#{staging_prefix}/lib/libpoppler-glib.a
          -DFONTFORGE_LIBRARIES=#{staging_prefix}/lib/libfontforge.a
          -DCMAKE_CXX_STANDARD=17
          -DCMAKE_C_FLAGS=-I#{staging_prefix}/include\ \-I#{Formula["glib"].opt_include}/glib-2.0\ \-I#{Formula["glib"].opt_lib}/glib-2.0/include
          -DCMAKE_CXX_FLAGS=-I#{staging_prefix}/include\ \-I#{Formula["glib"].opt_include}/glib-2.0\ \-I#{Formula["glib"].opt_lib}/glib-2.0/include
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

__END__
--- a/pdf2htmlEX/CMakeLists.txt
+++ b/pdf2htmlEX/CMakeLists.txt
@@ -38,20 +38,8 @@
 # by poppler
 find_package(Poppler REQUIRED)
-include_directories(
-    ${CMAKE_SOURCE_DIR}/../poppler/build
-    ${CMAKE_SOURCE_DIR}/../poppler
-    ${CMAKE_SOURCE_DIR}/../poppler/glib
-    ${CMAKE_SOURCE_DIR}/../poppler/goo
-    ${CMAKE_SOURCE_DIR}/../poppler/fofi
-    ${CMAKE_SOURCE_DIR}/../poppler/splash
-)
-link_directories(
-    ${CMAKE_SOURCE_DIR}/../poppler/build
-    ${CMAKE_SOURCE_DIR}/../poppler/build/glib
-)
-set(POPPLER_LIBS
-    ${CMAKE_SOURCE_DIR}/../poppler/build/glib/libpoppler-glib.a
-    ${CMAKE_SOURCE_DIR}/../poppler/build/libpoppler.a
-)
+include_directories(${POPPLER_INCLUDE_DIR})
+set(POPPLER_LIBS ${POPPLER_LIBRARIES} ${POPPLER_GLIB_LIBRARIES})
 
 # Find fontforge
 # we need to use our own build of fontforge
-include_directories(
-    ${CMAKE_SOURCE_DIR}/../fontforge/build/inc
-    ${CMAKE_SOURCE_DIR}/../fontforge
-)
-link_directories(${CMAKE_SOURCE_DIR}/../fontforge/build/lib)
-set(FONTFORGE_LIBS
-    ${CMAKE_SOURCE_DIR}/../fontforge/build/lib/libfontforge.a
-)
+include_directories(${FONTFORGE_INCLUDE_DIR})
+set(FONTFORGE_LIBS ${FONTFORGE_LIBRARIES})
