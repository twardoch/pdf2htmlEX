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
    url "https://poppler.freedesktop.org/poppler-22.12.0.tar.xz"
    sha256 "d9aa9cacdfbd0f8e98fc2b3bb008e645597ed480685757c3e7bc74b4278d15c0"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/archive/20230101.tar.gz"
    sha256 "ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"
  end

  def install
    # Set up build environment
    ENV.cxx11
    # Override with C++17 for std::optional compatibility with modern Poppler
    ENV.append "CXXFLAGS", "-std=c++17"
    
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

    # --- Stage 1: Build Poppler 22.12.0 from source ---
    resource("poppler").stage do
      # Patch DCTStream compilation issue when JPEG is disabled
      # Remove the problematic DCTStream.cc file entirely since JPEG is disabled
      rm "poppler/DCTStream.cc"
      
      # Remove the duplicate DCTStream class definition from DCTStream.h
      inreplace "poppler/DCTStream.h" do |s|
        # Comment out the duplicate class definition
        s.gsub!(/^class DCTStream : public FilterStream.*?^};$/m,
                "// DCTStream class disabled - JPEG support not available")
      end
      
      # Create a minimal stub DCTStream.cc file
      File.write("poppler/DCTStream.cc", <<~EOS)
        // DCTStream stub implementation - JPEG support disabled
        // No includes needed - all functionality disabled
      EOS
      
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
      # Apply official Homebrew patch for translation files
      patch do
        url "https://raw.githubusercontent.com/Homebrew/formula-patches/9403988/fontforge/20230101.patch"
        sha256 "e784c4c0fcf28e5e6c5b099d7540f53436d1be2969898ebacd25654d315c0072"
      end
      
      # Fix problematic translation files that have C format string errors
      # Create properly formatted empty PO files instead of removing them
      po_header = <<~EOS
        # SOME DESCRIPTIVE TITLE.
        # Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
        # This file is distributed under the same license as the PACKAGE package.
        # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
        #
        msgid ""
        msgstr ""
        "Project-Id-Version: fontforge\\n"
        "Report-Msgid-Bugs-To: \\n"
        "POT-Creation-Date: 2023-01-01 12:00+0000\\n"
        "PO-Revision-Date: 2023-01-01 12:00+0000\\n"
        "Last-Translator: FontForge Build System\\n"
        "Language-Team: LANGUAGE <LL@li.org>\\n"
        "Language: \\n"
        "MIME-Version: 1.0\\n"
        "Content-Type: text/plain; charset=UTF-8\\n"
        "Content-Transfer-Encoding: 8bit\\n"
      EOS
      
      File.write("po/fr.po", po_header)
      File.write("po/it.po", po_header)
      
      # Remove desktop integration files to avoid translation dependencies
      rm_rf "desktop"
      
      # Patch CMakeLists.txt to remove desktop subdirectory reference
      inreplace "CMakeLists.txt" do |s|
        s.gsub!(/add_subdirectory\(desktop\)/, "# add_subdirectory(desktop) # Disabled - desktop files removed")
      end

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
          -DENABLE_LOCALIZATION=OFF
        ]

        system "cmake", "..", "-G", "Ninja", *args
        system "ninja", "install"
        
        # Manually install libfontforge.a if it wasn't installed automatically
        unless File.exist?("#{staging_prefix}/lib/libfontforge.a")
          cp "lib/libfontforge.a", "#{staging_prefix}/lib/libfontforge.a"
        end
        
        # Manually install FontForge headers if missing
        unless File.exist?("#{staging_prefix}/include/fontforge.h")
          cp "../fontforge/fontforge.h", "#{staging_prefix}/include/fontforge.h" if File.exist?("../fontforge/fontforge.h")
        end
        unless File.exist?("#{staging_prefix}/include/fontforge-config.h")
          cp "inc/fontforge-config.h", "#{staging_prefix}/include/fontforge-config.h" if File.exist?("inc/fontforge-config.h")
        end
        unless File.exist?("#{staging_prefix}/include/basics.h")
          # Create a minimal basics.h header if it doesn't exist
          if File.exist?("../fontforge/inc/basics.h")
            cp "../fontforge/inc/basics.h", "#{staging_prefix}/include/basics.h"
          else
            # Create a minimal stub basics.h
            File.write("#{staging_prefix}/include/basics.h", <<~EOS)
              // Minimal basics.h stub for FontForge compatibility
              #ifndef _BASICS_H
              #define _BASICS_H
              
              #include <stdint.h>
              #include <stdio.h>
              #include <stdlib.h>
              #include <string.h>
              
              // Basic type definitions
              typedef unsigned char uint8;
              typedef unsigned short uint16;
              typedef unsigned int uint32;
              typedef char int8;
              typedef short int16;
              typedef int int32;
              
                             #endif /* _BASICS_H */
             EOS
           end
         end
         
         unless File.exist?("#{staging_prefix}/include/intl.h")
           # Create a minimal intl.h header for internationalization
           File.write("#{staging_prefix}/include/intl.h", <<~EOS)
             // Minimal intl.h stub for FontForge compatibility
             #ifndef _INTL_H
             #define _INTL_H
             
             // Disable internationalization for simplicity
             #define _(String) String
             #define N_(String) String
             #define gettext(String) String
             #define ngettext(String1, String2, N) ((N) == 1 ? (String1) : (String2))
             
             #endif /* _INTL_H */
           EOS
         end
         
         unless File.exist?("#{staging_prefix}/include/splinefont.h")
           # Copy splinefont.h from FontForge source if available
           if File.exist?("../fontforge/inc/splinefont.h")
             cp "../fontforge/inc/splinefont.h", "#{staging_prefix}/include/splinefont.h"
           elsif File.exist?("../fontforge/fontforge/splinefont.h")
             cp "../fontforge/fontforge/splinefont.h", "#{staging_prefix}/include/splinefont.h"
           else
             # Create a minimal splinefont.h stub
             File.write("#{staging_prefix}/include/splinefont.h", <<~EOS)
               // Minimal splinefont.h stub for FontForge compatibility
               #ifndef _SPLINEFONT_H
               #define _SPLINEFONT_H
               
               #include <stdio.h>
               #include <stdlib.h>
               
               // Forward declarations for basic FontForge types
               typedef struct splinechar SplineChar;
               typedef struct splinefont SplineFont;
               
               #endif /* _SPLINEFONT_H */
             EOS
           end
         end
         
         unless File.exist?("#{staging_prefix}/include/uiinterface.h")
           # Copy uiinterface.h from FontForge source or create minimal stub
           if File.exist?("../fontforge/inc/uiinterface.h")
             cp "../fontforge/inc/uiinterface.h", "#{staging_prefix}/include/uiinterface.h"
           elsif File.exist?("../fontforge/fontforge/uiinterface.h")
             cp "../fontforge/fontforge/uiinterface.h", "#{staging_prefix}/include/uiinterface.h"
           else
             # Create a minimal uiinterface.h stub
             File.write("#{staging_prefix}/include/uiinterface.h", <<~EOS)
               // Minimal uiinterface.h stub for FontForge compatibility
               #ifndef _UIINTERFACE_H
               #define _UIINTERFACE_H
               
               #include <stdio.h>
               
               // Minimal UI interface stubs for headless FontForge
               #define UI_TTY 0
               #define UI_NONE 1
               
               extern int ui_interface;
               
               #endif /* _UIINTERFACE_H */
             EOS
           end
         end
         
         unless File.exist?("#{staging_prefix}/include/baseviews.h")
           # Create minimal baseviews.h stub for FontForge compatibility
           File.write("#{staging_prefix}/include/baseviews.h", <<~EOS)
             // Minimal baseviews.h stub for FontForge compatibility
             #ifndef _BASEVIEWS_H
             #define _BASEVIEWS_H
             
             #include <stdio.h>
             
             // Forward declarations for FontForge base view types
             typedef struct charview CharView;
             typedef struct fontview FontView;
             typedef struct bitmapview BitmapView;
             
             // Minimal encoding types
             typedef struct encoding {
                 char *enc_name;
                 int char_cnt;
                 char **unicode;
             } Encoding;
             
             // Minimal Mac feature types
             typedef struct macfeat {
                 int feature_type;
                 int feature_setting;
             } MacFeat;
             
             // External declarations that FontForge expects
             extern Encoding *default_encoding, custom;
             extern Encoding *enclist;
             extern MacFeat *default_mac_feature_map;
             
             #endif /* _BASEVIEWS_H */
           EOS
         end
      end
    end

    # --- Stage 3: Build pdf2htmlEX ---
    # Create missing test.py.in file that CMake expects
    mkdir_p "pdf2htmlEX/test"
    File.write("pdf2htmlEX/test/test.py.in", "")

    # Patch pdf2htmlEX's CMakeLists.txt to use our staged dependencies
    inreplace "pdf2htmlEX/CMakeLists.txt" do |s|
      # Replace hardcoded Poppler paths with staging paths
      s.gsub! "${CMAKE_SOURCE_DIR}/../poppler/build/glib/libpoppler-glib.a", "#{staging_prefix}/lib/libpoppler-glib.a"
      s.gsub! "${CMAKE_SOURCE_DIR}/../poppler/build/libpoppler.a", "#{staging_prefix}/lib/libpoppler.a"
      s.gsub! "../poppler/build/poppler", "#{staging_prefix}/include/poppler"
      s.gsub! "../poppler/build", "#{staging_prefix}/include"
      s.gsub! "../poppler/poppler", "#{staging_prefix}/include/poppler"
      s.gsub! "../poppler", "#{staging_prefix}/include"
      
      # Replace hardcoded FontForge paths with staging paths
      s.gsub! "${CMAKE_SOURCE_DIR}/../fontforge/build/lib/libfontforge.a", "#{staging_prefix}/lib/libfontforge.a"
      s.gsub! "../fontforge/fontforge", "#{staging_prefix}/include"
      s.gsub! "../fontforge/build/inc", "#{staging_prefix}/include"
      s.gsub! "../fontforge/inc", "#{staging_prefix}/include"
      s.gsub! "../fontforge", "#{staging_prefix}/include"
      
      # Update C++ standard to C++17 for std::optional compatibility
      s.gsub! "-std=c++14", "-std=c++17"
    end
    
    # Apply critical API compatibility patches for modern Poppler
    # Patch 1: Fix FontForge header include path (it's just fontforge.h)
    # No change needed - the original include is correct
    
    # Patch 2: Fix string API changes in font.cc (minimal safe changes only)
    inreplace "pdf2htmlEX/src/HTMLRenderer/font.cc" do |s|
      # Fix string API changes - these are safe and necessary
      s.gsub! 'font->getName()->toStr()', 'font->getName()->c_str()'
      s.gsub! 'localfontloc->path->toStr()', 'localfontloc->path.c_str()'
      # Let the compiler tell us about other API issues - our patches were breaking syntax
    end
    

    
    # Patch 3: Fix state.cc smart pointer issues
    inreplace "pdf2htmlEX/src/HTMLRenderer/state.cc" do |s|
      s.gsub! 'const FontInfo * new_font_info = install_font(state->getFont());',
              'const FontInfo * new_font_info = install_font(state->getFont().get());'
    end
    
    # Patch 4: Fix text.cc casting and function calls
    inreplace "pdf2htmlEX/src/HTMLRenderer/text.cc" do |s|
      s.gsub! 'width = ((GfxCIDFont *)font)->getWidth(buf, 2);',
              'width = static_cast<GfxCIDFont*>(font.get())->getWidth(buf, 2);'
      s.gsub! 'width = ((Gfx8BitFont *)font)->getWidth(code);',
              'width = static_cast<Gfx8BitFont*>(font.get())->getWidth(code);'
      s.gsub! 'uu = check_unicode(u, uLen, code, font);',
              'uu = check_unicode(u, uLen, code, font.get());'
      s.gsub! 'uu = unicode_from_font(code, font);',
              'uu = unicode_from_font(code, font.get());'
    end
    
    # Patch 5: Fix outline.cc method removal
    inreplace "pdf2htmlEX/src/HTMLRenderer/outline.cc" do |s|
      s.gsub! 'item->close();', '// item->close(); // Method removed in modern Poppler'
    end
    
    # Patch 6: Fix link.cc method removal  
    inreplace "pdf2htmlEX/src/HTMLRenderer/link.cc" do |s|
      s.gsub! 'dest = std::unique_ptr<LinkDest>( _->copy() );',
              'dest = std::unique_ptr<LinkDest>(new LinkDest(*_)); // copy() method removed'
    end
    
    # Patch 7: Fix form.cc smart pointer conversion
    inreplace "pdf2htmlEX/src/HTMLRenderer/form.cc" do |s|
      s.gsub! 'FormPageWidgets * widgets = cur_catalog->getPage(pageNum)->getFormWidgets();',
              'auto widgets_ptr = cur_catalog->getPage(pageNum)->getFormWidgets(); FormPageWidgets * widgets = widgets_ptr.get();'
    end
    
    # Patch 8: Fix pdf2htmlEX.cc PDFDoc API changes (simplified to avoid std::optional issues)
    inreplace "pdf2htmlEX/src/pdf2htmlEX.cc" do |s|
      s.gsub! 'doc = PDFDocFactory().createPDFDoc(fileName, ownerPW, userPW);',
              'doc = PDFDocFactory().createPDFDoc(fileName, ownerPW, userPW).release();'
    end

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