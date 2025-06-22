# Changelog

All notable changes to the pdf2htmlEX Homebrew formula project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete project restructuring with organized directory layout
- GitHub Actions workflows for automated testing, releases, and security scanning
  - `test.yml`: Multi-platform testing on macOS 12, 13, and 14
  - `release.yml`: Automated release and bottle building
  - `security.yml`: Weekly security scans and vulnerability checks
- Comprehensive development scripts
  - `scripts/test-formula.sh`: Local formula testing with extensive validation
  - `scripts/update-version.sh`: Automated version updates with SHA256 calculation
  - `scripts/check-dependencies.sh`: Dependency verification and system compatibility checks
- Test infrastructure
  - Integration tests for various pdf2htmlEX options
  - Test fixture creation scripts
  - Organized test directory structure
- Detailed TODO.md with phased implementation plan
- Project documentation improvements

### Changed
- Moved `pdf2htmlex.rb` formula from root to `Formula/` directory (standard Homebrew structure)
- Improved formula organization and structure

### Fixed
- Formula path references in documentation now point to correct location
- SHA256 checksums in formula updated from placeholders to actual values:
  - pdf2htmlEX: `a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641`
  - Poppler: `c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08`
  - FontForge: `ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1`

### Security
- Added automated CVE scanning workflow
- Implemented security audit checks for formula
- Added checks for HTTPS URLs and proper checksums

## [0.1.0] - 2024-01-01

### Added
- Initial Homebrew formula for pdf2htmlEX
- Support for macOS universal binaries (Intel and Apple Silicon)
- Static linking of Poppler 24.01.0 and FontForge 20230101
- Comprehensive build process with three-stage compilation
- Basic documentation in README.md and CLAUDE.md

### Known Issues
- SHA256 checksums in formula need to be updated from placeholders
- Manual bottle building process
- Limited test coverage

[Unreleased]: https://github.com/twardoch/pdf2htmlEX/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/twardoch/pdf2htmlEX/releases/tag/v0.1.0