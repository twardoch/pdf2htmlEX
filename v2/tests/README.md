# pdf2htmlEX v2 Test Suite

## Overview

This directory contains a comprehensive test suite for the pdf2htmlEX v2 Homebrew formula project. The test suite provides extensive coverage of the build system, formula validation, and binary functionality.

## Test Scripts

### Core Tests (Existing)
- `test_basic.sh` - Basic functionality tests
- `test_integration.sh` - Integration and installation tests  
- `test_fonts.sh` - Font handling tests

### Extended Tests (New)
- `test_build.sh` - Build system validation
- `test_patches.sh` - Patch application testing
- `test_edge_cases.sh` - Edge cases and error handling
- `test_formula.sh` - Homebrew formula validation
- `test_api_fixes.sh` - API compatibility fix scripts
- `test_runner.sh` - Master test runner

## Usage

### Run All Tests
```bash
./test_runner.sh
```

### Run Specific Tests
```bash
./test_runner.sh basic fonts
```

### Run with Options
```bash
./test_runner.sh --verbose --timeout 600
```

## Test Coverage Improvements

The new test suite significantly improves coverage by adding:

- **Build System Testing**: Validates build scripts, environment setup, and dependency management
- **Patch Validation**: Tests patch application, syntax, and compatibility
- **Edge Case Handling**: Tests error conditions, large files, and resource limits
- **Formula Compliance**: Validates Homebrew formula syntax and standards
- **API Fix Scripts**: Tests API compatibility fix scripts and integration

## Prerequisites

- macOS 12.0 or later
- Bash 4.0 or later
- Standard Unix tools

### Optional (for specific tests)
- Homebrew (for formula/integration tests)
- CMake (for build tests)
- Git (for patch tests)

## Test Runner Features

- Multiple output formats (text, JSON, XML)
- Parallel execution support
- Timeout handling
- Detailed reporting
- Continue on failure option
- Comprehensive logging

For detailed usage instructions, run:
```bash
./test_runner.sh --help
```
