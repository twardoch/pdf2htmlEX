# TODO

## Phase 1: Local Build Validation

### Setup and Script Creation
- [ ] Create v2/scripts/build.sh script that automates the four-stage build process locally
- [ ] Set up staging directory structure in build script for compiled static libraries
- [ ] Configure environment variables for PKG_CONFIG_PATH and JAVA_HOME in build script
- [ ] Add universal binary architecture flags (x86_64;arm64) to all CMake commands

### Stage 1: Build jpeg-turbo
- [ ] Download jpeg-turbo 3.0.2 source from SourceForge
- [ ] Configure CMake for static build with -DENABLE_SHARED=OFF -DENABLE_STATIC=ON
- [ ] Set CMAKE_OSX_ARCHITECTURES to x86_64;arm64 for universal binary
- [ ] Build and install jpeg-turbo to staging prefix directory
- [ ] Verify libjpeg.a is created in staging/lib directory

### Stage 2: Build Poppler
- [ ] Download Poppler 24.01.0 source from freedesktop.org
- [ ] Create test directory placeholder to prevent CMake test data error
- [ ] Configure Poppler build with -DWITH_JPEG=ON -DENABLE_DCTDECODER=libjpeg -DENABLE_LIBJPEG=ON
- [ ] Enable unstable API headers with -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
- [ ] Disable unnecessary components (UTILS, CPP, QT5, QT6)
- [ ] Build static Poppler with BUILD_SHARED_LIBS=OFF
- [ ] Install Poppler to staging prefix directory
- [ ] Verify libpoppler.a is created and includes DCTStream support

### Stage 3: Build FontForge
- [ ] Download FontForge 20230101 source from GitHub
- [ ] Patch po/CMakeLists.txt to disable failing translation builds
- [ ] Configure FontForge with -DENABLE_GUI=OFF -DENABLE_NATIVE_SCRIPTING=ON
- [ ] Disable Python scripting with -DENABLE_PYTHON_SCRIPTING=OFF
- [ ] Build static FontForge with BUILD_SHARED_LIBS=OFF
- [ ] Install FontForge to staging prefix directory
- [ ] Verify libfontforge.a is created in staging/lib directory

### Stage 4: Build pdf2htmlEX
- [ ] Implement in-source build pattern by moving staged libs to expected directories
- [ ] Move staging prefix contents to buildpath/poppler directory
- [ ] Move staging prefix contents to buildpath/fontforge directory
- [ ] Create build directory inside pdf2htmlEX source tree
- [ ] Run CMake from build directory without patching CMakeLists.txt
- [ ] Build pdf2htmlEX binary
- [ ] Install pdf2htmlEX to dist directory

### Validation
- [ ] Verify pdf2htmlEX binary exists in dist/bin directory
- [ ] Run file command to confirm Mach-O universal binary with x86_64 and arm64
- [ ] Run otool -L to verify static linking (only system libraries, no libpoppler/libfontforge)
- [ ] Test pdf2htmlEX --version command works
- [ ] Create test PDF with JPEG image
- [ ] Run pdf2htmlEX on test PDF and verify JPEG image appears in HTML output
- [ ] Test both architectures work correctly (x86_64 and arm64)

## Phase 2: Homebrew Formula Integration

### Formula Creation
- [ ] Create v2/Formula directory structure
- [ ] Create v2/Formula/pdf2htmlex.rb based on v1 formula structure
- [ ] Add jpeg-turbo resource with URL and SHA256
- [ ] Update poppler resource configuration for Poppler 24.01.0
- [ ] Update fontforge resource configuration for FontForge 20230101
- [ ] Port build logic from build.sh script to formula install method
- [ ] Add all required dependencies (cairo, fontconfig, freetype, etc.)
- [ ] Set ENV.cxx11 for C++11 compatibility

### Formula Testing
- [ ] Run brew install --build-from-source v2/Formula/pdf2htmlex.rb
- [ ] Debug and fix any compilation errors during formula build
- [ ] Verify formula creates universal binary
- [ ] Run brew test pdf2htmlex and ensure all tests pass
- [ ] Add comprehensive test block including version check and sample PDF conversion
- [ ] Run brew audit --strict v2/Formula/pdf2htmlex.rb
- [ ] Fix any audit warnings or errors
- [ ] Test formula on both Intel and Apple Silicon Macs

## Phase 3: CI/CD and Bottling

### GitHub Actions Setup
- [ ] Copy v1/.github/workflows to v2/.github/workflows
- [ ] Update test.yml workflow to use v2 formula path
- [ ] Configure test matrix for macos-12, macos-13, and macos-14
- [ ] Add both x86_64 and arm64 architecture testing
- [ ] Update release.yml workflow for v2 formula bottling
- [ ] Configure bottle upload process for all target platforms
- [ ] Update security.yml workflow for v2 codebase
- [ ] Add dependency caching to speed up CI builds

### CI/CD Testing
- [ ] Push v2 branch and trigger test workflow
- [ ] Verify test workflow passes on all macOS versions
- [ ] Test workflow on both Intel and Apple Silicon runners
- [ ] Create test release tag to trigger release workflow
- [ ] Verify bottles are created for all platforms
- [ ] Test bottle installation on clean macOS systems
- [ ] Verify security scanning completes without issues

## Additional Tasks

### Documentation and Maintenance
- [ ] Create v2/README.md documenting the new build approach
- [ ] Document jpeg-turbo vendoring solution in CLAUDE.md
- [ ] Create v2/scripts/update-version.sh for managing dependency updates
- [ ] Add script to verify SHA256 checksums for all resources
- [ ] Document the in-source build pattern advantages
- [ ] Create troubleshooting guide for common build issues

### Risk Mitigation
- [ ] Create fallback patch-based build option if in-source pattern fails
- [ ] Document Docker-first strategy as ultimate fallback
- [ ] Create v2/PLANS/docker-fallback.md with implementation details
- [ ] Test formula with different Xcode versions
- [ ] Verify formula works with different Homebrew configurations
- [ ] Create automated dependency update checking script

### Final Validation
- [ ] Full end-to-end test on clean macOS system
- [ ] Performance testing comparing v2 to original pdf2htmlEX
- [ ] Test with complex PDFs containing various image formats
- [ ] Verify all fonts render correctly in output HTML
- [ ] Check for any runtime dependency issues
- [ ] Validate universal binary runs natively on both architectures