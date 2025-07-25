# pdf2htmlEX v2 - Standalone Build System

This directory contains the v2 standalone build system for pdf2htmlEX on macOS, creating universal binaries without Homebrew dependencies.

## 🚀 Quick Start

```bash
cd v2
./build.sh

# After build completes (~15 minutes):
./dist/bin/pdf2htmlEX --version
```

## 📚 Documentation

- **[BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)** - Complete step-by-step build guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Solutions for common build issues
- **[FIXES.md](FIXES.md)** - Details of critical fixes applied
- **[SPEC.md](SPEC.md)** - Technical architecture and design

## ✅ Build Status

All critical issues have been resolved:
- ✅ **Framework linking** - Fixed pkg-config files for proper macOS framework syntax
- ✅ **Universal binary** - Builds for both x86_64 and arm64 architectures
- ✅ **Patch tracking** - Prevents duplicate patch applications
- ✅ **Static linking** - All dependencies vendored, no runtime Homebrew deps

## 🔧 What This Builds

The build script creates:
- `dist/bin/pdf2htmlEX` - Universal binary executable
- `dist/share/pdf2htmlEX/` - Required data files
- All dependencies built from source as static libraries

## 🧪 Testing

After building, validate with:

```bash
# Run comprehensive tests
./scripts/test-build.sh

# Test PDF conversion
./dist/bin/pdf2htmlEX test.pdf
```

## Test Suite

The `v2/tests/` directory contains a comprehensive test suite:

*   `test_basic.sh`: Validates core functionality and binary integrity.
*   `test_fonts.sh`: Tests various font handling scenarios.
*   `test_integration.sh`: Performs a full integration test of the Homebrew formula.

To run all tests:

```bash
./v2/tests/test_integration.sh
```

## Version Management

To update the versions of the vendored dependencies, use the `update-version.sh` script:

```bash
# Example: Update Poppler to a new version
./v2/scripts/update-version.sh poppler 24.02.0
```

This script will automatically download the new source, calculate the SHA256 checksum, and update the formula file.
