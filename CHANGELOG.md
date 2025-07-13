# CHANGELOG

## [Unreleased] - 2025-07-13

### Critical Build System Fixes (Build Analysis and Repair)

#### Build Error Analysis and Resolution
After extensive analysis of build failures in `issues/102.txt`, identified and addressed multiple critical build system issues:

#### Fixed - Framework Linker Arguments
- **Problem**: Malformed framework arguments causing `clang++: error: no such file or directory: 'ApplicationServices'`
- **Root Cause**: Cairo's pkg-config files contained `-framework ApplicationServices` which CMake/ninja didn't quote properly
- **Solution**: Added automatic sed fix in `build.sh` to convert framework flags to `-Wl,-framework,CoreFoundation -Wl,-framework,ApplicationServices` format
- **Files Modified**: `v2/scripts/build.sh` (lines 1288-1295)

#### Fixed - Universal Binary Architecture Support
- **Problem**: FontConfig configure failing with `Invalid configuration 'arm64-apple-darwin': machine 'arm64-apple' not recognized`
- **Root Cause**: Outdated config.sub in fontconfig-2.15.0 doesn't recognize arm64 architecture
- **Solution**: Added automatic config.sub update from GNU config repository during fontconfig build
- **Files Modified**: `v2/scripts/build.sh` (lines 1252-1257)

#### Fixed - FontConfig Static Library Integration
- **Problem**: Poppler still linking against system fontconfig (`/usr/local/lib/libfontconfig.dylib`) despite configuration
- **Root Cause**: FontConfig build was commented out due to previous issues
- **Solution**: 
  - Re-enabled fontconfig build with per-architecture compilation and lipo merging
  - Updated Poppler CMake configuration with explicit static fontconfig paths
  - Set PKG_CONFIG_PATH to prioritize staged dependencies
- **Files Modified**: 
  - `v2/scripts/build.sh` (lines 1238-1313, 1417-1446)
  - Added `-DFONTCONFIG_LIBRARY` and `-DFONTCONFIG_INCLUDE_DIR` to Poppler build

#### Fixed - Cairo FontConfig Integration
- **Problem**: Cairo built with fontconfig disabled, breaking dependency chain
- **Root Cause**: Previous build issues led to disabling fontconfig support
- **Solution**: Re-enabled fontconfig in Cairo meson configuration (`-Dfontconfig=enabled`)
- **Files Modified**: `v2/scripts/build.sh` (line 1340)

#### Updated - Build Environment Isolation
- **Problem**: System libraries (Homebrew) interfering with static builds
- **Solution**: 
  - Set PKG_CONFIG_PATH to only include staged dependencies
  - Added explicit environment variables for FONTCONFIG_CFLAGS and FONTCONFIG_LIBS
  - Improved library path isolation
- **Files Modified**: `v2/scripts/build.sh` (lines 1417-1427)

### Build Infrastructure Improvements

#### Enhanced Error Handling
- Improved curl command for config.sub download with better error handling
- Added fallback mechanisms for config.sub updates

#### Dependency Chain Fixes
- **Complete chain**: pdf2htmlEX → poppler-glib → cairo → fontconfig
- All components now configured for universal binary static linking
- Proper dependency order and library path management

### Current Build Status
- **Basic dependencies**: ✅ All built successfully (libjpeg-turbo, libpng, bzip2, brotli, etc.)
- **FontConfig**: 🔧 Build script fixed, testing in progress
- **Cairo**: ✅ Framework linking fixed, fontconfig enabled
- **Poppler**: 🔧 Configuration updated, awaiting fontconfig completion
- **pdf2htmlEX**: ⏳ Pending successful Poppler build

### Technical Debt Addressed
- Removed temporary workarounds and disabled features
- Restored full fontconfig support throughout dependency chain
- Improved universal binary build reliability
- Enhanced pkg-config path management

### Files Modified in This Session
- `v2/scripts/build.sh` - Major updates to fontconfig, Cairo, and Poppler builds
- `v2/build/staging/lib/pkgconfig/cairo*.pc` - Framework argument fixes
- `WORK.md` - Updated with current build status and issue analysis

### Known Issues Being Addressed
- Some test executables still failing to link (tests can be disabled)
- Poppler test data warnings (non-critical, expected)
- CMake policy warnings (non-blocking)

## [Previous] - 2025-07-12

### Added
- v2 standalone build script for creating universal binaries
- Per-architecture build support for problematic libraries
- Cross-compilation support for arm64 architecture
- Static library preference enforcement

### Fixed
- CMake boolean case sensitivity issue (PNG_INTEL_SSE must be lowercase)
- WebP/libsharpyuv linking issues in libtiff (disabled WebP support)
- OpenJPEG tools linking errors (disabled codec tools)
- Dynamic library preference (removed .dylib files to force static linking)
- lcms2 arm64 cross-compilation (added --host flag for configure)
- libpng ARM NEON optimization issues

### Changed
- Moved v1 Homebrew formula to legacy/v1 directory
- Project now focuses on v2 standalone build approach
- Simplified dependency builds by disabling optional features

### Completed Builds
Successfully built the following dependencies as universal static libraries:
- libjpeg-turbo 3.0.2
- libpng 1.6.43
- libgif 5.2.2
- libdeflate 1.18
- libwebp 1.3.2
- libtiff 4.4.0
- openjpeg 2.5.0

### In Progress
- lcms2 2.14 (build script updated, needs testing)
- Poppler 24.01.0
- FontForge 20230101
- pdf2htmlEX 0.18.8.rc1