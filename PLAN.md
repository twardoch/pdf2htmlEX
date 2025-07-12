# Plan to build pdf2htmlEX on macOS

## Overview

The goal is to create a reliable, self-contained build of pdf2htmlEX for macOS that produces a universal binary (x86_64 and arm64). This project now focuses on the `v2` standalone build script approach, with `legacy/v1` serving as an archived reference.

- **v2**: Standalone build script with complete dependency vendoring
- **legacy/v1**: Archived Homebrew formula approach using patched sources (for reference)

## Current Status

### legacy/v1 Build (Homebrew Formula)
**Status**: 📦 **Archived** - Moved to `legacy/v1` for historical reference.

### v2 Build (Standalone Script)
**Status**: 🔧 **In Progress** - Most dependencies built successfully

Current state:
- ⏳ **lcms2**: Build script updated with cross-compilation fixes, needs testing
- ⏳ **Poppler, FontForge, pdf2htmlEX**: Waiting on lcms2 completion

## Next Steps

### Phase 1: Complete Builds
1. **Complete v2 build** - Finish lcms2 build, then build Poppler, FontForge, and pdf2htmlEX
2. **Initial testing** - Verify v2 build produces working binaries

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
- **Build Order**: libpng → libgif → libdeflate → libwebp → libtiff → openjpeg → lcms2 → freetype → fontconfig → cairo → poppler → fontforge → pdf2htmlEX
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

### Known Issues and Solutions
1. **Dynamic library preference**: Remove .dylib files to force static linking
2. **Cross-compilation**: Use --host=arm64-apple-darwin for autotools on arm64
3. **CMake booleans**: Some packages require lowercase on/off instead of ON/OFF
4. **Library dependencies**: Disable optional features (like WebP in libtiff) to simplify builds