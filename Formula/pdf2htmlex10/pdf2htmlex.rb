# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v0.18.8.rc1.tar.gz"
  version "0.18.8.rc1"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  revision 18

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
    url "https://poppler.freedesktop.org/poppler-0.82.0.tar.xz"
    sha256 "234f8e573ea57fb6a008e7c1e56bfae1af5d1adf0e65f47555e1ae103874e4df"
  end

  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/releases/download/20190801/fontforge-20190801.tar.gz"
    sha256 "d92075ca783c97dc68433b1ed629b9054a4b4c74ac64c54ced7f691540f70852"
  end

  def install
    staging_prefix = buildpath/"staging"
    ENV.cxx11
    archs = "x86_64;arm64"

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

    resource("poppler").stage do
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

    resource("fontforge").stage do
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
               "-DENABLE_NLS=OFF",
               "-DBUILD_SHARED_LIBS=OFF"
        system "ninja", "install"
        system "cp", "lib/libfontforge.a", "#{staging_prefix}/lib/"
      end
    end

    ENV.prepend_path "PKG_CONFIG_PATH", "#{staging_prefix}/lib/pkgconfig"
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix

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

  test do
    system bin/"pdf2htmlEX", "--version"
  end
end