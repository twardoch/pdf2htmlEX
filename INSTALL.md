# Installation Guide

This guide provides multiple ways to install pdf2htmlEX on macOS with comprehensive build automation, testing, and release management.

## Quick Installation (Recommended)

### Using Homebrew

```bash
# Install from our tap
brew tap twardoch/pdf2htmlex
brew install pdf2htmlex

# Or install directly from the repository
brew install --build-from-source https://raw.githubusercontent.com/twardoch/pdf2htmlEX/main/v2/Formula/pdf2htmlex.rb
```

### Using Pre-built Binaries

1. Go to the [Releases page](https://github.com/twardoch/pdf2htmlEX/releases)
2. Download the appropriate binary for your system:
   - `pdf2htmlEX-X.Y.Z-macos-14-arm64.tar.gz` for Apple Silicon Macs
   - `pdf2htmlEX-X.Y.Z-macos-14-x86_64.tar.gz` for Intel Macs
3. Extract and install:

```bash
# Download (replace X.Y.Z with actual version)
curl -L -O https://github.com/twardoch/pdf2htmlEX/releases/download/vX.Y.Z/pdf2htmlEX-X.Y.Z-macos-14-arm64.tar.gz

# Verify checksum
curl -L -O https://github.com/twardoch/pdf2htmlEX/releases/download/vX.Y.Z/pdf2htmlEX-X.Y.Z-macos-14-arm64.tar.gz.sha256
shasum -a 256 -c pdf2htmlEX-X.Y.Z-macos-14-arm64.tar.gz.sha256

# Extract
tar -xzf pdf2htmlEX-X.Y.Z-macos-14-arm64.tar.gz

# Install (optional - copy to a directory in your PATH)
sudo cp bin/pdf2htmlEX /usr/local/bin/
```

## Building from Source

### Prerequisites

- macOS 12+ with Xcode Command Line Tools
- Homebrew (recommended for dependencies)
- At least 4GB of free disk space
- Internet connection for downloading dependencies

### Quick Build

```bash
# Clone the repository
git clone https://github.com/twardoch/pdf2htmlEX.git
cd pdf2htmlEX

# Build and test
./scripts/build-test-release.sh local
```

### Detailed Build Steps

1. **Install build dependencies:**
```bash
brew install cmake ninja pkg-config
brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz
```

2. **Clone and build:**
```bash
git clone https://github.com/twardoch/pdf2htmlEX.git
cd pdf2htmlEX

# Build for your architecture
./scripts/build-test-release.sh build

# Or build universal binary
ARCHS="x86_64;arm64" ./scripts/build-test-release.sh build
```

3. **Test the build:**
```bash
./scripts/build-test-release.sh test
```

4. **Find your binary:**
```bash
./v2/dist/bin/pdf2htmlEX --version
```

## Development Installation

### Setting up Development Environment

```bash
# Clone the repository
git clone https://github.com/twardoch/pdf2htmlEX.git
cd pdf2htmlEX

# Install development dependencies
brew install cmake ninja pkg-config ccache
brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz

# Set up ccache for faster builds
export CCACHE_DIR=$HOME/.cache/ccache
export CC="ccache clang"
export CXX="ccache clang++"

# Run development workflow
./scripts/build-test-release.sh local
```

### Running Tests

```bash
# Run all tests
./v2/tests/test_runner.sh

# Run specific test suites
./v2/tests/test_runner.sh build version release

# Run with verbose output
./v2/tests/test_runner.sh --verbose

# Run in parallel (experimental)
./v2/tests/test_runner.sh --parallel
```

### Version Management

```bash
# Check current version
./scripts/version.sh current

# Show next version
./scripts/version.sh next patch

# Create a new release (for maintainers)
./scripts/version.sh bump patch
```

## Build Options

### Architecture-Specific Builds

```bash
# Build for Intel only
ARCHS="x86_64" ./scripts/build-test-release.sh build

# Build for Apple Silicon only
ARCHS="arm64" ./scripts/build-test-release.sh build

# Build universal binary (default)
ARCHS="x86_64;arm64" ./scripts/build-test-release.sh build
```

### Clean Builds

```bash
# Clean and rebuild
./scripts/build-test-release.sh --clean build

# Or use environment variable
CLEAN=1 ./scripts/build-test-release.sh build
```

### Parallel Building

```bash
# Enable parallel building
./scripts/build-test-release.sh --parallel build

# Or use environment variable
PARALLEL=1 ./scripts/build-test-release.sh build
```

## Troubleshooting

### Build Issues

1. **Missing dependencies:**
```bash
# Install all required dependencies
brew install cmake ninja pkg-config
brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz
```

2. **Build failures:**
```bash
# Clean and retry
./scripts/build-test-release.sh clean
./scripts/build-test-release.sh build

# Check logs
less v2/build.log.txt
less v2/build.err.txt
```

3. **Test failures:**
```bash
# Run tests with verbose output
./v2/tests/test_runner.sh --verbose

# Run specific failing test
./v2/tests/test_runner.sh build
```

### Runtime Issues

1. **Binary not found:**
```bash
# Check if binary exists
ls -la v2/dist/bin/pdf2htmlEX

# Check architecture
file v2/dist/bin/pdf2htmlEX
lipo -info v2/dist/bin/pdf2htmlEX
```

2. **Permission issues:**
```bash
# Make binary executable
chmod +x v2/dist/bin/pdf2htmlEX

# Or copy to system path
sudo cp v2/dist/bin/pdf2htmlEX /usr/local/bin/
```

3. **Library issues:**
```bash
# Check library dependencies
otool -L v2/dist/bin/pdf2htmlEX
```

### Getting Help

1. **Check existing issues:** [GitHub Issues](https://github.com/twardoch/pdf2htmlEX/issues)
2. **Create a new issue:** Include:
   - macOS version
   - Architecture (Intel/Apple Silicon)
   - Build logs
   - Steps to reproduce

## Advanced Usage

### Custom Build Configuration

You can customize the build by editing `v2/scripts/build.sh`:

- Dependency versions
- Build flags
- Architecture settings
- Installation paths

### CI/CD Integration

The project includes GitHub Actions workflows:

- **CI:** `.github/workflows/ci.yml` - Runs on every push/PR
- **Release:** `.github/workflows/release.yml` - Runs on git tags

### Creating Releases

For maintainers:

```bash
# Create and push a new release
./scripts/version.sh bump minor
# This will:
# 1. Update version numbers
# 2. Create git tag
# 3. Push to remote
# 4. Trigger GitHub Actions
```

## System Requirements

- **macOS:** 12.0 or later
- **Architecture:** x86_64, arm64, or universal
- **Disk Space:** 4GB free space for building
- **Memory:** 4GB RAM recommended for building
- **Network:** Internet connection for downloading dependencies

## License

This project is licensed under the GPL v3 License. See the LICENSE file for details.