# Contributing to pdf2htmlEX Homebrew Formula

First off, thank you for considering contributing to this project! 

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, please include as many details as possible using our issue template.

**Great Bug Reports** tend to have:
- A quick summary and/or background
- Steps to reproduce (be specific!)
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:
- Use a clear and descriptive title
- Provide a step-by-step description of the suggested enhancement
- Provide specific examples to demonstrate the steps
- Describe the current behavior and explain which behavior you expected to see instead
- Explain why this enhancement would be useful

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed the formula, ensure it passes audit: `brew audit --strict Formula/pdf2htmlex.rb`
4. Ensure all tests pass: `./scripts/test-formula.sh`
5. Update the CHANGELOG.md with your changes
6. Issue that pull request!

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/twardoch/pdf2htmlEX.git
   cd pdf2htmlEX
   ```

2. **Install dependencies**
   ```bash
   ./scripts/check-dependencies.sh
   brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz
   ```

3. **Test the formula**
   ```bash
   ./scripts/test-formula.sh
   ```

## Development Guidelines

### Formula Updates

When updating the formula:

1. **Version Updates**: Use the update script
   ```bash
   ./scripts/update-version.sh --all
   ```

2. **Manual Changes**: 
   - Always calculate proper SHA256 checksums
   - Test on both Intel and Apple Silicon if possible
   - Ensure static linking is maintained

3. **Testing**:
   - Run the full test suite
   - Test with various PDF types
   - Verify universal binary support

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Examples:
```
formula: update Poppler to 24.02.0

- Updates Poppler resource to version 24.02.0
- Adjusts CMake flags for compatibility
- Tested on macOS 13 and 14
```

### Code Style

For Ruby (Formula):
- Follow Homebrew's Ruby style guide
- Use `brew style --fix` to auto-format
- Keep formula clean and well-commented

For Shell Scripts:
- Use bash with `set -euo pipefail`
- Include error handling
- Add helpful comments
- Use ShellCheck for validation

### Testing

Before submitting:

1. **Local Testing**:
   ```bash
   # Full test suite
   ./scripts/test-formula.sh
   
   # Dependency check
   ./scripts/check-dependencies.sh
   
   # Integration tests
   ./tests/integration/test_conversions.sh
   ```

2. **Formula Audit**:
   ```bash
   brew audit --strict Formula/pdf2htmlex.rb
   ```

3. **Different Platforms**:
   - Test on latest macOS if possible
   - Test on both architectures if available

## Project Structure

```
pdf2htmlEX/
├── Formula/          # Homebrew formula
├── scripts/          # Development scripts
├── tests/           # Test suites
├── .github/         # GitHub configs
└── docs/           # Documentation
```

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create PR with changes
4. After merge, tag release
5. GitHub Actions will build bottles

## Questions?

Feel free to open an issue with the question label or reach out to the maintainers.

Thank you for contributing! 🎉