#!/bin/bash
# setup-tap.sh - Set up a proper Homebrew tap for pdf2htmlEX

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

print_status "$GREEN" "=== pdf2htmlEX Tap Setup Script ==="
echo ""

# Check if Homebrew is installed
if ! command_exists brew; then
    print_status "$RED" "Error: Homebrew is not installed"
    print_status "$YELLOW" "Install from: https://brew.sh"
    exit 1
fi

# Parse arguments
TAP_NAME="${1:-twardoch/pdf2htmlex}"
FORMULA_URL="https://raw.githubusercontent.com/twardoch/pdf2htmlEX/main/Formula/pdf2htmlex.rb"

print_status "$YELLOW" "This script will set up a Homebrew tap for pdf2htmlEX"
echo ""
echo "Tap name: $TAP_NAME"
echo ""

# Check if tap already exists
if brew tap | grep -q "^$TAP_NAME\$"; then
    print_status "$YELLOW" "Tap $TAP_NAME already exists. Updating..."
    brew untap "$TAP_NAME"
fi

# Create the tap
print_status "$BLUE" "Creating tap..."
brew tap-new "$TAP_NAME" --no-git

# Get tap directory
TAP_DIR=$(brew --repository)/Library/Taps/$(echo "$TAP_NAME" | tr '/' '/homebrew-')

# Create Formula directory if it doesn't exist
mkdir -p "$TAP_DIR/Formula"

# Download the formula
print_status "$BLUE" "Downloading formula..."
curl -sL "$FORMULA_URL" -o "$TAP_DIR/Formula/pdf2htmlex.rb"

# Verify the formula
print_status "$BLUE" "Verifying formula..."
if brew audit --strict "$TAP_DIR/Formula/pdf2htmlex.rb" 2>/dev/null; then
    print_status "$GREEN" "✓ Formula audit passed"
else
    print_status "$YELLOW" "⚠ Formula has some warnings (this is normal)"
fi

# Initialize git repository (optional, for version control)
if [ ! -d "$TAP_DIR/.git" ]; then
    print_status "$BLUE" "Initializing git repository..."
    cd "$TAP_DIR"
    git init
    git add .
    git commit -m "Initial commit with pdf2htmlex formula"
    cd - >/dev/null
fi

print_status "$GREEN" "=== Setup Complete! ==="
echo ""
print_status "$YELLOW" "You can now install pdf2htmlEX with:"
echo ""
echo "  brew install $TAP_NAME/pdf2htmlex"
echo ""
print_status "$YELLOW" "Or build from source:"
echo ""
echo "  brew install --build-from-source $TAP_NAME/pdf2htmlex"
echo ""
print_status "$YELLOW" "To uninstall the tap later:"
echo ""
echo "  brew untap $TAP_NAME"
echo ""