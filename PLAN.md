# V2 Plan: A Detailed Blueprint for a Resilient pdf2htmlEX Homebrew Formula

This document provides a detailed, actionable plan for creating a stable and maintainable Homebrew formula for `pdf2htmlEX` on macOS. It synthesizes the lessons from the `v1` attempt and the strategic insights from all `v2` planning documents.

## 1. Executive Summary: The Path to Success

The `v1` attempt correctly identified the core strategy—vendoring specific versions of `Poppler` and `FontForge`—but failed on a specific compilation issue (`DCTStream` error) due to disabling JPEG support in Poppler.

The `v2` strategy corrects this by building upon the `v1` foundation with two key improvements:

1.  **Re-enable JPEG Support**: We will vendor and statically build `libjpeg-turbo`, allowing `Poppler` to compile correctly without disabling its core features. This fixes the root cause of the `v1` failure.
2.  **Adopt an In-Source Build Pattern**: Instead of complex patching of `pdf2htmlEX`'s `CMakeLists.txt`, we will create the exact directory structure it expects. This simplifies the build process, making it more robust and easier to maintain.

The result will be a self-contained, universal binary that works reliably across modern Intel and Apple Silicon Macs.

## 2. The V2 Homebrew Formula: A Technical Deep Dive

The new formula, `v2/Formula/pdf2htmlex.rb`, will be structured as follows. This is a near-complete implementation, heavily commented to explain the rationale behind each decision.

```ruby
# typed: false
# frozen_string_literal: true

class Pdf2htmlex < Formula
  desc "Convert PDF to HTML without losing text or format"
  homepage "https://github.com/pdf2htmlEX/pdf2htmlEX"
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz"
  sha256 "a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641"
  license "GPL-3.0-or-later"
  version "0.18.8.rc1"

  # ==> V2 Strategy: Add jpeg-turbo as a resource to fix Poppler build
  resource "jpeg-turbo" do
    url "https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-3.0.2.tar.gz"
    sha256 "b248932c275a39395a55434385d83442b25d6894435511c333a74991c1aeba5f"
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

    # --- Stage 1: Build jpeg-turbo (static) ---
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

    # --- Stage 2: Build Poppler (static) ---
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

    # --- Stage 3: Build FontForge (static) ---
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

    # --- Stage 4: Build pdf2htmlEX (linking against staged libs) ---
    ohai "Building pdf2htmlEX"
    
    # ==> V2 Strategy: In-source build pattern
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
    # ... more comprehensive tests from v1 ...
  end
end
```

## 4. Phased Implementation and Validation Plan

This plan breaks the work into manageable, verifiable stages.

#### **Phase 1: Local Build Validation**
*   **Task**: Create a `v2/scripts/build.sh` script that automates the four-stage build process locally, outside of Homebrew.
*   **Goal**: Prove that the build logic is sound and produces a working, universal binary.
*   **Validation**:
    1.  The script completes without errors.
    2.  The final `pdf2htmlEX` binary is created in a `dist/` directory.
    3.  `file dist/bin/pdf2htmlEX` reports `Mach-O universal binary with 2 architectures: [x86_64:..., arm64:...]`.
    4.  `otool -L dist/bin/pdf2htmlEX` shows linkage only to system libraries (e.g., `libSystem.B.dylib`, `libc++.1.dylib`), not to Homebrew-installed versions of `libpoppler` or `libfontforge`.
    5.  Run the binary on a test PDF with a JPEG image and verify that the image is present in the output HTML.

#### **Phase 2: Homebrew Formula Integration**
*   **Task**: Port the successful logic from `build.sh` into the `install` block of `v2/Formula/pdf2htmlex.rb`.
*   **Goal**: A working Homebrew formula that can be installed from source.
*   **Validation**:
    1.  `brew install --build-from-source v2/Formula/pdf2htmlex.rb` completes successfully.
    2.  `brew test pdf2htmlex` passes.
    3.  `brew audit --strict` passes with no major errors.

#### **Phase 3: CI/CD and Bottling**
*   **Task**: Adapt the GitHub Actions workflows from `v1` to the `v2` formula.
*   **Goal**: A fully automated CI/CD pipeline for testing, bottling, and releasing.
*   **Validation**:
    1.  The `test.yml` workflow passes on `macos-12`, `macos-13`, and `macos-14` for both Intel and Apple Silicon architectures.
    2.  The `release.yml` workflow successfully builds and uploads bottles for all target platforms when a new version is tagged.
    3.  The `security.yml` workflow runs without errors.

## 5. Risk Mitigation and Fallback Strategies

*   **Risk**: New versions of dependencies introduce breaking changes.
    *   **Mitigation**: The formula pins exact versions via URL and SHA256. Updates will require careful testing. The `v2/scripts/update-version.sh` script will be used to manage this process.
*   **Risk**: The in-source build pattern fails due to subtle path issues.
    *   **Mitigation**: Revert to the `v1` strategy of patching `CMakeLists.txt` with `inreplace`, which is more complex but proven to work for path redirection.
*   **Risk**: Native compilation proves too fragile or time-consuming for CI.
    *   **Mitigation (Fallback Plan)**: Adopt the **Docker-first strategy** outlined in `v2/PLANS/plan4.md`. This involves shipping a lightweight wrapper script that executes `pdf2htmlEX` inside a pre-built Docker container. This guarantees functionality at the cost of a Docker runtime dependency.

This detailed plan provides a clear and robust path forward, addressing the specific technical blockers of the past while building on its successes.