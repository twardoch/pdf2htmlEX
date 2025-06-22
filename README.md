# pdf2htmlEX Homebrew Formula for macOS

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

## Contribution Guidelines

### For Project Maintainers

#### Regular Maintenance Tasks

1. **Weekly**
   - Check upstream pdf2htmlEX for new releases
   - Monitor Poppler and FontForge for updates
   - Review and triage new issues
   - Test formula on latest macOS beta (if available)

2. **Monthly**
   - Update dependency versions (if compatible)
   - Review and merge pending PRs
   - Update documentation based on user feedback
   - Publish release notes

3. **Quarterly**
   - Comprehensive security audit
   - Performance profiling and optimization
   - Major version planning
   - Community outreach

#### Release Process

1. **Version Update Checklist**
   ```bash
   # 1. Update version numbers
   ./scripts/update-versions.rb --component pdf2htmlex --version X.Y.Z
   
   # 2. Test locally on all architectures
   ./scripts/test-build.sh --arch universal
   
   # 3. Run full test suite
   ./test/validate.rb --comprehensive
   
   # 4. Create PR with changes
   git checkout -b update-pdf2htmlex-X.Y.Z
   git commit -am "Update pdf2htmlEX to X.Y.Z"
   gh pr create --title "Update pdf2htmlEX to X.Y.Z"
   
   # 5. After CI passes, merge and tag
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

2. **Bottle Creation**
   - Bottles should be built on clean macOS installations
   - Test bottles on minimum supported macOS version
   - Verify universal binary with `lipo -info`
   - Upload to GitHub Releases with checksums

### For Contributors

#### Getting Started

1. **Development Environment Setup**
   ```bash
   # Fork and clone the repository
   git clone https://github.com/YOUR_USERNAME/pdf2htmlex-homebrew
   cd pdf2htmlex-homebrew
   
   # Install development dependencies
   brew install --HEAD --build-from-source ./Formula/pdf2htmlex.rb
   
   # Set up pre-commit hooks
   ./scripts/setup-dev-env.sh
   ```

2. **Testing Your Changes**
   ```bash
   # Run local tests
   brew test --verbose Formula/pdf2htmlex.rb
   
   # Run comprehensive test suite
   ./test/validate.rb --all
   
   # Test on both architectures (if on Apple Silicon)
   arch -x86_64 brew test Formula/pdf2htmlex.rb
   arch -arm64 brew test Formula/pdf2htmlex.rb
   ```

#### Contribution Types

1. **Bug Fixes**
   - Reproduce the issue locally first
   - Add a test case that fails without your fix
   - Ensure your fix doesn't break existing functionality
   - Document the fix in the commit message

2. **Feature Additions**
   - Discuss in an issue before implementing
   - Follow the existing code style
   - Add comprehensive tests
   - Update documentation

3. **Dependency Updates**
   - Test with both old and new versions
   - Document any breaking changes
   - Update compatibility matrix
   - Provide migration instructions if needed

4. **Documentation Improvements**
   - Ensure technical accuracy
   - Add practical examples
   - Keep language clear and concise
   - Update table of contents if needed

#### Code Standards

1. **Ruby Style**
   - Follow Homebrew's Ruby style guide
   - Use `brew style --fix` before committing
   - Keep methods under 25 lines
   - Use descriptive variable names

2. **Shell Scripts**
   - Use `#!/usr/bin/env bash` shebang
   - Set `set -euo pipefail` for safety
   - Quote all variables
   - Add inline documentation

3. **Documentation**
   - Use GitHub Flavored Markdown
   - Include code examples with syntax highlighting
   - Add table of contents for long documents
   - Keep line length under 100 characters

#### Pull Request Guidelines

1. **Before Submitting**
   - [ ] Run all tests locally
   - [ ] Update CHANGELOG.md
   - [ ] Ensure commits are logical and atomic
   - [ ] Write clear commit messages
   - [ ] Update relevant documentation

2. **PR Description Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Performance improvement
   
   ## Testing
   - [ ] Tested on Intel Mac
   - [ ] Tested on Apple Silicon Mac
   - [ ] Added/updated tests
   
   ## Checklist
   - [ ] Follows code style guidelines
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated
   - [ ] No breaking changes (or documented)
   ```

3. **Review Process**
   - Address reviewer feedback promptly
   - Keep PR scope focused
   - Rebase on main if needed
   - Squash commits before merge if requested

#### Issue Reporting

1. **Bug Reports Should Include**
   - macOS version and architecture
   - Homebrew version (`brew --version`)
   - Complete error output
   - Steps to reproduce
   - Expected vs actual behavior

2. **Feature Requests Should Include**
   - Use case description
   - Proposed implementation (if any)
   - Potential impact on existing users
   - Alternative solutions considered

### Communication Channels

1. **GitHub Issues**: Primary communication method
2. **Discussions**: For general questions and ideas
3. **Pull Requests**: For code contributions
4. **Email**: For security issues only (security@example.com)

### Recognition

Contributors who make significant improvements will be:
- Added to CONTRIBUTORS.md
- Mentioned in release notes
- Given collaborator access (for sustained contributions)

## Security Policy

Security issues should be reported privately via email. Do not create public issues for security vulnerabilities. We aim to respond within 48 hours and provide fixes within 7 days for critical issues.

## License

This Homebrew formula is released under the same license as Homebrew (BSD 2-Clause). pdf2htmlEX itself is licensed under GPLv3.

---

*This project is not officially affiliated with the pdf2htmlEX project but aims to support the macOS community in using this excellent tool.*