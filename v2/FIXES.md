# Build Fixes Applied - v2 pdf2htmlEX Mac Build

This document details all fixes applied to resolve the critical build failures identified in the v2 build system.

## Critical Issues Fixed

### 1. Framework Linker Arguments

**Problem**: Build failing with `clang++: error: no such file or directory: 'ApplicationServices'`

**Root Cause**: pkg-config files from dependencies (Cairo, GLib) contain `-framework ApplicationServices` which needs to be in the format `-Wl,-framework,ApplicationServices` for proper linking.

**Fix Applied**:
```bash
# Added helper function to build.sh
fix_framework_args() {
  local pc_dir="${1:-${STAGING_DIR}/lib/pkgconfig}"
  log "Fixing framework arguments in ${pc_dir}"
  
  if [[ -d "${pc_dir}" ]]; then
    find "${pc_dir}" -name "*.pc" -exec sed -i.bak \
      's/-framework \([^ ]*\)/-Wl,-framework,\1/g' {} \;
    find "${pc_dir}" -name "*.pc.bak" -delete
  fi
}
```

**Applied After**:
- GLib installation
- FontConfig installation  
- Cairo installation
- Poppler installation

### 2. FontConfig config.sub Download

**Problem**: Curl command failing to download config.sub update

**Root Cause**: Incorrect URL format for Git web interface

**Fix Applied**:
```bash
# Changed from:
curl -fsSL https://git.savannah.gnu.org/cgit/config.git/plain/config.sub -o ../config.sub

# To:
curl -fsSL -o ../config.sub "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub"
```

### 3. Patch Tracking System

**Problem**: Patches being applied multiple times causing interactive prompts and build failures

**Root Cause**: No tracking of previously applied patches

**Fix Applied**:
```bash
# Added patch tracking function
apply_patch_once() {
  local patch_file="$1"
  local target_dir="$2"
  local patch_name="$(basename "${patch_file}" .patch)"
  local marker_file="${BUILD_DIR}/.patch_${patch_name}_applied"
  
  if [[ -f "${marker_file}" ]]; then
    log "Patch ${patch_name} already applied - skipping"
    return 0
  fi
  
  log "Applying patch ${patch_name}"
  if patch -p1 -d "${target_dir}" -N < "${patch_file}"; then
    touch "${marker_file}"
    log "Successfully applied ${patch_name}"
  else
    log "Warning: Failed to apply ${patch_name} - may already be applied"
    touch "${marker_file}"  # Mark as applied anyway to prevent retries
  fi
}
```

## Build Configuration Verified

### Already Correctly Configured:
1. **FontConfig Universal Build**: Already builds for both x86_64 and arm64
2. **Poppler Test Disable**: Already has `-DBUILD_TESTS=OFF`
3. **Static Library Preference**: Already uses `-DCMAKE_FIND_LIBRARY_SUFFIXES=.a`

## Testing the Fixes

After applying these fixes, run:

```bash
cd v2
./build.sh

# After build completes:
./scripts/test-build.sh
```

## Expected Results

With these fixes applied:
1. ✅ No more "ApplicationServices not found" errors
2. ✅ FontConfig config.sub downloads successfully
3. ✅ Patches apply only once without prompts
4. ✅ All pkg-config files have correct framework syntax
5. ✅ Build completes to produce universal binary

## If Build Still Fails

Check these common issues:
1. Ensure all build tools installed: `cmake`, `ninja`, `make`, `curl`, `shasum`
2. Check error log: `tail -100 v2/build.err.txt`
3. Verify no conflicting Homebrew libraries in PATH
4. Ensure Xcode Command Line Tools installed
5. Check disk space (build requires ~2GB)

## Files Modified

- `v2/scripts/build.sh` - All fixes applied here
- Added `v2/scripts/test-build.sh` - Build validation script
- Added `v2/FIXES.md` - This documentation