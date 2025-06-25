# pdf2htmlEX Homebrew Formula for macOS

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![macOS](https://img.shields.io/badge/macOS-11%2B-green.svg)](https://www.apple.com/macos/)
[![Homebrew](https://img.shields.io/badge/Homebrew-4.0%2B-orange.svg)](https://brew.sh)
[![pdf2htmlEX](https://img.shields.io/badge/pdf2htmlEX-0.18.8.rc1-red.svg)](https://github.com/pdf2htmlEX/pdf2htmlEX)
[![CI Status](https://img.shields.io/badge/CI-Ready-brightgreen.svg)](.github/workflows/test.yml)

## TL;DR - Quick Install

### Option 1: Clone and Install Locally (Recommended)
```bash
# Clone the repository
git clone https://github.com/twardoch/pdf2htmlEX.git
cd pdf2htmlEX

# Install from local formula
brew install --build-from-source Formula/pdf2htmlex.rb

# Basic usage
pdf2htmlEX input.pdf output.html

# Advanced usage with options
pdf2htmlEX --zoom 1.5 --embed-css 1 --split-pages 1 input.pdf
```

### Option 2: Create a Local Tap
```bash
# Create a local tap
brew tap-new $USER/pdf2htmlex
cd $(brew --repository)/Library/Taps/$USER/homebrew-pdf2htmlex

# Download the formula
curl -L https://raw.githubusercontent.com/twardoch/pdf2htmlEX/main/Formula/pdf2htmlex.rb \
  -o Formula/pdf2htmlex.rb

# Install from your tap
brew install $USER/pdf2htmlex/pdf2htmlex
```

### Option 3: Direct Formula Download
```bash
# Download the formula to a local directory
mkdir -p /tmp/pdf2htmlex
curl -L https://raw.githubusercontent.com/twardoch/pdf2htmlEX/main/Formula/pdf2htmlex.rb \
  -o /tmp/pdf2htmlex/pdf2htmlex.rb

# Install from the local file
brew install --build-from-source /tmp/pdf2htmlex/pdf2htmlex.rb
```

**Note:** Installation will take 10-15 minutes as it builds from source with specific dependency versions.

## Project Overview

This repository hosts a modern, maintained Homebrew formula for [pdf2htmlEX](https://github.com/pdf2htmlEX/pdf2htmlEX) that enables macOS users to install and use this powerful PDF-to-HTML conversion tool. The official Homebrew formula was removed in 2018 due to build failures, leaving macOS users without a straightforward installation path.

### Why This Project Exists

pdf2htmlEX has unique requirements that make it challenging to build on macOS:
- It requires **specific versions** of Poppler and FontForge libraries
- It uses internal APIs from these libraries that aren't exposed in standard builds
- The build process requires static linking to avoid version conflicts
- Modern macOS requires universal binaries (x86_64 + arm64) for optimal compatibility

This repository solves these challenges by providing:
- A carefully crafted Homebrew formula with vendored dependencies
- Build scripts that ensure compatibility with both Intel and Apple Silicon Macs
- Continuous integration to track upstream changes
- Clear documentation for contributors and users

## Development and Future Plans

For details on how to contribute to this project, please see our [Contribution Guidelines](CONTRIBUTING.md).

Future development plans, including repository reorganization and potential improvements, are outlined in our [Project Roadmap](ROADMAP.md).

## Security Policy

Security issues should be reported privately via email. Do not create public issues for security vulnerabilities. We aim to respond within 48 hours and provide fixes within 7 days for critical issues.

## License

This Homebrew formula is released under the same license as Homebrew (BSD 2-Clause). pdf2htmlEX itself is licensed under GPLv3.

---

*This project is not officially affiliated with the pdf2htmlEX project but aims to support the macOS community in using this excellent tool.*