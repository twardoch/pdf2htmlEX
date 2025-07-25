# Build Instructions - pdf2htmlEX for macOS

This guide explains how to build pdf2htmlEX on macOS using the v2 standalone build system.

## Prerequisites

### Required Tools
- macOS 11.0 or later
- Xcode Command Line Tools
- CMake (3.16+)
- Ninja build system
- curl
- GNU make

### Install Prerequisites
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install build tools via Homebrew
brew install cmake ninja

# Or download directly:
# - CMake: https://cmake.org/download/
# - Ninja: https://github.com/ninja-build/ninja/releases
```

### Verify Installation
```bash
# Check all required tools
cmake --version
ninja --version
make --version
curl --version
shasum --version
```

## Building pdf2htmlEX

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/pdf2htmlEX.git
cd pdf2htmlEX
```

### 2. Run the Build Script
```bash
cd v2
./build.sh
```

The build script will:
- Download all dependencies
- Build static libraries for each dependency
- Create universal binaries (x86_64 + arm64)
- Build pdf2htmlEX with all dependencies statically linked
- Install the final binary to `v2/dist/bin/pdf2htmlEX`

### 3. Build Options

**Single Architecture Build** (faster, for testing):
```bash
ARCHS="x86_64" ./build.sh     # Intel only
ARCHS="arm64" ./build.sh      # Apple Silicon only
```

**Clean Build** (remove all previous artifacts):
```bash
CLEAN=1 ./build.sh
```

**Verbose Output** (for debugging):
```bash
set -x
./build.sh
```

### 4. Monitor Progress

The build creates two log files:
- `v2/build.log.txt` - Standard output
- `v2/build.err.txt` - Error output

Monitor in real-time:
```bash
# In another terminal
tail -f v2/build.log.txt
```

## Build Time Expectations

- Apple Silicon (M1/M2): ~10-15 minutes
- Intel Mac: ~20-30 minutes
- First build downloads ~100MB of sources

## Verifying the Build

### 1. Run the Test Script
```bash
./scripts/test-build.sh
```

This checks:
- Binary exists and is executable
- Architecture support (universal binary)
- No unwanted dynamic dependencies
- Build completed without critical errors

### 2. Manual Verification
```bash
# Check binary exists
ls -la v2/dist/bin/pdf2htmlEX

# Check architecture
lipo -info v2/dist/bin/pdf2htmlEX

# Check dependencies (should only show system libs)
otool -L v2/dist/bin/pdf2htmlEX

# Test basic functionality
v2/dist/bin/pdf2htmlEX --version
```

### 3. Test PDF Conversion
```bash
# Convert a simple PDF
v2/dist/bin/pdf2htmlEX test.pdf

# With options
v2/dist/bin/pdf2htmlEX --zoom 1.3 --split-pages 1 test.pdf output/
```

## Installation

### Local Installation
The binary is self-contained and can be copied anywhere:
```bash
# Copy to /usr/local/bin
sudo cp v2/dist/bin/pdf2htmlEX /usr/local/bin/

# Or add to PATH
export PATH="$PWD/v2/dist/bin:$PATH"
```

### System-wide Installation
```bash
# Copy binary
sudo cp v2/dist/bin/pdf2htmlEX /usr/local/bin/

# Copy data files
sudo cp -r v2/dist/share/pdf2htmlEX /usr/local/share/
```

## Troubleshooting

If the build fails:

1. **Check the error log**: `tail -100 v2/build.err.txt`
2. **See common issues**: Read `v2/TROUBLESHOOTING.md`
3. **Review fixes applied**: See `v2/FIXES.md`

### Quick Fixes

**Framework linking errors**:
```bash
find v2/build/staging/lib/pkgconfig -name "*.pc" -exec sed -i.bak \
  's/-framework \([^ ]*\)/-Wl,-framework,\1/g' {} \;
```

**Architecture issues**:
```bash
# Force single architecture
ARCHS="x86_64" ./build.sh
```

**Clean rebuild**:
```bash
rm -rf v2/build v2/dist
./build.sh
```

## Build Artifacts

After successful build:
- `v2/dist/bin/pdf2htmlEX` - The executable
- `v2/dist/share/pdf2htmlEX/` - Data files
- `v2/build/staging/` - All static libraries
- `v2/build/src/` - Downloaded sources

## Advanced Options

### Custom Installation Prefix
Edit `build.sh` and change:
```bash
DIST_DIR="${ROOT_DIR}/v2/dist"  # Change this path
```

### Specific Dependency Versions
Edit version numbers at the top of `v2/scripts/build.sh`

### Debug Build
Edit `build.sh` and change:
```bash
-DCMAKE_BUILD_TYPE=Release  # Change to Debug
```

## Support

- Check existing issues in `issues/` directory
- Review `CHANGELOG.md` for recent changes
- See `PLAN.md` for project roadmap

## Success!

If you see this output, the build succeeded:
```
✓ pdf2htmlEX binary found at v2/dist/bin/pdf2htmlEX
✓ Universal binary (x86_64 + arm64) confirmed
✓ No Homebrew dependencies found
✓ All tests passed!
```

You now have a working pdf2htmlEX binary for macOS!