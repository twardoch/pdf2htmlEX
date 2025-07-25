# Plan to build pdf2htmlEX on macOS

## Overview

The goal is to create a reliable, self-contained build of pdf2htmlEX for macOS that produces a universal binary (x86_64 and arm64). This project now focuses on the `v2` standalone build script approach, with `legacy/v1` serving as an archived reference.

- **v2**: Standalone build script with complete dependency vendoring
- **legacy/v1**: Archived Homebrew formula approach using patched sources (for reference)

## Current Status

### v2 Build (Standalone Script)
**Status**: 🔧 **FIXES APPLIED** - All critical issues addressed, ready for testing

Current state:
- ✅ **Built successfully**: libjpeg-turbo, libpng, libgif, bzip2, brotli, expat, harfbuzz
- 🔄 **Ready to rebuild**: gettext, glib, cairo, fontconfig, poppler, fontforge, pdf2htmlEX
- ✅ **Fixed blockers**: Framework linker errors, config.sub download, patch management

## Critical Issues Analysis

### 1. Framework Linker Error (HIGHEST PRIORITY)
**Problem**: Malformed framework arguments in linker commands
- Cairo and other deps generate `-framework ApplicationServices` in .pc files
- Linker expects `-Wl,-framework,ApplicationServices` format
- Build fails with "no such file or directory: 'ApplicationServices'"

**Solution**:
- Add post-install sed fix to convert framework arguments in all .pc files
- Apply after each dependency installation that generates .pc files
- Pattern: `s/-framework \([^ ]*\)/-Wl,-framework,\1/g`

### 2. Architecture Mismatch Issues
**Problem**: Mixed architectures causing symbol resolution failures
- Some dependencies built as x86_64 only (fontconfig)
- Homebrew dependencies may be single-arch
- Universal binary creation failing

**Solution**:
- Force all dependencies to build universal binaries
- Enable per-arch builds for problematic deps (fontconfig, glib)
- Verify each static library with `lipo -info` before proceeding
- Use vendored dependencies exclusively, no Homebrew runtime deps

### 3. FontConfig Build Failure
**Problem**: config.sub download and architecture issues
- Curl command syntax error in config.sub update
- FontConfig not building for arm64
- Missing symbols when linking Poppler

**Solution**:
- Fix curl command: `curl -fsSL -o config.sub "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub"`
- Enable universal build for fontconfig
- Build per-arch and merge with lipo if needed

### 4. Patch Management Issues
**Problem**: Patches being applied multiple times
- Build script doesn't track which patches have been applied
- Interactive patch prompts breaking automated builds

**Solution**:
- Add patch tracking mechanism
- Use `patch -N` to skip already applied patches
- Create marker files to track patch application state

## Immediate Action Plan

### Phase 1: Fix Critical Build Infrastructure (✅ COMPLETED)
1. **Fixed framework linker arguments** ✅
   - Added `fix_framework_args()` function to fix all .pc files
   - Applied after glib, fontconfig, cairo, and poppler installations
   
2. **Fixed fontconfig build** ✅
   - Corrected curl command URL format for config.sub
   - Verified universal binary build already enabled
   - Per-architecture build with lipo merge in place
   
3. **Implemented patch tracking** ✅
   - Added `apply_patch_once()` function
   - Creates `.patch_*_applied` marker files
   - Non-interactive patch application

4. **Verified build settings** ✅
   - Poppler already has `-DBUILD_TESTS=OFF`
   - Non-essential features already disabled
   - Focus on core functionality maintained

### Phase 2: Systematic Dependency Build
1. **Build order with fixes**:
   - ✅ Already built: libjpeg-turbo, libpng, libgif, bzip2, brotli, expat, harfbuzz
   - 🔧 Fix and build: gettext, glib (with fixed headers)
   - 🔧 Fix and build: fontconfig (universal)
   - 🔧 Fix and build: cairo (with framework fix)
   - 🔧 Build: lcms2, freetype, pixman
   - 🔧 Build: poppler (with all fixes)
   - 🔧 Build: fontforge
   - 🎯 Build: pdf2htmlEX

2. **Verification after each step**:
   - Check static libraries exist
   - Verify architectures with `lipo -info`
   - Test pkg-config files are valid

### Phase 3: Final Build and Testing
1. **Build pdf2htmlEX**
   - Apply comprehensive Poppler 24 API patch
   - Link against all vendored static libraries
   - Create universal binary

2. **Validate final binary**
   - Test on both x86_64 and arm64 Macs
   - Verify no dynamic library dependencies (except system)
   - Test PDF conversion functionality

## Technical Implementation Details

### Framework Fix Implementation
```bash
# Add after each dependency installation
find "${STAGING_DIR}/lib/pkgconfig" -name "*.pc" -exec sed -i.bak \
  's/-framework \([^ ]*\)/-Wl,-framework,\1/g' {} \;
```

### FontConfig Universal Build
```bash
# Build per-arch then merge
for arch in x86_64 arm64; do
  ./configure --prefix="${STAGING_DIR}" \
    --enable-static --disable-shared \
    --build="${arch}-apple-darwin" \
    CFLAGS="-arch ${arch}"
  make clean && make && make install-arch-${arch}
done
# Merge with lipo
```

### Patch Tracking
```bash
# Before applying patch
PATCH_MARKER="${SRC_DIR}/.patch_${PATCH_NAME}_applied"
if [[ ! -f "${PATCH_MARKER}" ]]; then
  patch -p1 -N < "${PATCH_FILE}"
  touch "${PATCH_MARKER}"
fi
```

## Success Metrics
1. **All dependencies build without errors**
2. **pdf2htmlEX compiles and links successfully**
3. **Universal binary verified with `lipo -info`**
4. **Test conversions work on both architectures**
5. **No Homebrew runtime dependencies**

## Risk Mitigation
1. **Keep detailed logs** of each build step
2. **Test incrementally** after each fix
3. **Have rollback strategy** if changes break working parts
4. **Document all workarounds** for future reference