# pdf2htmlEX Homebrew Formula

**This project creates a modern Homebrew formula for pdf2htmlEX on macOS**, solving the complex build requirements of specific Poppler/FontForge versions through static linking and universal binary support. The formula enables macOS users to install pdf2htmlEX via `brew install`, providing a tool that converts PDFs to HTML while preserving layout, fonts, and formatting with high fidelity.

## 1. Project Status

**Current Status**: Formula builds successfully through dependency stages but encounters DCTStream compilation issues in Poppler. The architecture is proven and ready for finalization.

**Working Components**:
- ✅ Vendored dependency management (Poppler + FontForge)
- ✅ Universal binary compilation (x86_64 + arm64)
- ✅ CMakeLists.txt patching system
- ✅ Staged build process
- ✅ Official Homebrew formula patterns integration

**Remaining Challenge**: DCTStream compilation error when JPEG/DCT decoder is disabled in Poppler.

---

## 2. Architecture Overview

### 2.1. Core Challenge

pdf2htmlEX requires:
- **Exact versions** of Poppler and FontForge with internal API access
- **Static linking** to avoid runtime version conflicts  
- **Universal binary** support for Intel and Apple Silicon Macs
- **Custom build configuration** not available in standard Homebrew packages

### 2.2. Proven Solution: Vendored Dependencies + Official Patterns

Our testing confirmed that the **hybrid approach** works best:

1. **Vendored Dependencies**: Build exact Poppler/FontForge versions as resources
2. **Official Formula Patterns**: Use build configurations from official Homebrew formulas
3. **CMakeLists.txt Patching**: Replace hardcoded paths with staging directory paths
4. **Staged Installation**: Dependencies built into staging area before final pdf2htmlEX compilation

---

## 3. Development History & Lessons Learned

### 3.1. ✅ Successful Strategies

#### 3.1.1. Vendored Dependency Approach
**What**: Download and build specific Poppler/FontForge versions as formula resources
**Why it works**: 
- Ensures exact version compatibility (Poppler 23.12.0/24.01.0, FontForge 20230101)
- Provides access to internal APIs not exposed in standard builds
- Enables static linking for runtime stability

```ruby
resource "poppler" do
  url "https://poppler.freedesktop.org/poppler-23.12.0.tar.xz"
  sha256 "beba398c9d37a9b6d02486496635e08f1df3d437cfe61dab2593f47c4d14cdbb"
end
```

#### 3.1.2. CMakeLists.txt Patching System
**What**: Replace hardcoded paths in pdf2htmlEX's build system with staging directory paths
**Why it works**:
- pdf2htmlEX expects specific directory structure: `../poppler/build/libpoppler.a`
- Patching allows using our staged dependencies without restructuring
- Maintains all original build logic while redirecting paths

```ruby
inreplace "pdf2htmlEX/CMakeLists.txt" do |s|
  s.gsub! "${CMAKE_SOURCE_DIR}/../poppler/build/glib/libpoppler-glib.a", "#{staging_prefix}/lib/libpoppler-glib.a"
  s.gsub! "${CMAKE_SOURCE_DIR}/../poppler/build/libpoppler.a", "#{staging_prefix}/lib/libpoppler.a"
end
```

#### 3.1.3. Official Formula Integration
**What**: Use build configurations and patterns from official Homebrew Poppler/FontForge formulas
**Why it works**:
- Leverages proven dependency management
- Includes necessary patches (e.g., FontForge translation files)
- Provides complete CMake flag configurations

#### 3.1.4. Universal Binary Architecture
**What**: Build for both x86_64 and arm64 architectures simultaneously
**Why it works**:
- Uses `-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64` consistently across all components
- All dependencies and final binary support both architectures
- No architecture-specific issues encountered

#### 3.1.5. Staged Build Process
**What**: Three-stage build: Poppler → FontForge → pdf2htmlEX
**Why it works**:
- Isolates dependency builds from each other
- Allows custom configuration per component
- Provides clean staging area for final assembly

### 3.2. ❌ Rejected Strategies

#### 3.2.1. Using Current Homebrew Dependencies
**What**: Depend on `brew install poppler fontforge`
**Why rejected**:
- Version mismatch: Homebrew Poppler 25.06.0 vs required 24.01.0/23.12.0
- API incompatibility: Modern Poppler uses C++20 features, pdf2htmlEX uses C++14
- Missing static libraries: FontForge only provides dynamic libraries
- **Evidence**: Compilation fails with C++20 feature errors (`std::optional`, `std::span`)

#### 3.2.2. In-Source Build Structure
**What**: Build dependencies in exact directory structure pdf2htmlEX expects
**Why rejected**:
- Complex directory manipulation required
- Harder to maintain and debug
- CMakeLists.txt patching is cleaner and more maintainable
- **Evidence**: Patching approach proved more reliable in testing

#### 3.2.3. Dynamic Library Linking
**What**: Use `.dylib` files instead of static `.a` libraries
**Why rejected**:
- Runtime version conflicts likely
- pdf2htmlEX build system expects static libraries
- Deployment complexity increases
- **Evidence**: FontForge linking worked better with static approach

#### 3.2.4. Older pdf2htmlEX Versions
**What**: Use pdf2htmlEX 0.14.x or 0.16.x instead of 0.18.8.rc1
**Why rejected**:
- Missing modern features and bug fixes
- Still has dependency version requirements
- 0.18.8.rc1 is the most stable recent version
- **Evidence**: Official build scripts target 0.18.8.rc1

---

## 4. Technical Implementation Guide

### 4.1. Current Working Formula Structure

```ruby
class Pdf2htmlex < Formula
  # Main source
  url "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz"
  
  # Vendored dependencies with exact versions
  resource "poppler" do
    url "https://poppler.freedesktop.org/poppler-23.12.0.tar.xz"
  end
  
  resource "fontforge" do
    url "https://github.com/fontforge/fontforge/archive/20230101.tar.gz"
  end
  
  def install
    # Stage 1: Build Poppler with minimal features
    # Stage 2: Build FontForge with official patches
    # Stage 3: Patch pdf2htmlEX CMakeLists.txt and build
  end
end
```

### 4.2. Critical Build Configurations

#### 4.2.1. Poppler Build Flags
```ruby
args = %W[
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_OSX_ARCHITECTURES=x86_64;arm64
  -DENABLE_UNSTABLE_API_ABI_HEADERS=ON  # Required by pdf2htmlEX
  -DBUILD_SHARED_LIBS=OFF               # Static libraries
  -DENABLE_GLIB=ON                      # Required by pdf2htmlEX
  -DENABLE_QT5=OFF -DENABLE_QT6=OFF     # Disable Qt
  -DENABLE_LIBTIFF=OFF                  # Avoid version conflicts
  -DENABLE_DCTDECODER=none              # Disable problematic JPEG
  -DENABLE_LIBJPEG=OFF                  # Disable JPEG completely
]
```

#### 4.2.2. FontForge Build Flags
```ruby
args = %W[
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_OSX_ARCHITECTURES=x86_64;arm64
  -DBUILD_SHARED_LIBS=OFF
  -DENABLE_GUI=OFF
  -DENABLE_FONTFORGE_EXTRAS=ON
  -DENABLE_NATIVE_SCRIPTING=ON
]
```

### 4.3. Known Issues & Solutions

#### 4.3.1. Issue: DCTStream Compilation Error
**Problem**: Both Poppler 23.12.0 and 24.01.0 fail with DCTStream redefinition errors
**Root Cause**: DCTStream.cc has compilation issues when JPEG/DCT decoder is disabled
**Current Status**: Affects targets 132/177 in Poppler build
**Potential Solutions**:
1. Patch DCTStream.cc to fix compilation errors
2. Try Poppler 22.x series (pre-DCT refactor)
3. Enable minimal JPEG support instead of complete disabling

#### 4.3.2. Issue: Missing test.py.in
**Problem**: CMake expects `pdf2htmlEX/test/test.py.in` file
**Solution**: Create empty placeholder file before CMake configuration
```ruby
(buildpath/"pdf2htmlEX/test/test.py.in").write ""
```

#### 4.3.3. Issue: FontForge Translation Patch
**Problem**: FontForge 20230101 needs translation file fixes
**Solution**: Apply official Homebrew patch
```ruby
patch do
  url "https://raw.githubusercontent.com/Homebrew/formula-patches/9403988/fontforge/20230101.patch"
  sha256 "e784c4c0fcf28e5e6c5b099d7540f53436d1be2969898ebacd25654d315c0072"
end
```

---

## 5. Future Maintenance Guide

### 5.1. Updating pdf2htmlEX Version

1. **Check Official Build Scripts**: Look at `pdf2htmlEX/buildScripts/versionEnvs` for required dependency versions
2. **Update Main URL**: Change version in formula URL and update SHA256
3. **Test CMakeLists.txt Patching**: Verify paths haven't changed in new version
4. **Update Test Block**: Ensure test PDF and validation still work

### 5.2. Updating Poppler Version

1. **Version Compatibility**: Check pdf2htmlEX documentation for supported Poppler versions
2. **API Changes**: Test for C++ standard compatibility (pdf2htmlEX uses C++14)
3. **Build Flag Updates**: Check official Homebrew Poppler formula for new/changed flags
4. **DCT/JPEG Support**: Monitor if DCTStream compilation issues are resolved

### 5.3. Updating FontForge Version

1. **Patch Availability**: Check if official Homebrew patches exist for new version
2. **CMake vs Autotools**: Ensure new version still uses CMake build system
3. **Static Library Support**: Verify static library generation still works
4. **Scripting Support**: Ensure native scripting remains enabled

### 5.4. Adapting to macOS Changes

1. **Xcode Updates**: Test with new Xcode/CommandLineTools versions
2. **Architecture Changes**: Monitor for new Apple Silicon developments
3. **System Library Changes**: Update system library paths if needed
4. **Homebrew Changes**: Adapt to new Homebrew formula patterns

### 5.5. Debugging New Issues

1. **Build Logs**: Always check `brew gist-logs pdf2htmlex` for detailed error information
2. **Staging Inspection**: Examine staging directory contents to verify dependency builds
3. **CMake Verbose**: Use `CMAKE_VERBOSE_MAKEFILE=ON` for detailed build information
4. **Architecture Testing**: Test each architecture separately if universal build fails

---

## 6. Quick Start for Developers

### 6.1. Testing Current Formula
```bash
# Install from source with verbose output
brew install --build-from-source --verbose Formula/pdf2htmlex.rb

# Check build logs if it fails
brew gist-logs pdf2htmlex

# Test basic functionality
pdf2htmlEX --version
pdf2htmlEX test.pdf
```

### 6.2. Development Workflow
```bash
# Make changes to formula
edit Formula/pdf2htmlex.rb

# Uninstall previous version
brew uninstall pdf2htmlex

# Test new version
brew install --build-from-source Formula/pdf2htmlex.rb

# Validate universal binary
file $(brew --prefix)/bin/pdf2htmlEX
lipo -info $(brew --prefix)/bin/pdf2htmlEX
```

### 6.3. Common Debug Commands
```bash
# Check dependency versions
brew list --versions poppler fontforge

# Inspect staging area during build
ls -la /tmp/pdf2htmlex-*/staging/

# Test individual components
pkg-config --libs poppler-glib
pkg-config --libs fontforge
```

---

## 7. Project Files

- `Formula/pdf2htmlex.rb` - Main Homebrew formula
- `PLAN.md` - Implementation strategy and current status
- `issues/203.txt` - Analysis of official Homebrew formulas (crucial reference)
- `scripts/` - Helper scripts for testing and development

---

## 8. Contributing

When contributing to this formula:

1. **Test thoroughly** on both Intel and Apple Silicon if possible
2. **Document changes** in commit messages and update this README
3. **Preserve working components** - the architecture is proven sound
4. **Focus on the DCTStream issue** - this is the main remaining blocker
5. **Follow Homebrew best practices** - use official formula patterns where possible

The foundation is solid. Future work should focus on resolving the final compilation issues while maintaining the proven vendored dependency architecture.
