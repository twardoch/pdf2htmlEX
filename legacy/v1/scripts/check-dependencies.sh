#!/bin/bash
# check-dependencies.sh - Check and verify pdf2htmlEX dependencies

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check brew package
check_brew_package() {
    local package=$1
    local required=${2:-true}
    
    if brew list "$package" &>/dev/null; then
        local version=$(brew list --versions "$package" | awk '{print $2}')
        print_status "$GREEN" "  ✓ $package ($version)"
        return 0
    else
        if [ "$required" = true ]; then
            print_status "$RED" "  ✗ $package (NOT INSTALLED)"
        else
            print_status "$YELLOW" "  ○ $package (optional, not installed)"
        fi
        return 1
    fi
}

# Function to check system tool
check_system_tool() {
    local tool=$1
    local check_version_cmd=${2:-"$tool --version"}
    
    if command_exists "$tool"; then
        local version=$($check_version_cmd 2>&1 | head -1 || echo "unknown version")
        print_status "$GREEN" "  ✓ $tool: $version"
        return 0
    else
        print_status "$RED" "  ✗ $tool (NOT FOUND)"
        return 1
    fi
}

# Function to check upstream versions
check_upstream_versions() {
    print_status "$BLUE" "\n=== Checking Upstream Versions ==="
    
    # Check pdf2htmlEX
    print_status "$YELLOW" "pdf2htmlEX latest releases:"
    curl -s https://api.github.com/repos/pdf2htmlEX/pdf2htmlEX/releases | \
        jq -r '.[:3] | .[] | "  - \(.tag_name) (\(.published_at | split("T")[0]))"' 2>/dev/null || \
        print_status "$RED" "  Failed to fetch releases"
    
    # Check Poppler
    print_status "$YELLOW" "\nPoppler recent versions:"
    curl -s https://poppler.freedesktop.org/ | \
        grep -Eo 'poppler-[0-9]+\.[0-9]+\.[0-9]+\.tar\.xz' | \
        sort -V | tail -5 | sed 's/^/  - /' || \
        print_status "$RED" "  Failed to fetch versions"
    
    # Check FontForge
    print_status "$YELLOW" "\nFontForge latest releases:"
    curl -s https://api.github.com/repos/fontforge/fontforge/releases | \
        jq -r '.[:3] | .[] | "  - \(.tag_name) (\(.published_at | split("T")[0]))"' 2>/dev/null || \
        print_status "$RED" "  Failed to fetch releases"
}

# Main script
print_status "$GREEN" "=== pdf2htmlEX Dependency Check ==="
echo ""

# Check if Homebrew is installed
if ! command_exists brew; then
    print_status "$RED" "Error: Homebrew is not installed"
    print_status "$YELLOW" "Install from: https://brew.sh"
    exit 1
fi

# Check build tools
print_status "$BLUE" "=== Build Tools ==="
check_system_tool "cmake" "cmake --version"
check_system_tool "ninja" "ninja --version"
check_system_tool "pkg-config" "pkg-config --version"
check_system_tool "git" "git --version"

# Check required dependencies
print_status "$BLUE" "\n=== Required Dependencies ==="
MISSING_DEPS=0

for dep in cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz; do
    check_brew_package "$dep" || ((MISSING_DEPS++))
done

# Check optional dependencies
print_status "$BLUE" "\n=== Optional Dependencies ==="
check_brew_package "openjdk" false
check_brew_package "ccache" false

# Check if pdf2htmlEX is installed
print_status "$BLUE" "\n=== pdf2htmlEX Installation ==="
if command_exists pdf2htmlEX; then
    PDF2HTMLEX_VERSION=$(pdf2htmlEX --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[^ ]*' | head -1 || echo "unknown")
    print_status "$GREEN" "✓ pdf2htmlEX is installed (version: $PDF2HTMLEX_VERSION)"
    
    # Check binary details
    BINARY_PATH=$(which pdf2htmlEX)
    print_status "$YELLOW" "  Binary: $BINARY_PATH"
    
    # Check architecture
    if command_exists file; then
        ARCH_INFO=$(file "$BINARY_PATH" | sed 's/.*: //')
        print_status "$YELLOW" "  Architecture: $ARCH_INFO"
    fi
    
    # Check dynamic libraries
    if command_exists otool; then
        print_status "$YELLOW" "  Dynamic libraries:"
        otool -L "$BINARY_PATH" | grep -v "$BINARY_PATH:" | head -5 | sed 's/^/    /'
        DYLIB_COUNT=$(otool -L "$BINARY_PATH" | grep -c '\.dylib' || true)
        print_status "$YELLOW" "    ... and $((DYLIB_COUNT - 5)) more"
    fi
else
    print_status "$YELLOW" "○ pdf2htmlEX is not installed"
fi

# Check formula
print_status "$BLUE" "\n=== Formula Status ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA_PATH="$SCRIPT_DIR/../Formula/pdf2htmlex.rb"

if [ -f "$FORMULA_PATH" ]; then
    print_status "$GREEN" "✓ Formula found at: $FORMULA_PATH"
    
    # Extract versions from formula
    FORMULA_PDF2HTMLEX=$(grep -E '^\s*version\s+"' "$FORMULA_PATH" | sed -E 's/.*"(.*)".*/\1/')
    FORMULA_POPPLER=$(grep -A1 'resource "poppler"' "$FORMULA_PATH" | grep url | sed -E 's/.*poppler-(.*)\.tar.*/\1/')
    FORMULA_FONTFORGE=$(grep -A1 'resource "fontforge"' "$FORMULA_PATH" | grep url | sed -E 's/.*fontforge-(.*)\.tar.*/\1/')
    
    print_status "$YELLOW" "  Versions in formula:"
    print_status "$YELLOW" "    pdf2htmlEX: $FORMULA_PDF2HTMLEX"
    print_status "$YELLOW" "    Poppler: $FORMULA_POPPLER"
    print_status "$YELLOW" "    FontForge: $FORMULA_FONTFORGE"
else
    print_status "$RED" "✗ Formula not found"
fi

# System information
print_status "$BLUE" "\n=== System Information ==="
print_status "$YELLOW" "  macOS: $(sw_vers -productVersion)"
print_status "$YELLOW" "  Architecture: $(uname -m)"
print_status "$YELLOW" "  Xcode: $(xcodebuild -version 2>/dev/null | head -1 || echo "Not installed")"
print_status "$YELLOW" "  Homebrew: $(brew --version | head -1)"

# Check for potential issues
print_status "$BLUE" "\n=== Potential Issues ==="
ISSUES=0

# Check for missing dependencies
if [ $MISSING_DEPS -gt 0 ]; then
    print_status "$RED" "✗ Missing $MISSING_DEPS required dependencies"
    ((ISSUES++))
fi

# Check for outdated Xcode
if ! xcode-select -p &>/dev/null; then
    print_status "$RED" "✗ Xcode Command Line Tools not installed"
    print_status "$YELLOW" "  Install with: xcode-select --install"
    ((ISSUES++))
fi

# Check for Rosetta on Apple Silicon
if [ "$(uname -m)" = "arm64" ] && [ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]; then
    print_status "$YELLOW" "○ Rosetta 2 not installed (optional, for x86_64 compatibility)"
    print_status "$YELLOW" "  Install with: softwareupdate --install-rosetta"
fi

if [ $ISSUES -eq 0 ]; then
    print_status "$GREEN" "✓ No issues detected"
fi

# Installation instructions
if [ $MISSING_DEPS -gt 0 ]; then
    print_status "$BLUE" "\n=== Installation Instructions ==="
    print_status "$YELLOW" "Install missing dependencies with:"
    echo "  brew install cairo fontconfig freetype gettext glib jpeg-turbo libpng libtiff libxml2 pango harfbuzz"
fi

# Optional: Check upstream versions
if [ "${CHECK_UPSTREAM:-0}" = "1" ]; then
    check_upstream_versions
fi

# Summary
echo ""
if [ $MISSING_DEPS -eq 0 ] && [ $ISSUES -eq 0 ]; then
    print_status "$GREEN" "=== All dependencies satisfied! ==="
else
    print_status "$RED" "=== Dependencies check failed ==="
    print_status "$YELLOW" "Please install missing dependencies before building pdf2htmlEX"
    exit 1
fi