# pdf2htmlEX Project Refactoring TODO

## Phase 0: Fix this problem ✓ COMPLETED

~~README.md now suggests doing this but this doesn't work:~~

**RESOLVED:** Updated README.md with three working installation methods:
1. Clone repository and install locally (recommended)
2. Create a local tap using the new `scripts/setup-tap.sh` helper
3. Download formula and install from local file

The error was due to Homebrew's security policy preventing installation from arbitrary URLs. All three methods now work around this limitation.



## Phase 1: Repository Restructuring (Immediate)

### 1.1 Directory Structure Reorganization ✓ COMPLETED
- [x] Create proper directory structure:
  ```
  pdf2htmlEX/
  ├── .github/
  │   ├── workflows/        # CI/CD pipelines ✓
  │   ├── ISSUE_TEMPLATE/   # Issue templates ✓
  │   └── pull_request_template.md ✓
  ├── Formula/
  │   └── pdf2htmlex.rb     # Move from root ✓
  ├── scripts/              # Development and utility scripts ✓
  │   ├── update-version.sh ✓
  │   ├── test-formula.sh ✓
  │   ├── setup-tap.sh     # Added for Phase 0 fix ✓
  │   └── check-dependencies.sh ✓
  ├── tests/
  │   ├── fixtures/         # Test PDFs ✓
  │   ├── integration/      # Full conversion tests ✓
  │   └── unit/            # Component tests ✓
  ├── patches/             # macOS-specific patches ✓
  ├── docs/                ✓
  │   └── refactoring-summary.md ✓
  └── config/              # Build configurations ✓
  ```

### 1.2 Move and Update Files ✓ COMPLETED
- [x] Move `pdf2htmlex.rb` to `Formula/pdf2htmlex.rb` ✓
- [x] Update file paths in documentation ✓
- [x] Verify formula still works after move ✓

## Phase 2: Formula Improvements

### 2.1 Fix Placeholder Values ✓ COMPLETED
- [x] Calculate and add real SHA256 checksums for pdf2htmlEX source ✓
- [x] Verify all resource checksums are correct ✓
- [x] Add version constants at top of formula ✓
  - pdf2htmlEX: `a1d320f155eaffe78e4af88e288ed5e8217e29031acf6698d14623c59a7c5641`
  - Poppler: `c7def693a7a492830f49d497a80cc6b9c85cb57b15e9be2d2d615153b79cae08`
  - FontForge: `ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1`

### 2.2 Build Process Enhancements
- [ ] Add proper error handling with descriptive messages
- [ ] Implement build stage validation
- [ ] Add progress indicators for long operations
- [ ] Cache intermediate build artifacts
- [ ] Add rollback mechanism for failed builds

### 2.3 Testing Improvements
- [ ] Expand test block in formula with comprehensive checks
- [ ] Add multi-architecture validation
- [ ] Test various PDF features (fonts, images, layouts)
- [ ] Add performance benchmarks

## Phase 3: CI/CD Implementation

### 3.1 GitHub Actions Workflows ✓ COMPLETED
- [x] Create `.github/workflows/test.yml` for PR testing ✓
- [x] Create `.github/workflows/release.yml` for releases ✓
- [ ] Create `.github/workflows/bottle.yml` for bottle building (merged into release.yml)
- [x] Create `.github/workflows/security.yml` for vulnerability scanning ✓

### 3.2 Testing Matrix
- [ ] Test on multiple macOS versions (12, 13, 14)
- [ ] Test on both Intel and Apple Silicon
- [ ] Test with various Homebrew configurations
- [ ] Add dependency compatibility testing

### 3.3 Automated Bottle Building
- [ ] Implement bottle creation workflow
- [ ] Set up artifact storage
- [ ] Automate bottle SHA updates in formula
- [ ] Create release automation

## Phase 4: Development Infrastructure

### 4.1 Helper Scripts (Partially Complete)
- [x] `scripts/test-formula.sh` - Local testing helper ✓
- [x] `scripts/update-version.sh` - Version bump automation ✓
- [ ] `scripts/build-bottle.sh` - Local bottle building
- [x] `scripts/check-dependencies.sh` - Dependency verification ✓
- [x] `scripts/setup-tap.sh` - Tap setup helper (added for Phase 0) ✓
- [ ] `scripts/benchmark.sh` - Performance testing

### 4.2 Development Tools (Partially Complete)
- [ ] Add `.editorconfig` for consistent formatting
- [x] Create `Makefile` for common tasks ✓
- [ ] Add pre-commit hooks for validation
- [ ] Create development container configuration

## Phase 5: Testing Suite

### 5.1 Test Fixtures
- [ ] Create diverse PDF test files:
  - [ ] Simple text-only PDF
  - [ ] Complex layout with columns
  - [ ] PDF with embedded fonts
  - [ ] PDF with images and graphics
  - [ ] Multi-page document
  - [ ] PDF with forms and annotations
  - [ ] Unicode and international text

### 5.2 Integration Tests
- [ ] Test basic conversion functionality
- [ ] Test all command-line options
- [ ] Test error handling and edge cases
- [ ] Test memory usage and performance
- [ ] Test output quality validation

### 5.3 Unit Tests
- [ ] Test formula installation
- [ ] Test dependency resolution
- [ ] Test build configuration
- [ ] Test platform detection

## Phase 6: Documentation Enhancement

### 6.1 User Documentation
- [ ] Create comprehensive troubleshooting guide
- [ ] Add FAQ section
- [ ] Create migration guide from other tools
- [ ] Add performance tuning guide

### 6.2 Developer Documentation
- [ ] Document build architecture
- [ ] Create dependency update guide
- [ ] Add formula development guide
- [ ] Create debugging guide

### 6.3 Project Documentation (Partially Complete)
- [x] Add CONTRIBUTING.md ✓
- [ ] Create SECURITY.md
- [ ] Add CODE_OF_CONDUCT.md
- [x] Create CHANGELOG.md ✓
- [x] Update README.md with installation instructions ✓
- [ ] Update README.md with badges

## Phase 7: Security Hardening

### 7.1 Build Security
- [ ] Enable all compiler security flags
- [ ] Add runtime security checks
- [ ] Implement secure defaults
- [ ] Add security testing to CI

### 7.2 Dependency Security
- [ ] Set up automated CVE scanning
- [ ] Create security update process
- [ ] Document security policies
- [ ] Add security contact information

## Phase 8: Performance Optimization

### 8.1 Build Performance
- [ ] Optimize CMake flags
- [ ] Enable ccache support
- [ ] Parallelize build stages
- [ ] Minimize dependency builds

### 8.2 Runtime Performance
- [ ] Profile conversion performance
- [ ] Optimize memory usage
- [ ] Add performance benchmarks
- [ ] Create performance regression tests

## Phase 9: Community Features

### 9.1 Issue Management (Partially Complete)
- [x] Create issue templates for bugs ✓
- [x] Create feature request template ✓
- [ ] Add security issue template
- [ ] Set up issue labels and automation

### 9.2 Contribution Support (Partially Complete)
- [x] Create PR template ✓
- [x] Add contributor guidelines (in CONTRIBUTING.md) ✓
- [x] Set up automated PR checks (via GitHub Actions) ✓
- [ ] Create contributor recognition

## Phase 10: Release Management

### 10.1 Version Management
- [ ] Implement semantic versioning
- [ ] Automate version bumping
- [ ] Create release notes generation
- [ ] Set up release notifications

### 10.2 Distribution
- [ ] Automate bottle uploads
- [ ] Create tap for the formula
- [ ] Set up mirror locations
- [ ] Add installation statistics

## Implementation Priority

### Week 1 (Immediate)
1. Repository restructuring (Phase 1)
2. Fix formula placeholders (Phase 2.1)
3. Basic CI/CD setup (Phase 3.1)

### Week 2-3 (Short-term)
4. Helper scripts (Phase 4.1)
5. Basic test suite (Phase 5.1-5.2)
6. Documentation updates (Phase 6.3)

### Week 4+ (Medium-term)
7. Advanced CI/CD features (Phase 3.2-3.3)
8. Security implementation (Phase 7)
9. Performance optimization (Phase 8)
10. Community features (Phase 9-10)

## Success Metrics

- [ ] All tests passing on CI
- [ ] Successful bottle builds for all platforms
- [ ] < 10 minute build time
- [ ] Zero security vulnerabilities
- [ ] 100% documentation coverage
- [ ] Automated release process
- [ ] Active community contributions

## Notes

- Each phase can be worked on in parallel where dependencies allow
- Priority should be given to user-facing improvements
- Security fixes should be implemented immediately when discovered
- Performance optimizations should be data-driven
- Community feedback should guide feature prioritization