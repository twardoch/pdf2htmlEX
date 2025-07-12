# CHANGELOG

## [Unreleased] - 2025-07-12

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