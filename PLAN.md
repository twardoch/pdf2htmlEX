# Plan to build pdf2htmlEX on macOS

## Overview

The goal is to create a reliable, self-contained build of pdf2htmlEX for macOS that produces a universal binary (x86_64 and arm64). This project now focuses on the `v2` standalone build script approach, with `legacy/v1` serving as an archived reference.

- **v2**: Standalone build script with complete dependency vendoring
- **legacy/v1**: Archived Homebrew formula approach using patched sources (for reference)

## Current Status

### legacy/v1 Build (Homebrew Formula)
**Status**: 📦 **Archived** - Moved to `legacy/v1` for historical reference.

### v2 Build (Standalone Script)
**Status**: 🚀 **Functional & Progressing** - Critical build issues resolved, 7+ dependencies built successfully

Current state:
- ✅ **Core dependencies**: libjpeg-turbo, libpng, libgif, bzip2, brotli, expat, harfbuzz
- ⏳ **gettext**: Currently building (in progress)
- 🎯 **Next**: glib, cairo, lcms2, freetype, fontconfig, poppler, fontforge, pdf2htmlEX

## Next Steps

### Phase 1: Complete Builds (🎯 **URGENT - FOCUS HERE**)
1. **Monitor current build** - gettext is building, let it complete
2. **Continue dependency chain** - glib → cairo → lcms2 → freetype → fontconfig → poppler → fontforge
3. **Build final pdf2htmlEX** - The ultimate goal
4. **Initial testing** - Verify v2 build produces working binaries

### Phase 2: Testing and Validation
1. **Binary testing** - Test pdf2htmlEX on both x86_64 and arm64 architectures
2. **Functional testing** - Test PDF conversion with sample files
3. **Architecture verification** - Confirm universal binary support with `lipo -info`
4. **Build verification** - Add automated tests to v2 system

### Phase 3: Quality Assurance
1. **Create test suite** - Build collection of sample PDFs for validation
2. **Performance testing** - Benchmark conversion speed and memory usage
3. **Error handling** - Verify graceful handling of malformed PDFs
4. **Build metrics** - Track build time and binary size

### Phase 4: Documentation and Distribution
1. **Documentation** - Document v2 build process and usage instructions
2. **Release packaging** - Create distributable binaries from v2 build
3. **CI/CD setup** - Automate testing and building
4. **Version management** - Establish release tagging and changelog practices

## Build Architecture

### v2 (Standalone Script)
- **Approach**: Complete dependency vendoring with universal static linking
- **Dependencies**: All dependencies built from source as universal binaries
- **Build Order**: ✅ libjpeg-turbo → ✅ libpng → ✅ libgif → ✅ bzip2 → ✅ brotli → ✅ expat → ✅ harfbuzz → ⏳ gettext → glib → cairo → lcms2 → freetype → fontconfig → poppler → fontforge → 🎯 **pdf2htmlEX**
- **Output**: Self-contained `dist/` directory with standalone binary

## Technical Details

### Universal Binary Strategy
- Use `CMAKE_OSX_ARCHITECTURES="x86_64;arm64"` where possible
- Fall back to per-architecture builds with `lipo` merging for problematic libraries
- Ensure all static libraries are properly merged before final linking

### Dependency Management
- **Per-arch builds**: libjpeg-turbo, libwebp, libdeflate, libtiff, lcms2
- **Universal builds**: libpng, libgif, openjpeg, poppler, fontforge
- **Key flags**: Force static linking with `-DCMAKE_FIND_LIBRARY_SUFFIXES=.a`

### Known Issues and Solutions ✅ **RESOLVED**
1. ✅ **SHA256 verification failures**: Fixed all placeholder/incorrect hash values
2. ✅ **Archive extraction errors**: Completely rewrote fetch_and_extract function for --strip-components=1
3. ✅ **Build configuration conflicts**: Eliminated meson duplicates and linker issues
4. ✅ **Universal binary creation**: Fixed lipo architecture handling
5. ✅ **Missing CMakeLists.txt**: Resolved extraction directory logic
6. ✅ **bzip2 linker errors**: Removed macOS-incompatible -soname options

### Critical Success Factors for Remaining Build
1. **Monitor for new build failures** - Address immediately as they appear
2. **Maintain momentum** - Build system is now functional, keep it moving
3. **Focus on pdf2htmlEX final binary** - The ultimate deliverable