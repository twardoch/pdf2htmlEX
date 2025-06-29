# Comprehensive Plan for Resolving FontForge Build Validation Failure

## Problem Analysis

### Issue Summary (from issues/104.txt)
The pdf2htmlEX build process is failing at the FontForge validation stage with:
```
==> ✓ FontForge 20230101 built successfully (20.1s)
Error: Build validation failed: FontForge artifact not found at /private/tmp/pdf2htmlex-20250629-50345-jd868d/pdf2htmlEX-0.18.8.rc1/staging/lib/libfontforge.a
Error: Build failed: FontForge build validation failed
```

### Root Cause Analysis

**Key Finding**: FontForge builds successfully but the static library is not installed to the staging directory.

After analyzing the FontForge codebase in `archive/fontforge/`, I discovered the root cause in `fontforge/CMakeLists.txt` lines 282-289:

```cmake
# No dev package -> no need to install if static
if(BUILD_SHARED_LIBS)
  if(WIN32 OR CYGWIN)
    install(TARGETS fontforge RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
  else()
    install(TARGETS fontforge RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR} LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
  endif()
endif()
```

**The Problem**: When our formula sets `-DBUILD_SHARED_LIBS=OFF`, FontForge:
1. ✅ Builds the static library correctly (`libfontforge.a`)
2. ❌ Does NOT install it due to the conditional install block
3. ❌ Validation fails because `staging/lib/libfontforge.a` doesn't exist

### Build Process Flow Analysis

1. **Stage 1: Poppler** - ✅ Works correctly
2. **Stage 2: FontForge** - ⚠️  Builds but doesn't install static library
3. **Stage 3: pdf2htmlEX** - ❌ Never reached due to validation failure

## Solution Strategy

### Approach 1: Manual Library Copy (Recommended)
Add a step after FontForge's `ninja install` to manually copy the built static library to the staging directory.

**Advantages**:
- Minimal change to existing formula
- No modifications to FontForge's build system
- Clear and straightforward implementation

### Approach 2: Force FontForge Installation (Alternative)
Patch FontForge's CMakeLists.txt to always install the library regardless of `BUILD_SHARED_LIBS`.

**Disadvantages**:
- More complex patching
- Requires maintaining additional patches

## Implementation Plan

### Step 1: Modify Formula to Copy Static Library
In `Formula/pdf2htmlex.rb`, after the FontForge `ninja install` command, add:

```ruby
# Stage 2: Build FontForge
build_with_progress("FontForge 20230101") do
  resource("fontforge").stage do
    mkdir "build" do
      # ... existing cmake and ninja install commands ...
      system "ninja", "install"
      
      # Manual copy of static library since FontForge doesn't install it when BUILD_SHARED_LIBS=OFF
      lib_source = "lib/libfontforge.a"
      lib_dest = "#{staging_prefix}/lib/libfontforge.a"
      
      if File.exist?(lib_source)
        system "mkdir", "-p", "#{staging_prefix}/lib"
        system "cp", lib_source, lib_dest
        ohai "✓ Manually copied libfontforge.a to staging directory"
      else
        onoe "Static library not found at #{lib_source}"
        raise "FontForge static library build failed"
      end
    end
  end
end
```

### Step 2: Validate the Fix
The existing validation should now pass:
```ruby
validate_build_stage("FontForge", staging_prefix/"lib/libfontforge.a")
```

### Step 3: Test Build Process
1. Run `./build.sh` or `brew install --build-from-source Formula/pdf2htmlex.rb`
2. Verify FontForge stage completes successfully
3. Verify pdf2htmlEX stage begins and completes
4. Validate final binary functionality

## Expected Outcomes

### Build Log Changes
- FontForge build should show: `✓ Manually copied libfontforge.a to staging directory`
- FontForge validation should show: `✓ FontForge build validated`
- pdf2htmlEX stage should begin successfully

### Success Criteria
1. ✅ FontForge builds and library is copied to staging
2. ✅ FontForge validation passes
3. ✅ pdf2htmlEX builds successfully
4. ✅ Final binary works correctly
5. ✅ All tests pass

## Risk Assessment

### Low Risk
- The manual copy approach is straightforward and safe
- Existing build stages (Poppler) are unaffected
- Change is isolated to FontForge build stage

### Contingency Plans
If manual copy approach fails:
1. **Debug**: Check exact build directory structure
2. **Alternative**: Use `find` command to locate the built library
3. **Fallback**: Implement Approach 2 (patch FontForge CMakeLists.txt)

## Implementation Timeline

1. **Immediate**: Implement the manual copy solution
2. **Validate**: Test build process end-to-end
3. **Document**: Update any relevant documentation
4. **Close**: Mark issue 104.txt as resolved

## Additional Observations

### Why This Wasn't Caught Earlier
- Previous issues (102.txt, 103.txt) were focused on patch application problems
- The build was failing earlier in the process, masking this validation issue
- Issue 104.txt shows the build progressed further, revealing the new problem

### Formula Improvements
This analysis suggests the formula could benefit from:
1. More detailed logging during each build stage
2. Better error messages for build validation failures
3. Cleaner separation between build and validation steps

## Next Steps

1. ✅ **Read issues/104.txt** - Completed
2. ✅ **Consult archive/fontforge/** - Completed, found root cause
3. ✅ **Analyze llms.txt** - Reviewed existing code structure
4. ✅ **Write comprehensive plan** - This document
5. 🔄 **Implement the plan** - Next action
6. 🔄 **Run ./build.sh and analyze** - Next action
7. 🔄 **Iterate until solved** - Next action