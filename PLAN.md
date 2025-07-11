# Plan to build pdf2htmlEX on macOS

The goal is to create a reliable, self-contained build of pdf2htmlEX for macOS that produces a universal binary (x86_64 and arm64).

The current build process is failing due to linker errors related to mismatched architectures in the dependencies. The solution is to vendor all required dependencies and build them from source as static, universal libraries.

## Phase 1: Vendor and Build Dependencies

1.  **Create a `vendor` directory:** This directory will contain the source code for all dependencies.
2.  **Update the build script (`v2/scripts/build.sh`):**
    *   Add functions to download and extract the source code for each dependency into the `vendor` directory.
    *   Add build functions for each dependency. These functions will:
        *   Configure the build using CMake or autotools.
        *   Set the correct flags for a static, universal build (`-arch x86_64 -arch arm64`).
        *   Install the compiled libraries into the `staging` directory.
3.  **List of dependencies to vendor:**
    *   `libjpeg-turbo` (already vendored)
    *   `poppler` (already being built from source)
    *   `fontforge`
    *   `nss`
    *   `gpgme`
    *   `lcms2`
    *   `libpng`
    *   `openjpeg`
    *   `freetype`
    *   `fontconfig`
    *   `cairo`

## Phase 2: Build pdf2htmlEX

1.  **Update `pdf2htmlEX` CMakeLists.txt:**
    *   Modify the `CMakeLists.txt` to find and link against the static libraries in the `staging` directory.
    *   This will involve setting `CMAKE_PREFIX_PATH` and potentially other variables to point to the `staging` directory.
2.  **Build `pdf2htmlEX`:**
    *   Compile `pdf2htmlEX` as a static, universal binary, linking against the vendored dependencies.

## Phase 3: Testing and Refinement

1.  **Run the build script:**
    *   Execute the updated build script and ensure that it completes without errors.
2.  **Test the `pdf2htmlEX` binary:**
    *   Run the compiled `pdf2htmlEX` binary to verify that it works correctly.
    *   Test on both x86_64 and arm64 architectures.
3.  **Refine the build process:**
    *   Clean up the build script and remove any unnecessary steps.
    *   Document the build process in the `README.md`.