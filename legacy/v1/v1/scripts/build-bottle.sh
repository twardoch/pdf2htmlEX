#!/bin/bash
# build-bottle.sh - Build bottles for pdf2htmlEX formula

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

# Parse arguments
KEEP_BOTTLE=${KEEP_BOTTLE:-0}
UPLOAD=${UPLOAD:-0}
FORMULA_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --keep)
            KEEP_BOTTLE=1
            shift
            ;;
        --upload)
            UPLOAD=1
            shift
            ;;
        --formula)
            FORMULA_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --keep          Keep bottle file after building"
            echo "  --upload        Upload bottle to GitHub release (requires gh)"
            echo "  --formula PATH  Path to formula (default: auto-detect)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            print_status "$RED" "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "$GREEN" "=== pdf2htmlEX Bottle Builder ==="
echo ""

# Check prerequisites
if ! command_exists brew; then
    print_status "$RED" "Error: Homebrew is not installed"
    exit 1
fi

# Find formula path if not specified
if [ -z "$FORMULA_PATH" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FORMULA_PATH="$SCRIPT_DIR/../Formula/pdf2htmlex.rb"
fi

if [ ! -f "$FORMULA_PATH" ]; then
    print_status "$RED" "Error: Formula not found at $FORMULA_PATH"
    exit 1
fi

# Get formula name
FORMULA_NAME=$(basename "$FORMULA_PATH" .rb)

# Check if formula is installed
if ! brew list "$FORMULA_NAME" &>/dev/null; then
    print_status "$YELLOW" "Formula not installed. Installing first..."
    brew install --build-bottle "$FORMULA_PATH"
else
    print_status "$YELLOW" "Uninstalling existing installation..."
    brew uninstall "$FORMULA_NAME"
    print_status "$YELLOW" "Reinstalling with --build-bottle flag..."
    brew install --build-bottle "$FORMULA_PATH"
fi

# Build the bottle
print_status "$BLUE" "Building bottle..."
brew bottle --json --no-rebuild "$FORMULA_NAME" > bottle_output.json

# Parse bottle information
if [ -f bottle_output.json ]; then
    BOTTLE_FILE=$(jq -r ".\"$FORMULA_NAME\".bottle.tags[].filename" bottle_output.json | head -1)
    print_status "$GREEN" "✓ Bottle created: $BOTTLE_FILE"
    
    # Show bottle information
    print_status "$BLUE" "Bottle information:"
    jq ".\"$FORMULA_NAME\".bottle.tags" bottle_output.json
    
    # Calculate SHA256
    if [ -f "$BOTTLE_FILE" ]; then
        SHA256=$(shasum -a 256 "$BOTTLE_FILE" | awk '{print $1}')
        print_status "$YELLOW" "SHA256: $SHA256"
    fi
    
    # Clean up JSON file
    rm -f bottle_output.json
else
    print_status "$RED" "✗ Failed to create bottle"
    exit 1
fi

# Show bottle block for formula
print_status "$BLUE" "Add this bottle block to your formula:"
echo ""
cat << EOF
  bottle do
    sha256 cellar: :any, arm64_sonoma:  "$SHA256"
    sha256 cellar: :any, arm64_ventura: "$SHA256"
    sha256 cellar: :any, ventura:       "$SHA256"
    sha256 cellar: :any, monterey:      "$SHA256"
  end
EOF
echo ""
print_status "$YELLOW" "Note: You'll need to build on each platform to get accurate SHAs"

# Upload to GitHub if requested
if [ "$UPLOAD" = "1" ]; then
    if command_exists gh; then
        print_status "$BLUE" "Uploading to GitHub release..."
        
        # Get latest release
        LATEST_RELEASE=$(gh release list --limit 1 | awk '{print $1}')
        
        if [ -n "$LATEST_RELEASE" ]; then
            gh release upload "$LATEST_RELEASE" "$BOTTLE_FILE"
            print_status "$GREEN" "✓ Bottle uploaded to release $LATEST_RELEASE"
        else
            print_status "$RED" "No releases found. Create a release first."
        fi
    else
        print_status "$RED" "GitHub CLI (gh) not installed. Cannot upload."
    fi
fi

# Clean up or keep bottle
if [ "$KEEP_BOTTLE" = "1" ]; then
    print_status "$GREEN" "Bottle kept at: $BOTTLE_FILE"
else
    print_status "$YELLOW" "Cleaning up bottle file..."
    rm -f "$BOTTLE_FILE"
fi

print_status "$GREEN" "=== Bottle building complete! ==="

# Additional instructions
echo ""
print_status "$YELLOW" "Next steps:"
echo "1. Build bottles on all target platforms"
echo "2. Collect SHA256 values for each platform"
echo "3. Update formula with bottle block"
echo "4. Test bottle installation:"
echo "   brew install --force-bottle $FORMULA_NAME"