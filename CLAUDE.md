  

# pdf2htmlEX Homebrew Formula

**This project creates a modern Homebrew formula for pdf2htmlEX on macOS**, solving the complex build requirements of specific Poppler/FontForge versions through static linking and universal binary support. The formula enables macOS users to install pdf2htmlEX via `brew install`, providing a tool that converts PDFs to HTML while preserving layout, fonts, and formatting with high fidelity.

---

## Project Context & Architecture

### Core Challenge

pdf2htmlEX requires:

- **Exact versions** of Poppler (24.01.0) and FontForge (20230101)
- Access to **internal APIs** not exposed in standard builds
- **Static linking** to avoid runtime version conflicts
- **Universal binary** support for Intel and Apple Silicon Macs

### Solution Architecture

1. **Vendored Dependencies**: The formula downloads and builds specific Poppler/FontForge versions as resources
2. **Static Compilation**: All dependencies are built as static libraries and linked into the final binary
3. **Universal Build**: Uses `CMAKE_OSX_ARCHITECTURES="x86_64;arm64"` for dual-architecture support
4. **Staged Installation**: Dependencies are built into a staging area before final pdf2htmlEX compilation

### Repository Structure

```
pdf2htmlEX/
├── Formula/
│   └── pdf2htmlex.rb      # The Homebrew formula
├── build_prototype.sh     # Build testing script
├── reference/            # Documentation and notes
└── README.md            # User-facing documentation
```

---

## Development Workflow

### Initial Setup

1. **Clone and Navigate**

   ```bash
   git clone https://github.com/twardoch/pdf2htmlEX
   cd pdf2htmlEX
   ```

2. **Install Build Dependencies**

   ```bash
   brew install cmake ninja pkg-config
   brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz
   brew install openjdk  # For JavaScript/CSS minification
   ```

3. **Test the Formula Locally**
   ```bash
   brew install --build-from-source --verbose --debug Formula/pdf2htmlex.rb
   ```

### Making Changes

#### Modifying the Formula

1. **Edit `Formula/pdf2htmlex.rb`**

   - Update version numbers in the formula header
   - Modify resource URLs/checksums if updating dependencies
   - Adjust CMake flags in the `install` method
   - Update the `test` block for new functionality

2. **Test Your Changes**

   ```bash
   # Uninstall existing version
   brew uninstall pdf2htmlex

   # Reinstall from source
   brew install --build-from-source Formula/pdf2htmlex.rb

   # Run the test block
   brew test pdf2htmlex

   # Run audit
   brew audit --strict Formula/pdf2htmlex.rb
   ```

3. **Verify Universal Binary**
   ```bash
   file $(brew --prefix)/bin/pdf2htmlEX
   lipo -info $(brew --prefix)/bin/pdf2htmlEX
   ```

#### Updating Dependencies

1. **Check Upstream Versions**

   - pdf2htmlEX: https://github.com/pdf2htmlEX/pdf2htmlEX/releases
   - Poppler: https://poppler.freedesktop.org/
   - FontForge: https://github.com/fontforge/fontforge/releases

2. **Update Resource Blocks**

   ```ruby
   resource "poppler" do
     url "https://poppler.freedesktop.org/poppler-XX.YY.Z.tar.xz"
     sha256 "NEW_SHA256_HERE"
   end
   ```

3. **Test Compatibility**
   - Build with new versions
   - Run comprehensive tests
   - Check for API breakage

### Build Process Deep Dive

#### Stage 1: Poppler Build

The formula builds Poppler with:

- Minimal features (no Qt, no utils, no tests)
- Static libraries only (`-DBUILD_SHARED_LIBS=OFF`)
- Cairo backend enabled for rendering
- JPEG and PNG support for images

Critical flags:

```cmake
-DENABLE_UNSTABLE_API_ABI_HEADERS=OFF  # Stability
-DENABLE_SPLASH=ON                     # Required by pdf2htmlEX
-DENABLE_GLIB=ON                       # Required by pdf2htmlEX
-DENABLE_UTILS=OFF                     # Not needed
-DBUILD_SHARED_LIBS=OFF                # Static only
```

#### Stage 2: FontForge Build

FontForge is built without GUI:

- Command-line utilities only (`-DENABLE_GUI=OFF`)
- Native scripting enabled (`-DENABLE_NATIVE_SCRIPTING=ON`)
- No Python bindings (simplifies build)
- Static libraries only

Critical flags:

```cmake
-DENABLE_GUI=OFF                       # No GUI needed
-DENABLE_NATIVE_SCRIPTING=ON           # Required by pdf2htmlEX
-DENABLE_PYTHON_SCRIPTING=OFF          # Simplifies build
-DBUILD_SHARED_LIBS=OFF                # Static only
```

#### Stage 3: pdf2htmlEX Build

Final compilation with:

- Links against staged Poppler/FontForge
- Universal binary support
- Finds dependencies via `CMAKE_PREFIX_PATH`
- Installs to Homebrew prefix

### Testing Guidelines

#### Basic Functionality Test

```bash
# Create test PDF
cat > test.pdf << 'EOF'
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj
4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
5 0 obj<</Length 44>>stream
BT /F1 24 Tf 100 700 Td (Hello World!) Tj ET
endstream
endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000052 00000 n
0000000101 00000 n
0000000229 00000 n
0000000299 00000 n
trailer<</Size 6/Root 1 0 R>>
startxref
398
%%EOF
EOF

# Convert to HTML
pdf2htmlEX test.pdf

# Verify output
grep -q "Hello World!" test.html && echo "Test passed!"
```

#### Comprehensive Testing

```bash
# Test with various PDF features
pdf2htmlEX --zoom 1.5 --embed-css 0 complex.pdf
pdf2htmlEX --split-pages 1 multipage.pdf
pdf2htmlEX --process-outline 1 --embed-font 1 formatted.pdf
```

#### Architecture Testing

```bash
# On Apple Silicon, test both architectures
arch -x86_64 pdf2htmlEX --version
arch -arm64 pdf2htmlEX --version
```

### Debugging Build Issues

#### Common Problems and Solutions

1. **Poppler Build Fails**

   - Check Cairo/Freetype versions: `brew list --versions cairo freetype`
   - Ensure pkg-config finds dependencies: `pkg-config --libs poppler-glib`
   - Look for missing headers in build logs

2. **FontForge Build Fails**

   - Verify libxml2 is installed: `brew list libxml2`
   - Check for conflicting Python installations
   - Disable more features if needed

3. **Linking Errors**

   - Verify static libraries exist: `find staging -name "*.a"`
   - Check CMAKE_PREFIX_PATH is set correctly
   - Use `otool -L` to inspect dynamic dependencies

4. **Universal Binary Issues**
   - Some dependencies may not build universal
   - Fall back to separate builds + `lipo -create`
   - Check each stage with `file` command

#### Debug Build

```bash
# Enable verbose output
export VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

# Build with debug symbols
brew install --build-from-source --debug Formula/pdf2htmlex.rb

# Check build logs
brew gist-logs pdf2htmlex
```

### Contributing Changes

#### Before Submitting

1. **Code Quality**

   - Run `brew style --fix Formula/pdf2htmlex.rb`
   - Ensure formula passes `brew audit --strict`
   - Test on clean macOS installation if possible

2. **Testing**

   - Test on both Intel and Apple Silicon if available
   - Verify with multiple PDF types
   - Check output quality and correctness

3. **Documentation**
   - Update inline comments in formula
   - Document any new build flags
   - Update README.md if needed

#### Pull Request Process

1. **Create Feature Branch**

   ```bash
   git checkout -b feature/your-improvement
   ```

2. **Commit with Clear Messages**

   ```bash
   git add Formula/pdf2htmlex.rb
   git commit -m "formula: update Poppler to X.Y.Z

   - Updates Poppler resource to version X.Y.Z
   - Adjusts CMake flags for compatibility
   - Tested on macOS 13 and 14"
   ```

3. **Push and Create PR**
   ```bash
   git push origin feature/your-improvement
   gh pr create --title "Update Poppler to X.Y.Z" --body "..."
   ```

### Maintenance Tasks

#### Weekly Checks

- Monitor upstream pdf2htmlEX for issues/updates
- Check Poppler releases (they release frequently)
- Review formula for deprecation warnings

#### Monthly Updates

- Test formula on latest macOS beta
- Update dependencies if compatible
- Review and update documentation

#### Quarterly Reviews

- Performance profiling of conversions
- Security audit of dependencies
- Major version planning

### Advanced Topics

#### Customizing the Build

1. **Adding New Dependencies**

   ```ruby
   depends_on "new-dep"

   # In cmake_prefix_paths
   Formula["new-dep"].opt_prefix,
   ```

2. **Enabling Additional Features**

   - Research CMake options in pdf2htmlEX source
   - Test thoroughly before enabling
   - Document performance/size impact

3. **Optimization Flags**

   ```ruby
   # For smaller binary
   ENV.append "CXXFLAGS", "-Os"

   # For better performance
   ENV.append "CXXFLAGS", "-O3 -march=native"
   ```

#### Creating Bottles

1. **Build for Bottling**

   ```bash
   brew install --build-bottle Formula/pdf2htmlex.rb
   brew bottle --json --no-rebuild pdf2htmlex
   ```

2. **Upload to GitHub Releases**

   - Create release with version tag
   - Upload bottle files
   - Update formula with bottle block

3. **Bottle Block Format**
   ```ruby
   bottle do
     sha256 cellar: :any, arm64_sonoma: "SHA256_HERE"
     sha256 cellar: :any, arm64_ventura: "SHA256_HERE"
     sha256 cellar: :any, ventura: "SHA256_HERE"
   end
   ```

#### CI/CD Integration

1. **GitHub Actions Workflow**

   ```yaml
   name: Test Formula
   on: [push, pull_request]
   jobs:
     test:
       runs-on: macos-latest
       steps:
         - uses: actions/checkout@v4
         - run: brew install --build-from-source Formula/pdf2htmlex.rb
         - run: brew test pdf2htmlex
         - run: brew audit --strict Formula/pdf2htmlex.rb
   ```

2. **Automated Dependency Updates**
   - Use Dependabot or similar
   - Test updates automatically
   - Create PRs for successful updates

### Performance Optimization

#### Build Time Optimization

- Use `ccache` if available
- Enable parallel builds: `-j$(sysctl -n hw.ncpu)`
- Reuse staging directory between builds

#### Runtime Optimization

- Profile with Instruments.app
- Optimize CMake flags for target use case
- Consider link-time optimization (LTO)

#### Size Optimization

- Strip debug symbols: `strip -S`
- Disable unused features
- Use `-Os` compilation flag

### Security Considerations

1. **Dependency Scanning**

   - Check CVE databases for Poppler/FontForge
   - Monitor security mailing lists
   - Update promptly for security fixes

2. **Build Hardening**

   ```ruby
   ENV.append "CXXFLAGS", "-fstack-protector-strong"
   ENV.append "LDFLAGS", "-Wl,-bind_at_load"
   ```

3. **Runtime Security**
   - Validate PDF inputs
   - Sandbox execution where possible
   - Document security limitations

### Troubleshooting Resources

1. **Build Logs**

   - `brew gist-logs pdf2htmlex`
   - Check `~/Library/Logs/Homebrew/pdf2htmlex/`
   - Enable verbose CMake output

2. **Dependency Issues**

   - `brew doctor`
   - `brew deps --tree pdf2htmlex`
   - `otool -L $(which pdf2htmlEX)`

3. **Community Support**
   - GitHub Issues on this repo
   - Homebrew Discourse
   - pdf2htmlEX upstream issues

---

## Quick Reference

### Essential Commands

```bash
# Install from source
brew install --build-from-source Formula/pdf2htmlex.rb

# Test installation
brew test pdf2htmlex

# Audit formula
brew audit --strict Formula/pdf2htmlex.rb

# Check version
pdf2htmlEX --version

# Basic conversion
pdf2htmlEX input.pdf output.html

# Advanced conversion
pdf2htmlEX --zoom 2 --embed-font 1 --split-pages 1 input.pdf
```

### Key File Locations

- Formula: `Formula/pdf2htmlex.rb`
- Build script: `build_prototype.sh`
- Upstream source: https://github.com/pdf2htmlEX/pdf2htmlEX
- Poppler: https://poppler.freedesktop.org/
- FontForge: https://fontforge.org/

### Version Matrix

| Component  | Version    | Notes                        |
| ---------- | ---------- | ---------------------------- |
| pdf2htmlEX | 0.18.8.rc1 | Latest stable                |
| Poppler    | 24.01.0    | Specific version required    |
| FontForge  | 20230101   | Specific version required    |
| macOS      | 11+        | Big Sur and later            |
| Xcode      | 12+        | For universal binary support |



# main-overview

## Development Guidelines

- Only modify code directly relevant to the specific request. Avoid changing unrelated functionality.
- Never replace code with placeholders like `# ... rest of the processing ...`. Always include complete code.
- Break problems into smaller steps. Think through each step separately before implementing.
- Always provide a complete PLAN with REASONING based on evidence from code and logs before making changes.
- Explain your OBSERVATIONS clearly, then provide REASONING to identify the exact issue. Add console logs when needed to gather more information.


## Core Business Architecture

The pdf2htmlEX Homebrew formula implements a specialized build system for converting PDF documents to HTML while preserving layout and formatting. The core business logic revolves around three critical components:

1. Dependency Version Control (Importance: 95)
- Strict version requirements for Poppler (24.01.0) and FontForge (20230101)
- Static linking to prevent runtime version conflicts
- Managed through vendored resources in the formula

2. Universal Binary Architecture (Importance: 90)
- Cross-architecture compilation support for Intel and Apple Silicon
- Dual-architecture binary generation using CMAKE_OSX_ARCHITECTURES
- Staged build process ensuring architecture compatibility

3. Custom Build Pipeline (Importance: 85)
- Three-stage compilation process:
  1. Poppler with minimal features and Cairo backend
  2. FontForge without GUI and with native scripting
  3. pdf2htmlEX linking against staged dependencies
- Specialized CMake configurations for each component

## Key Business Components

### Dependency Management System (Importance: 90)
`Formula/pdf2htmlex.rb`
- Downloads and builds specific versions of Poppler/FontForge
- Implements static linking to avoid version conflicts
- Manages complex interdependencies between components

### Build Configuration Engine (Importance: 85)
`Formula/pdf2htmlex.rb`
- Configures specialized build flags for each dependency
- Implements staged installation process
- Handles universal binary generation

### Quality Assurance Framework (Importance: 75)
- Automated validation of PDF conversion
- Architecture-specific testing for universal binaries
- Security hardening through build flags

## Integration Points

### Build System Integration (Importance: 80)
- Custom CMake configurations for dependency builds
- Integration with Homebrew's installation system
- Version-specific resource management

### Platform Integration (Importance: 75)
- macOS-specific optimizations and configurations
- Architecture detection and binary generation
- System dependency management
