#!/bin/bash
# update-version.sh - Update pdf2htmlEX version in the formula

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to calculate SHA256
calculate_sha256() {
    local url=$1
    local temp_file=$(mktemp)
    
    print_status "$YELLOW" "Downloading from $url..."
    if curl -L -o "$temp_file" "$url"; then
        local sha=$(shasum -a 256 "$temp_file" | awk '{print $1}')
        rm -f "$temp_file"
        echo "$sha"
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Update the pdf2htmlEX formula with new versions and checksums.

OPTIONS:
    -p, --pdf2htmlex VERSION    Update pdf2htmlEX version
    -o, --poppler VERSION       Update Poppler version
    -f, --fontforge VERSION     Update FontForge version
    -a, --all                   Update all components (interactive)
    -h, --help                  Show this help message

EXAMPLES:
    $0 --pdf2htmlex 0.18.8.rc2
    $0 --poppler 24.02.0
    $0 --all
EOF
}

# Parse arguments
UPDATE_PDF2HTMLEX=""
UPDATE_POPPLER=""
UPDATE_FONTFORGE=""
UPDATE_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--pdf2htmlex)
            UPDATE_PDF2HTMLEX="$2"
            shift 2
            ;;
        -o|--poppler)
            UPDATE_POPPLER="$2"
            shift 2
            ;;
        -f|--fontforge)
            UPDATE_FONTFORGE="$2"
            shift 2
            ;;
        -a|--all)
            UPDATE_ALL=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_status "$RED" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Get formula path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA_PATH="$SCRIPT_DIR/../Formula/pdf2htmlex.rb"

if [ ! -f "$FORMULA_PATH" ]; then
    print_status "$RED" "Error: Formula not found at $FORMULA_PATH"
    exit 1
fi

# Interactive mode for --all
if [ "$UPDATE_ALL" = true ]; then
    print_status "$GREEN" "=== Interactive Version Update ==="
    echo ""
    
    # Get current versions
    CURRENT_PDF2HTMLEX=$(grep -E '^\s*version\s+"' "$FORMULA_PATH" | sed -E 's/.*"(.*)".*/\1/')
    CURRENT_POPPLER=$(grep -A1 'resource "poppler"' "$FORMULA_PATH" | grep url | sed -E 's/.*poppler-(.*)\.tar.*/\1/')
    CURRENT_FONTFORGE=$(grep -A1 'resource "fontforge"' "$FORMULA_PATH" | grep url | sed -E 's/.*fontforge-(.*)\.tar.*/\1/')
    
    print_status "$YELLOW" "Current versions:"
    echo "  pdf2htmlEX: $CURRENT_PDF2HTMLEX"
    echo "  Poppler: $CURRENT_POPPLER"
    echo "  FontForge: $CURRENT_FONTFORGE"
    echo ""
    
    read -p "Update pdf2htmlEX version? (current: $CURRENT_PDF2HTMLEX, press Enter to skip): " UPDATE_PDF2HTMLEX
    read -p "Update Poppler version? (current: $CURRENT_POPPLER, press Enter to skip): " UPDATE_POPPLER
    read -p "Update FontForge version? (current: $CURRENT_FONTFORGE, press Enter to skip): " UPDATE_FONTFORGE
fi

# Create backup
BACKUP_FILE="${FORMULA_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$FORMULA_PATH" "$BACKUP_FILE"
print_status "$GREEN" "Created backup: $BACKUP_FILE"

# Update pdf2htmlEX version
if [ -n "$UPDATE_PDF2HTMLEX" ]; then
    print_status "$YELLOW" "Updating pdf2htmlEX to version $UPDATE_PDF2HTMLEX..."
    
    # Construct URL
    URL="https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v${UPDATE_PDF2HTMLEX}.tar.gz"
    
    # Calculate SHA256
    SHA256=$(calculate_sha256 "$URL")
    if [ $? -eq 0 ]; then
        # Update version
        sed -i '' "s/version \".*\"/version \"$UPDATE_PDF2HTMLEX\"/" "$FORMULA_PATH"
        
        # Update URL if needed
        sed -i '' "s|url \".*pdf2htmlEX.*\"|url \"$URL\"|" "$FORMULA_PATH"
        
        # Update SHA256
        sed -i '' "/url.*pdf2htmlEX/,/sha256/ s/sha256 \".*\"/sha256 \"$SHA256\"/" "$FORMULA_PATH"
        
        print_status "$GREEN" "✓ Updated pdf2htmlEX to $UPDATE_PDF2HTMLEX"
        print_status "$GREEN" "  SHA256: $SHA256"
    else
        print_status "$RED" "✗ Failed to download pdf2htmlEX version $UPDATE_PDF2HTMLEX"
    fi
fi

# Update Poppler version
if [ -n "$UPDATE_POPPLER" ]; then
    print_status "$YELLOW" "Updating Poppler to version $UPDATE_POPPLER..."
    
    # Construct URL
    URL="https://poppler.freedesktop.org/poppler-${UPDATE_POPPLER}.tar.xz"
    
    # Calculate SHA256
    SHA256=$(calculate_sha256 "$URL")
    if [ $? -eq 0 ]; then
        # Update URL and SHA256 in the poppler resource block
        sed -i '' "/resource \"poppler\"/,/end/ s|url \".*\"|url \"$URL\"|" "$FORMULA_PATH"
        sed -i '' "/resource \"poppler\"/,/end/ s/sha256 \".*\"/sha256 \"$SHA256\"/" "$FORMULA_PATH"
        
        print_status "$GREEN" "✓ Updated Poppler to $UPDATE_POPPLER"
        print_status "$GREEN" "  SHA256: $SHA256"
    else
        print_status "$RED" "✗ Failed to download Poppler version $UPDATE_POPPLER"
    fi
fi

# Update FontForge version
if [ -n "$UPDATE_FONTFORGE" ]; then
    print_status "$YELLOW" "Updating FontForge to version $UPDATE_FONTFORGE..."
    
    # Construct URL
    URL="https://github.com/fontforge/fontforge/releases/download/${UPDATE_FONTFORGE}/fontforge-${UPDATE_FONTFORGE}.tar.xz"
    
    # Calculate SHA256
    SHA256=$(calculate_sha256 "$URL")
    if [ $? -eq 0 ]; then
        # Update URL and SHA256 in the fontforge resource block
        sed -i '' "/resource \"fontforge\"/,/end/ s|url \".*\"|url \"$URL\"|" "$FORMULA_PATH"
        sed -i '' "/resource \"fontforge\"/,/end/ s/sha256 \".*\"/sha256 \"$SHA256\"/" "$FORMULA_PATH"
        
        print_status "$GREEN" "✓ Updated FontForge to $UPDATE_FONTFORGE"
        print_status "$GREEN" "  SHA256: $SHA256"
    else
        print_status "$RED" "✗ Failed to download FontForge version $UPDATE_FONTFORGE"
    fi
fi

# Show diff
if [ -n "$UPDATE_PDF2HTMLEX" ] || [ -n "$UPDATE_POPPLER" ] || [ -n "$UPDATE_FONTFORGE" ]; then
    echo ""
    print_status "$YELLOW" "Changes made:"
    diff -u "$BACKUP_FILE" "$FORMULA_PATH" || true
    
    echo ""
    print_status "$YELLOW" "Testing formula..."
    if brew audit --strict "$FORMULA_PATH"; then
        print_status "$GREEN" "✓ Formula audit passed"
    else
        print_status "$RED" "✗ Formula audit failed"
        print_status "$YELLOW" "Restoring backup..."
        cp "$BACKUP_FILE" "$FORMULA_PATH"
        exit 1
    fi
    
    echo ""
    print_status "$GREEN" "=== Version update complete ==="
    print_status "$YELLOW" "Next steps:"
    echo "1. Test the formula: ./scripts/test-formula.sh"
    echo "2. Commit changes: git add Formula/pdf2htmlex.rb && git commit -m 'Update versions'"
    echo "3. Create PR or push to main"
else
    print_status "$YELLOW" "No updates requested"
    rm -f "$BACKUP_FILE"
fi