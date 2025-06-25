# Project Roadmap: pdf2htmlEX Homebrew Formula

This document outlines future plans for enhancing the pdf2htmlEX Homebrew formula and its surrounding infrastructure. These are ideas for development beyond the initial MVP v1.0.

## Repository Reorganization Plan

### Current Structure Issues
The current repository structure mixes reference documentation, prototype scripts, and the actual formula. This needs to be reorganized for clarity and maintainability.

### Proposed Structure

```
pdf2htmlex-homebrew/
├── Formula/
│   └── pdf2htmlex.rb          # The main Homebrew formula
├── patches/                   # macOS-specific patches for dependencies
│   ├── poppler/
│   │   └── *.patch
│   └── fontforge/
│       └── *.patch
├── scripts/                   # Development and maintenance scripts
│   ├── update-versions.rb     # Script to check for new versions
│   ├── test-build.sh         # Local build testing script
│   ├── bottle.sh             # Bottle creation helper
│   └── ci-matrix.sh          # CI test matrix runner
├── test/                     # Test PDFs and validation scripts
│   ├── fixtures/
│   │   ├── simple.pdf
│   │   ├── complex.pdf
│   │   └── unicode.pdf
│   └── validate.rb           # Comprehensive test suite
├── docs/                     # Detailed documentation
│   ├── BUILD.md             # Build process details
│   ├── TROUBLESHOOTING.md   # Common issues and solutions
│   ├── DEPENDENCIES.md      # Dependency version tracking
│   └── DEVELOPMENT.md       # Development workflow
├── .github/
│   ├── workflows/
│   │   ├── test.yml         # PR testing workflow
│   │   ├── bottle.yml       # Bottle building workflow
│   │   └── update.yml       # Dependency update checker
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── build_failure.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

### Implementation Steps

1. **Phase 1: Core Structure** (Week 1)
   - Move `pdf2htmlex.rb` to `Formula/` directory
   - Create the directory structure above
   - Move reference materials to `docs/`
   - Remove prototype scripts (keep refined versions in `scripts/`)

2. **Phase 2: Testing Infrastructure** (Week 2)
   - Develop comprehensive test suite in `test/`
   - Add diverse PDF fixtures covering edge cases
   - Create automated validation scripts
   - Set up local testing harness

3. **Phase 3: CI/CD Pipeline** (Week 3)
   - Implement GitHub Actions workflows
   - Set up matrix testing (macOS versions × architectures)
   - Automate bottle building and hosting
   - Add dependency update monitoring

4. **Phase 4: Documentation** (Week 4)
   - Write comprehensive build documentation
   - Create troubleshooting guide
   - Document development workflow
   - Add inline code documentation

## Improvement Notes

### Technical Improvements

1. **Dependency Management**
   - Implement SHA256 verification for all resources
   - Create a dependency lockfile mechanism
   - Add version compatibility matrix
   - Automate security vulnerability scanning

2. **Build Optimization**
   - Use ccache for faster rebuilds
   - Implement parallel build where possible
   - Optimize CMake flags for size/performance
   - Add build caching in CI

3. **Universal Binary Support**
   - Ensure all dependencies build as universal
   - Implement automatic architecture detection
   - Add Rosetta 2 compatibility testing
   - Optimize for both architectures

4. **Testing Enhancements**
   - Add performance benchmarks
   - Implement visual regression testing
   - Test with various PDF specifications
   - Add memory leak detection

### User Experience Improvements

1. **Installation**
   - Add progress indicators during build
   - Provide pre-built bottles for common configurations
   - Implement rollback mechanism
   - Add installation verification

2. **Documentation**
   - Create video tutorials
   - Add FAQ section
   - Provide migration guide from other tools
   - Include real-world examples

3. **Error Handling**
   - Implement detailed error messages
   - Add automatic diagnostic collection
   - Provide solution suggestions
   - Create error recovery mechanisms
```
