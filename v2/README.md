# pdf2htmlEX v2

This directory contains the second iteration of the `pdf2htmlEX` Homebrew formula, designed to be robust, maintainable, and future-proof.

## Quick Start

To install `pdf2htmlEX` using this formula:

```bash
# Install from the formula file directly
brew install --build-from-source v2/Formula/pdf2htmlex.rb

# Verify the installation
pdf2htmlEX --version
```

## Local Build and Test

To build and test the formula locally without installing it into Homebrew, use the provided build script:

```bash
# Run the local build script
./v2/scripts/build.sh

# The compiled binary will be available in the `dist/` directory
./dist/bin/pdf2htmlEX --version
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
