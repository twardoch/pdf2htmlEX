# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v0.18.8.rc1.tar.gz"
  version "0.18.8.rc1"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  revision 1 # Increment if resources or build logic changes without a version bump

  # Universal build supported
  # bottle :unneeded # We will build from source, bottles can be added later

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "openjdk" => :build # For YUI Compressor and Closure Compiler

  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "jpeg-turbo" # Homebrew standard for jpeg
  depends_on "libpng"
  depends_on "libtiff" # FontForge can use this
  depends_on "libxml2" # FontForge can use this
  depends_on "pango" # FontForge
  depends_on "harfbuzz" # FontForge

  resource "poppler" do
    url "https://poppler.freedesktop.org/poppler-24.01.0.tar.xz"
    sha256 "c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/archive/refs/tags/20230101.tar.gz"
    sha256 "ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"
  end

  # Helper methods for build process
  def build_with_progress(component, &block)
    ohai "Building #{component}..."
    start_time = Time.now
    
    begin
      yield
      elapsed = Time.now - start_time
      ohai "✓ #{component} built successfully (#{elapsed.round(1)}s)"
    rescue => e
      onoe "✗ Failed to build #{component}: #{e.message}"
      raise "#{component} build failed"
    end
  end

  def validate_build_stage(component, path)
    unless File.exist?(path)
      onoe "Build validation failed: #{component} artifact not found at #{path}"
      raise "#{component} build validation failed"
    end
    ohai "✓ #{component} build validated"
  end

  def with_build_environment(&block)
    # Save original environment
    orig_cflags = ENV["CFLAGS"]
    orig_cxxflags = ENV["CXXFLAGS"]
    orig_ldflags = ENV["LDFLAGS"]
    
    # Set optimized build flags
    ENV.append "CFLAGS", "-O2 -fstack-protector-strong"
    ENV.append "CXXFLAGS", "-O2 -fstack-protector-strong"
    ENV.append "LDFLAGS", "-Wl,-rpath,@loader_path/../lib"
    
    yield
  ensure
    # Restore original environment
    ENV["CFLAGS"] = orig_cflags
    ENV["CXXFLAGS"] = orig_cxxflags
    ENV["LDFLAGS"] = orig_ldflags
  end

  def install
    ohai "pdf2htmlEX Build Process Starting"
    
    # Staging prefix for our custom-built static libraries
    ENV.cxx11

    # Ensure Homebrew's libraries are found by pkg-config and cmake
    # This setup should be sufficient for most cases.
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["freetype"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["fontconfig"].opt_lib/"pkgconfig"
    # Add other specific opt_lib/pkgconfig paths if needed, but Homebrew's superenv usually handles this.

    # Remove march flags that can cause issues with older compilers or specific C++ features in dependencies
    ENV.remove "HOMEBREW_CFLAGS", / ?-march=\S*/
    ENV.remove "HOMEBREW_CXXFLAGS", / ?-march=\S*/

    # Determine the architectures to build for.
    # Homebrew < 4.5 exposed Hardware::CPU.universal_archs but this method
    # was removed in 4.5 (see https://brew.sh/2025/04/29/homebrew-4.5.0/).
    # Use it when available for backwards-compatibility, otherwise fall back to
    # a manual selection that still produces a universal binary.
    archs = if Hardware::CPU.respond_to?(:universal_archs)
      Hardware::CPU.universal_archs.join(";")
    else
      if Hardware::CPU.arm?
        # Native Apple Silicon build, include Intel slice for universal binary
        "arm64;x86_64"
      else
        # Building the extra arm64 slice on Intel hosts requires Xcode 12+
        # *and* a recent macOS SDK.  Older toolchains will error out during
        # the CMake compiler checks (see issue observed by users).
        # Default to a safe single-arch build unless the user explicitly opts
        # into a universal build via the PDF2HTMLEX_FORCE_UNIVERSAL env var.
        if ENV["PDF2HTMLEX_FORCE_UNIVERSAL"]
          "x86_64;arm64"
        else
          "x86_64"
        end
      end
    end
    
    ohai "Building for architectures: #{archs.gsub(";", ", ")}"

    staging_prefix = buildpath/"staging"
    
    # Create build log
    build_log = buildpath/"build.log"

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
    ENV["CMAKE_PREFIX_PATH"] = cmake_prefix_paths

    with_build_environment do
      # Stage 1: Build Poppler
      build_with_progress("Poppler 24.01.0") do
        resource("poppler").stage do
          mkdir "build" do
        system "cmake", "..",
               "-G", "Ninja",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
               "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
               "-DCMAKE_PREFIX_PATH=#{ENV["CMAKE_PREFIX_PATH"]}",
               "-DCMAKE_FIND_FRAMEWORK=NEVER",
               "-DCMAKE_FIND_APPBUNDLE=NEVER",
               "-DENABLE_UNSTABLE_API_ABI_HEADERS=OFF",
               "-DBUILD_GTK_TESTS=OFF",
               "-DBUILD_QT5_TESTS=OFF",
               "-DBUILD_QT6_TESTS=OFF",
               "-DBUILD_CPP_TESTS=OFF",
               "-DBUILD_MANUAL_TESTS=OFF",
               "-DENABLE_BOOST=OFF",
               "-DENABLE_SPLASH=ON",
               "-DENABLE_UTILS=OFF",
               "-DENABLE_CPP=OFF",
               "-DENABLE_GLIB=ON",
               "-DENABLE_GOBJECT_INTROSPECTION=OFF",
               "-DENABLE_GTK_DOC=OFF",
               "-DENABLE_QT5=OFF",
               "-DENABLE_QT6=OFF",
               "-DENABLE_LIBOPENJPEG=none",
               "-DENABLE_DCTDECODER=libjpeg",
               "-DENABLE_CMS=none",
               "-DENABLE_LCMS=OFF",
               "-DENABLE_LIBCURL=OFF",
               "-DENABLE_LIBTIFF=OFF",
               "-DWITH_TIFF=OFF",
               "-DWITH_NSS3=OFF",
               "-DENABLE_NSS3=OFF",
               "-DENABLE_GPGME=OFF",
               "-DENABLE_ZLIB=ON",
               "-DENABLE_ZLIB_UNCOMPRESS=OFF",
               "-DUSE_FLOAT=OFF",
               "-DBUILD_SHARED_LIBS=OFF",
               "-DRUN_GPERF_IF_PRESENT=OFF",
               "-DEXTRA_WARN=OFF",
               "-DWITH_JPEG=ON",
               "-DWITH_PNG=ON",
               "-DWITH_Cairo=ON"
            system "ninja", "install"
          end
        end
      end
      validate_build_stage("Poppler", staging_prefix/"lib/libpoppler.a")

      # Stage 2: Build FontForge
      build_with_progress("FontForge 20230101") do
        resource("fontforge").stage do
          mkdir "build" do
            # FontForge needs to find the Poppler we just built in staging_prefix
            fontforge_cmake_prefix_path = "#{staging_prefix};#{ENV["CMAKE_PREFIX_PATH"]}"
            
            # Disable problematic gettext/msgfmt build completely by pointing to /bin/true
            ENV["MSGFMT"] = "/bin/true"
            ENV["XGETTEXT"] = "/bin/true"
            ENV["MSGMERGE"] = "/bin/true"
            ENV.delete("LANG")
            ENV.delete("LC_ALL")
            ENV.delete("LC_MESSAGES")
            ENV["LC_ALL"] = "C"
            
            # Create patch to disable message compilation
            mkdir_p "patches"
            (buildpath/"patches/disable-gettext.patch").write <<~EOS
              diff --git a/po/CMakeLists.txt b/po/CMakeLists.txt
              index d5bcb789d..b695a5a09 100644
              --- a/po/CMakeLists.txt
              +++ b/po/CMakeLists.txt
              @@ -1,3 +1,4 @@
              +return()
               # Distributed under the original FontForge BSD 3-clause license
               
               if (GETTEXT_FOUND)
            EOS

            # Apply the patch
            system "patch", "-p1", "-i", buildpath/"patches/disable-gettext.patch"
            
            system "cmake", "..",
               "-G", "Ninja",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
               "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
               "-DCMAKE_PREFIX_PATH=#{fontforge_cmake_prefix_path}",
               "-DCMAKE_FIND_FRAMEWORK=NEVER",
               "-DCMAKE_FIND_APPBUNDLE=NEVER",
               "-DBUILD_SHARED_LIBS=OFF",
               "-DENABLE_GUI=OFF",
               "-DENABLE_X11=OFF",
               "-DENABLE_NATIVE_SCRIPTING=ON",
               "-DENABLE_PYTHON_SCRIPTING=OFF",
               "-DENABLE_PYTHON_EXTENSION=OFF",
               "-DENABLE_LIBSPIRO=OFF",
               "-DENABLE_LIBUNINAMESLIST=OFF",
               "-DENABLE_LIBGIF=OFF",
               "-DENABLE_LIBJPEG=ON",
               "-DENABLE_LIBPNG=ON",
               "-DENABLE_LIBREADLINE=OFF",
               "-DENABLE_LIBTIFF=ON",
               "-DENABLE_WOFF2=OFF",
               "-DENABLE_DOCS=OFF",
               "-DENABLE_CODE_COVERAGE=OFF",
               "-DENABLE_DEBUG_RAW_POINTS=OFF",
               "-DENABLE_FONTFORGE_EXTRAS=OFF",
               "-DENABLE_MAINTAINER_TOOLS=OFF",
               "-DENABLE_TILE_PATH=OFF",
               "-DENABLE_WRITE_PFM=OFF",
               "-DENABLE_SANITIZER=none",
               "-DENABLE_FREETYPE_DEBUGGER=",
               "-DSPHINX_USE_VENV=OFF",
               "-DENABLE_GETTEXT=OFF",
               "-DBUILD_GETTEXT=OFF",
               "-DENABLE_NLS=OFF",
               "-DENABLE_MULTILAYER=OFF",
               "-DREAL_TYPE=double",
               "-DTHEME=tango"
            system "ninja", "install"
          end
        end
      end
      validate_build_stage("FontForge", staging_prefix/"lib/libfontforge.a")

      # Configure pdf2htmlEX build
      ENV.prepend_path "PKG_CONFIG_PATH", "#{staging_prefix}/lib/pkgconfig"
      # CMAKE_PREFIX_PATH for pdf2htmlEX needs our staging_prefix and the general Homebrew paths
      pdf2htmlex_cmake_prefix_path = "#{staging_prefix};#{ENV["CMAKE_PREFIX_PATH"]}"

      ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix

      # Stage 3: Build pdf2htmlEX
      build_with_progress("pdf2htmlEX #{version}") do
        # pdf2htmlEX source is in the root of the buildpath (after url.stage)
        # It has a pdf2htmlEX subdirectory which contains the main CMakeLists.txt
        # The main tarball extracts to pdf2htmlEX-0.18.8.rc1, so cd into that.
        cd buildpath/name do # 'name' is a special var in Homebrew for the extracted dir name
          cd "pdf2htmlEX" do # The actual sources are in a subdirectory
            mkdir "build" do
              system "cmake", "..",
                     "-G", "Ninja",
                     "-DCMAKE_BUILD_TYPE=Release",
                     "-DCMAKE_INSTALL_PREFIX=#{prefix}",
                     "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
                     "-DCMAKE_PREFIX_PATH=#{pdf2htmlex_cmake_prefix_path}",
                     "-DCMAKE_FIND_FRAMEWORK=NEVER",
                     "-DCMAKE_FIND_APPBUNDLE=NEVER"
              system "ninja", "install"
            end
          end
        end
      end
      validate_build_stage("pdf2htmlEX", bin/"pdf2htmlEX")
    end

    # Final validation
    ohai "Running post-build validation..."
    system bin/"pdf2htmlEX", "--version"
    ohai "✓ Build completed successfully!"
  rescue => e
    onoe "Build failed: #{e.message}"
    onoe "Check build log at: #{build_log}" if build_log.exist?
    raise
  end

  test do
    ohai "Running pdf2htmlEX tests..."
    
    # Test 1: Basic functionality with simple PDF
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

    # Test basic conversion
    system bin/"pdf2htmlEX", testpath/"test.pdf"
    assert_predicate testpath/"test.html", :exist?, "test.html should be created"
    assert_match "pdf2htmlEX test", (testpath/"test.html").read, "Output HTML should contain text from PDF"
    assert_match "pdf2htmlEX", (testpath/"test.html").read, "Output HTML should mention pdf2htmlEX"
    
    # Test 2: Version output
    version_output = shell_output("#{bin}/pdf2htmlEX --version")
    assert_match version.to_s, version_output, "Version should match formula version"
    
    # Test 3: Help output
    help_output = shell_output("#{bin}/pdf2htmlEX --help", 1)
    assert_match "pdf2htmlEX", help_output, "Help should mention pdf2htmlEX"
    assert_match "Usage:", help_output, "Help should show usage"
    
    # Test 4: Various command-line options
    system bin/"pdf2htmlEX", "--zoom", "1.5", "--embed-css", "0", testpath/"test.pdf", testpath/"test_zoom.html"
    assert_predicate testpath/"test_zoom.html", :exist?, "Custom output file should be created"
    
    # Test 5: Split pages option
    system bin/"pdf2htmlEX", "--split-pages", "1", testpath/"test.pdf", testpath/"test_split.html"
    assert_predicate testpath/"test_split", :directory?, "Split pages directory should be created"
    
    # Test 6: Process outline option
    system bin/"pdf2htmlEX", "--process-outline", "1", testpath/"test.pdf", testpath/"test_outline.html"
    assert_predicate testpath/"test_outline.html", :exist?, "Outline processing should work"
    
    # Test 7: Unicode handling
    (testpath/"unicode_test.pdf").write <<~EOS
      %PDF-1.4
      1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
      2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
      3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj
      4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
      5 0 obj<</Length 150>>stream
      BT /F1 24 Tf 100 700 Td (Hello ) Tj /F1 24 Tf (世界) Tj /F1 24 Tf ( €£¥) Tj ET
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
      407
      %%EOF
    EOS
    
    system bin/"pdf2htmlEX", testpath/"unicode_test.pdf"
    assert_predicate testpath/"unicode_test.html", :exist?, "Unicode PDF should be converted"
    
    # Test 8: Architecture validation
    ohai "Validating binary architecture..."
    binary_info = shell_output("file #{bin}/pdf2htmlEX")
    lipo_info = shell_output("lipo -info #{bin}/pdf2htmlEX 2>/dev/null")
    
    if Hardware::CPU.arm?
      assert_match "arm64", binary_info, "Binary should contain arm64 architecture"
      # Check if universal binary
      if binary_info.include?("x86_64")
        assert_match "x86_64 arm64", lipo_info, "Universal binary should contain both architectures"
        ohai "✓ Universal binary validated (arm64 + x86_64)"
      else
        ohai "✓ Native arm64 binary validated"
      end
    else
      assert_match "x86_64", binary_info, "Binary should contain x86_64 architecture"
      # Check if universal binary  
      if binary_info.include?("arm64")
        assert_match "x86_64 arm64", lipo_info, "Universal binary should contain both architectures"
        ohai "✓ Universal binary validated (x86_64 + arm64)"
      else
        ohai "✓ Native x86_64 binary validated"
      end
    end
    
    # Test 9: Test both architectures if universal binary
    if lipo_info.include?("x86_64") && lipo_info.include?("arm64")
      ohai "Testing x86_64 architecture..."
      x86_version = shell_output("arch -x86_64 #{bin}/pdf2htmlEX --version 2>&1")
      assert_match version.to_s, x86_version, "x86_64 binary should run correctly"
      
      ohai "Testing arm64 architecture..."
      arm_version = shell_output("arch -arm64 #{bin}/pdf2htmlEX --version 2>&1")
      assert_match version.to_s, arm_version, "arm64 binary should run correctly"
    end
    
    ohai "✓ All tests passed!"
  end
end
