# Troubleshooting Guide - pdf2htmlEX Mac Build

## Common Build Failures and Solutions

### 1. Framework Linking Errors

**Error**: `clang++: error: no such file or directory: 'ApplicationServices'`

**Solution**: This should be fixed in the current build script. If it persists:
```bash
# Manually fix pkg-config files
find v2/build/staging/lib/pkgconfig -name "*.pc" -exec sed -i.bak \
  's/-framework \([^ ]*\)/-Wl,-framework,\1/g' {} \;
```

### 2. Architecture Mismatch

**Error**: `Undefined symbols for architecture arm64` or `x86_64`

**Solution**: 
- Ensure all dependencies built as universal binaries
- Check with: `lipo -info v2/build/staging/lib/*.a`
- Force single architecture build: `ARCHS="x86_64" ./build.sh`

### 3. Missing Build Tools

**Error**: `Missing command: cmake` or `ninja`

**Solution**: Install required tools:
```bash
# Using Homebrew
brew install cmake ninja

# Or download directly
# CMake: https://cmake.org/download/
# Ninja: https://github.com/ninja-build/ninja/releases
```

### 4. Patch Application Failures

**Error**: `patch: **** malformed patch` or interactive prompts

**Solution**: 
- Delete patch markers: `rm -f v2/build/.patch_*_applied`
- Check patch compatibility: `patch --dry-run -p1 < patch_file`

### 5. FontConfig Build Failures

**Error**: `Invalid configuration 'arm64-apple-darwin'`

**Solution**: config.sub should auto-update. If not:
```bash
cd v2/build/src/fontconfig-*/
curl -o config.sub "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub"
chmod +x config.sub
```

### 6. Poppler Linking Errors

**Error**: Missing symbols from dependencies

**Solution**: Verify all dependencies built:
```bash
ls -la v2/build/staging/lib/ | grep -E "(libjpeg|libpng|libgif|libfontconfig|libcairo)\.a"
```

### 7. Out of Disk Space

**Error**: `No space left on device`

**Solution**: 
- Build requires ~2GB free space
- Clean previous builds: `rm -rf v2/build`
- Keep only final artifacts: `rm -rf v2/build/src`

## Debugging Steps

### 1. Check Build Logs
```bash
# View last 100 lines of error log
tail -100 v2/build.err.txt

# Search for specific errors
grep -i "error\|fail\|undefined" v2/build.err.txt
```

### 2. Verify Dependencies
```bash
# Check what's been built
ls -la v2/build/staging/lib/*.a

# Check pkg-config files
ls -la v2/build/staging/lib/pkgconfig/*.pc

# Test pkg-config
PKG_CONFIG_PATH=v2/build/staging/lib/pkgconfig pkg-config --libs poppler
```

### 3. Clean Build
```bash
# Full clean rebuild
CLEAN=1 ./v2/build.sh

# Partial clean (keep downloaded sources)
rm -rf v2/build/staging
rm -rf v2/build/src/*/build*
```

### 4. Verbose Output
```bash
# Add to build.sh for more output
set -x  # Enable command tracing
export VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON
```

## Platform-Specific Issues

### macOS Version Compatibility
- Requires macOS 11.0 or later
- Xcode 12.0 or later
- Command Line Tools must be installed

### Homebrew Conflicts
- Ensure `/usr/local/bin` or `/opt/homebrew/bin` not interfering
- Temporarily remove from PATH if needed:
  ```bash
  export PATH=/usr/bin:/bin:/usr/sbin:/sbin
  ```

### Apple Silicon (M1/M2) Specific
- Rosetta 2 may be needed for some tools
- Some dependencies may need `--build=aarch64-apple-darwin`

## Getting Help

If none of these solutions work:

1. **Collect Debug Info**:
   ```bash
   # System info
   sw_vers
   xcodebuild -version
   which -a cmake ninja make
   
   # Build environment
   echo $PATH
   echo $PKG_CONFIG_PATH
   
   # Error context
   tail -200 v2/build.err.txt > build_error.log
   ```

2. **Check Existing Issues**: Review `issues/` directory for similar problems

3. **Document the Issue**: Include:
   - Exact error message
   - macOS version and architecture
   - Steps to reproduce
   - What you've tried

## Quick Fixes Checklist

- [ ] All build tools installed (cmake, ninja, etc.)
- [ ] Xcode Command Line Tools installed
- [ ] Sufficient disk space (2GB+)
- [ ] No Homebrew path conflicts
- [ ] Previous build artifacts cleaned
- [ ] Framework fixes applied to .pc files
- [ ] Patches tracked properly
- [ ] All dependencies built successfully