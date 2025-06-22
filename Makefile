# Makefile for pdf2htmlEX Homebrew Formula

.PHONY: help install test audit clean deps update-version check-deps lint

# Default target
help:
	@echo "pdf2htmlEX Homebrew Formula - Development Tasks"
	@echo ""
	@echo "Available targets:"
	@echo "  make install      - Install the formula from source"
	@echo "  make test         - Run all tests"
	@echo "  make audit        - Run brew audit on the formula" 
	@echo "  make clean        - Clean build artifacts and test files"
	@echo "  make deps         - Install required dependencies"
	@echo "  make check-deps   - Check if all dependencies are installed"
	@echo "  make update       - Interactive version update"
	@echo "  make lint         - Run linting checks"
	@echo ""
	@echo "Quick start:"
	@echo "  make deps         # Install dependencies"
	@echo "  make install      # Install formula"
	@echo "  make test         # Run tests"

# Install the formula
install:
	@echo "Installing pdf2htmlEX formula..."
	@brew uninstall pdf2htmlex 2>/dev/null || true
	@brew install --build-from-source Formula/pdf2htmlex.rb

# Run all tests
test: test-formula test-integration
	@echo "All tests completed!"

# Run formula tests
test-formula:
	@echo "Running formula tests..."
	@./scripts/test-formula.sh

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	@./tests/integration/test_conversions.sh

# Audit the formula
audit:
	@echo "Auditing formula..."
	@brew audit --strict Formula/pdf2htmlex.rb

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf staging/
	@rm -f test.pdf test.html test-*.pdf test-*.html
	@rm -f Formula/*.backup.*
	@find . -name "*.log" -delete
	@find . -name ".DS_Store" -delete
	@echo "Clean complete!"

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@brew install cmake ninja pkg-config
	@brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz
	@brew install openjdk
	@echo "Dependencies installed!"

# Check dependencies
check-deps:
	@./scripts/check-dependencies.sh

# Update versions interactively
update:
	@./scripts/update-version.sh --all

# Lint checks
lint: lint-shell lint-ruby

# Lint shell scripts
lint-shell:
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null; then \
		find . -name "*.sh" -type f -exec shellcheck {} \; ; \
	else \
		echo "shellcheck not installed, skipping shell linting"; \
	fi

# Lint Ruby files
lint-ruby:
	@echo "Linting Ruby files..."
	@brew style Formula/pdf2htmlex.rb

# Quick test after changes
quick-test:
	@brew audit Formula/pdf2htmlex.rb
	@if command -v pdf2htmlEX >/dev/null; then \
		pdf2htmlEX --version; \
	fi

# Create a release
release:
	@echo "Creating release..."
	@echo "1. Update version in formula"
	@echo "2. Update CHANGELOG.md"
	@echo "3. Commit changes"
	@echo "4. Tag with version"
	@echo "5. Push to GitHub"
	@echo ""
	@echo "Run: git tag -a vX.Y.Z -m 'Release vX.Y.Z'"
	@echo "     git push origin main --tags"

# Development setup
setup: deps
	@echo "Setting up development environment..."
	@chmod +x scripts/*.sh
	@chmod +x tests/integration/*.sh
	@chmod +x tests/fixtures/*.sh
	@echo "Setup complete!"

# Show current versions
versions:
	@echo "Current versions in formula:"
	@grep -E '^\s*version\s+"' Formula/pdf2htmlex.rb || echo "pdf2htmlEX: not found"
	@grep -A1 'resource "poppler"' Formula/pdf2htmlex.rb | grep url | sed 's/.*poppler-\(.*\)\.tar.*/Poppler: \1/' || echo "Poppler: not found"
	@grep -A1 'resource "fontforge"' Formula/pdf2htmlex.rb | grep url | sed 's/.*fontforge-\(.*\)\.tar.*/FontForge: \1/' || echo "FontForge: not found"

# Run CI locally
ci: audit test
	@echo "CI checks passed locally!"

# Show formula info
info:
	@if brew list pdf2htmlex &>/dev/null; then \
		brew info pdf2htmlex; \
	else \
		echo "pdf2htmlEX not installed"; \
	fi