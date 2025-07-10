# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  version "0.18.8.rc1"

  # V2 Strategy: Add jpeg-turbo as a resource to fix Poppler build
  resource "jpeg-turbo" do
    url "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.2.tar.gz"
    sha256 "b236933836fab254353351b536a324f77260135f638542914e2c438a8b84e2bf"
  end

  resource "poppler" do
    url "https://poppler.freedesktop.org/poppler-24.01.0.tar.xz"
    sha256 "c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/archive/20230101.tar.gz"
    sha256 "ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "openjdk" => :build

  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "libxml2"
  depends_on "pango"
  depends_on "harfbuzz"
  depends_on "little-cms2"
  depends_on "openjpeg"

  def install
    ENV.cxx11
    # Staging prefix for all our compiled static libraries
    staging_prefix = buildpath/"staging"
    # Universal binary architecture
    archs = "x86_64;arm64"

    # Set up environment for build
    ENV.prepend_path "PKG_CONFIG_PATH", "#{staging_prefix}/lib/pkgconfig"
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix

    # Stage 1: Build jpeg-turbo (static)
    ohai "Building static jpeg-turbo"
    resource("jpeg-turbo").stage do
      system "cmake", "-S", ".", "-B", "build",
             "-DCMAKE_INSTALL_PREFIX=#{staging_prefix}",
             "-DCMAKE_OSX_ARCHITECTURES=#{archs}",
             "-DENABLE_SHARED=OFF",
             "-DENABLE_STATIC=ON",
             *std_cmake_args
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    # Stage 2: Build Poppler (static)
    ohai "Building static Poppler"
    resource("poppler").stage do
      # Create a placeholder to prevent CMake test data error
      (buildpath/"test").mkdir
      
      poppler_args = %W[
        -DCMAKE_INSTALL_PREFIX=#{staging_prefix}
        -DCMAKE_OSX_ARCHITECTURES=#{archs}
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
        -DENABLE_GLIB=ON
        -DENABLE_UTILS=OFF
        -DENABLE_CPP=OFF
        -DENABLE_QT5=OFF
        -DENABLE_QT6=OFF
        -DENABLE_LIBOPENJPEG=openjpeg2
        -DENABLE_CMS=lcms2
        -DWITH_JPEG=ON
        -DENABLE_DCTDECODER=libjpeg
        -DENABLE_LIBJPEG=ON
      ]
      
      system "cmake", "-S", ".", "-B", "build", *poppler_args, *std_cmake_args
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    # Stage 3: Build FontForge (static)
    ohai "Building static FontForge"
    resource("fontforge").stage do
      # Disable failing translation builds
      inreplace "po/CMakeLists.txt", "add_custom_target(pofiles ALL", "add_custom_target(pofiles"

      fontforge_args = %W[
        -DCMAKE_INSTALL_PREFIX=#{staging_prefix}
        -DCMAKE_OSX_ARCHITECTURES=#{archs}
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_GUI=OFF
        -DENABLE_NATIVE_SCRIPTING=ON
        -DENABLE_PYTHON_SCRIPTING=OFF
      ]

      system "cmake", "-S", ".", "-B", "build", *fontforge_args, *std_cmake_args
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    # Stage 4: Build pdf2htmlEX (linking against staged libs)
    ohai "Building pdf2htmlEX"
    
    # V2 Strategy: In-source build pattern
    # Move the compiled dependencies into the directory structure that
    # pdf2htmlEX's CMakeLists.txt expects. This avoids complex patching.
    (buildpath/"poppler").install Pathname.glob("#{staging_prefix}/*")
    (buildpath/"fontforge").install Pathname.glob("#{staging_prefix}/*")

    # Create a build directory inside the source tree
    mkdir "build" do
      # No more inreplace needed! CMake will find deps in ../poppler and ../fontforge
      system "cmake", "..", *std_cmake_args
      system "make"
      system "make", "install"
    end
  end

  test do
    system bin/"pdf2htmlEX", "--version"
    
    # Create a simple test PDF
    (testpath/"test.pdf").write("%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n4 0 obj\n<< /Length 44 >>\nstream\nBT\n/F1 12 Tf\n100 700 Td\n(Hello World) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000207 00000 n \ntrailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n301\n%%EOF")
    
    # Test basic conversion
    system bin/"pdf2htmlEX", "test.pdf"
    assert_predicate testpath/"test.html", :exist?
    
    # Test that the binary is universal
    output = shell_output("file #{bin}/pdf2htmlEX")
    assert_match "Mach-O universal binary", output
    
    # Test that it's statically linked (no Homebrew deps)
    output = shell_output("otool -L #{bin}/pdf2htmlEX")
    assert_no_match %r{#{HOMEBREW_PREFIX}/lib/libpoppler}, output
    assert_no_match %r{#{HOMEBREW_PREFIX}/lib/libfontforge}, output
  end
end