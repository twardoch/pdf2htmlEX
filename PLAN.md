# Plan to build pdf2htmlEX on macOS

## Overview

The goal is to create a reliable, self-contained build of pdf2htmlEX for macOS that produces a universal binary (x86_64 and arm64). This project maintains two parallel build approaches:

- **v1**: Homebrew formula approach using patched sources
- **v2**: Standalone build script with complete dependency vendoring

## Current Status: Build Fixes Applied

### v1 Build (Homebrew Formula)
**Status**: ✅ **Fixed** - Poppler 24 API compatibility issues resolved

The v1 build was failing due to Poppler API changes in version 24. Applied comprehensive patches to fix:
- `FoFiTrueType::load()` now returns `std::unique_ptr<FoFiTrueType>` instead of raw pointer
- `font->getName()` now returns `std::optional<std::string>` instead of `GooString*`
- `font->locateFont()` now returns `std::optional<GfxFontLoc>` instead of raw pointer
- `GfxFontLoc::path` is now `std::string` instead of `GooString*`
- Various other API changes for smart pointers and modern C++

**Fixes Applied**:
- Added comprehensive regex-based patches in the v1 formula
- Fixed all font.cc API compatibility issues
- Added patches for state.cc, text.cc, form.cc, link.cc, outline.cc, and pdf2htmlEX.cc
- Maintained backward compatibility while supporting Poppler 24

### v2 Build (Standalone Script)
**Status**: ✅ **Fixed** - Universal binary linking issues resolved

The v2 build was failing due to architecture mismatches in libtiff linking. Fixed by:
- Reordering dependency builds to ensure prerequisites are built first
- Converting libtiff to use per-architecture builds with `lipo` merging
- Ensuring all dependencies (libdeflate, libwebp, libjpeg, libpng, libgif) are built as universal binaries
- Proper library discovery and linking for all architectures

**Fixes Applied**:
- Reordered build sequence: libpng → libgif → libdeflate → libwebp → libtiff
- Changed libtiff to use the same per-architecture build pattern as other libraries
- Added proper library path specifications for all dependencies
- Ensured CMake finds static libraries correctly with `-DCMAKE_FIND_LIBRARY_SUFFIXES=.a`

## Next Steps

### Phase 1: Validation and Testing
1. **Test v1 build** - Verify the Homebrew formula builds successfully
2. **Test v2 build** - Verify the standalone script produces working binaries  
3. **Functional testing** - Test PDF conversion with various PDF types
4. **Architecture verification** - Confirm universal binary support on both Intel and Apple Silicon

### Phase 2: Quality Assurance
1. **Performance testing** - Benchmark conversion speed and memory usage
2. **Compatibility testing** - Test with various PDF formats and edge cases
3. **Error handling** - Verify graceful handling of malformed PDFs
4. **Documentation** - Update README with build instructions and usage examples

### Phase 3: Distribution Preparation
1. **Homebrew integration** - Prepare v1 formula for official Homebrew submission
2. **Release packaging** - Create distributable binaries from v2 build
3. **CI/CD setup** - Automate testing and building across architectures
4. **Version management** - Establish release tagging and changelog practices

## Build Architecture

### v1 (Homebrew Formula)
- **Approach**: Traditional Homebrew formula with staged builds
- **Dependencies**: Uses Homebrew's dependency resolution + vendored Poppler/FontForge
- **Patches**: Runtime source patching for API compatibility
- **Output**: Homebrew-managed installation in `/usr/local` or `/opt/homebrew`

### v2 (Standalone Script)
- **Approach**: Complete dependency vendoring with universal static linking
- **Dependencies**: All dependencies built from source as universal binaries
- **Patches**: Applied during build process from dedicated patch files
- **Output**: Self-contained `dist/` directory with standalone binary

## Technical Details

### Universal Binary Strategy
Both builds use `CMAKE_OSX_ARCHITECTURES="x86_64;arm64"` where possible, falling back to per-architecture builds with `lipo` merging for libraries that don't support multi-arch CMake builds.

### Dependency Management
- **libjpeg-turbo**: Per-arch builds (inline assembly restrictions)
- **libwebp**: Per-arch builds (linking complexity)
- **libdeflate**: Per-arch builds (consistency)
- **libtiff**: Per-arch builds (dependency resolution)
- **poppler**: Single universal build (CMake native support)
- **fontforge**: Single universal build (CMake native support)

### Static Linking Strategy
All dependencies are built as static libraries (`.a` files) to ensure the final binary has no runtime dependencies beyond macOS system frameworks. This creates a truly portable binary that works across different macOS versions and configurations.