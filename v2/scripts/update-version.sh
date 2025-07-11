#!/bin/bash
# this_file: v2/scripts/update-version.sh
#
# Version Management Script for pdf2htmlEX v2
# Updates dependency versions and checksums in the Homebrew formula
#
# Usage: ./v2/scripts/update-version.sh [component] [version]
# Components: pdf2htmlex, jpeg-turbo, poppler, fontforge
#
# Example: ./v2/scripts/update-version.sh pdf2htmlex 0.18.8.rc2

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FORMULA_PATH="$SCRIPT_DIR/../Formula/pdf2htmlex.rb"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*${NC}"
    exit 1
}

usage() {
    cat << EOF
Usage: $0 [component] [version]

Components:
  pdf2htmlex   - Main pdf2htmlEX application
  jpeg-turbo   - JPEG library dependency
  poppler      - PDF rendering library
  fontforge    - Font processing library

Examples:
  $0 pdf2htmlex 0.18.8.rc2
  $0 jpeg-turbo 3.0.3
  $0 poppler 24.02.0
  $0 fontforge 20230501

Without arguments, shows current versions.
EOF
}

get_url_for_component() {
    local component="$1"
    local version="$2"
    
    case "$component" in
        pdf2htmlex)
            echo "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v${version}.tar.gz"
            ;;
        jpeg-turbo)
            # libjpeg-turbo now publishes official release artefacts on GitHub
            # rather than SourceForge.  Use the canonical GitHub source archive
            # so that the formula and the standalone build script stay in
            # sync and avoid intermittent 404s from the old mirror.
            echo "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${version}.tar.gz"
            ;;
        poppler)
            echo "https://poppler.freedesktop.org/poppler-${version}.tar.xz"
            ;;
        fontforge)
            echo "https://github.com/fontforge/fontforge/archive/${version}.tar.gz"
            ;;
        *)
            error "Unknown component: $component"
            ;;
    esac
}

calculate_sha256() {
    local url="$1"
    local temp_file
    
    temp_file=$(mktemp)
    
    log "Downloading $url to calculate SHA256..."
    
    if curl -L "$url" -o "$temp_file"; then
        local sha256
        if command -v sha256sum &> /dev/null; then
            sha256=$(sha256sum "$temp_file" | cut -d' ' -f1)
        elif command -v shasum &> /dev/null; then
            sha256=$(shasum -a 256 "$temp_file" | cut -d' ' -f1)
        else
            error "Neither sha256sum nor shasum found"
        fi
        
        rm -f "$temp_file"
        echo "$sha256"
    else
        rm -f "$temp_file"
        error "Failed to download $url"
    fi
}

show_current_versions() {
    log "Current versions in formula:"
    
    if [[ ! -f "$FORMULA_PATH" ]]; then
        error "Formula not found at $FORMULA_PATH"
    fi
    
    # Extract current versions
    local pdf2htmlex_version
    local jpeg_turbo_version
    local poppler_version
    local fontforge_version
    
    pdf2htmlex_version=$(grep -E '^\s*version\s+' "$FORMULA_PATH" | sed 's/.*"\([^"]*\)".*/\1/')
    jpeg_turbo_version=$(grep -A1 'resource "jpeg-turbo"' "$FORMULA_PATH" | grep url | sed 's/.*libjpeg-turbo-\([^"]*\)\.tar\.gz.*/\1/')
    poppler_version=$(grep -A1 'resource "poppler"' "$FORMULA_PATH" | grep url | sed 's/.*poppler-\([^"]*\)\.tar\.xz.*/\1/')
    fontforge_version=$(grep -A1 'resource "fontforge"' "$FORMULA_PATH" | grep url | sed 's/.*\/\([^"]*\)\.tar\.gz.*/\1/')
    
    echo "  pdf2htmlEX: $pdf2htmlex_version"
    echo "  jpeg-turbo: $jpeg_turbo_version"
    echo "  poppler:    $poppler_version"
    echo "  fontforge:  $fontforge_version"
}

update_component() {
    local component="$1"
    local new_version="$2"
    
    log "Updating $component to version $new_version..."
    
    # Get URL for new version
    local url
    url=$(get_url_for_component "$component" "$new_version")
    
    # Calculate SHA256
    local sha256
    sha256=$(calculate_sha256 "$url")
    
    log "New SHA256: $sha256"
    
    # Create backup
    cp "$FORMULA_PATH" "$FORMULA_PATH.backup"
    
    # Update formula based on component
    case "$component" in
        pdf2htmlex)
            # Update main version and URL
            sed -i '' "s|url \"https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v[^\"]*\.tar\.gz\"|url \"$url\"|" "$FORMULA_PATH"
            sed -i '' "s|sha256 \"[^\"]*\"|sha256 \"$sha256\"|" "$FORMULA_PATH"
            sed -i '' "s|version \"[^\"]*\"|version \"$new_version\"|" "$FORMULA_PATH"
            ;;
        jpeg-turbo)
            # Update jpeg-turbo resource
            sed -i '' "/resource \"jpeg-turbo\"/,/end/ {
                s|url \"[^\"]*\"|url \"$url\"|
                s|sha256 \"[^\"]*\"|sha256 \"$sha256\"|
            }" "$FORMULA_PATH"
            ;;
        poppler)
            # Update poppler resource
            sed -i '' "/resource \"poppler\"/,/end/ {
                s|url \"[^\"]*\"|url \"$url\"|
                s|sha256 \"[^\"]*\"|sha256 \"$sha256\"|
            }" "$FORMULA_PATH"
            ;;
        fontforge)
            # Update fontforge resource
            sed -i '' "/resource \"fontforge\"/,/end/ {
                s|url \"[^\"]*\"|url \"$url\"|
                s|sha256 \"[^\"]*\"|sha256 \"$sha256\"|
            }" "$FORMULA_PATH"
            ;;
    esac
    
    # Verify the change was made
    if grep -q "$sha256" "$FORMULA_PATH"; then
        log "Successfully updated $component to version $new_version"
        
        # Also update the build script if it exists
        local build_script="$SCRIPT_DIR/build.sh"
        if [[ -f "$build_script" ]]; then
            case "$component" in
                pdf2htmlex)
                    sed -i '' "s/readonly PDF2HTMLEX_VERSION=\"[^\"]*\"/readonly PDF2HTMLEX_VERSION=\"$new_version\"/" "$build_script"
                    ;;
                jpeg-turbo)
                    sed -i '' "s/readonly JPEG_TURBO_VERSION=\"[^\"]*\"/readonly JPEG_TURBO_VERSION=\"$new_version\"/" "$build_script"
                    ;;
                poppler)
                    sed -i '' "s/readonly POPPLER_VERSION=\"[^\"]*\"/readonly POPPLER_VERSION=\"$new_version\"/" "$build_script"
                    ;;
                fontforge)
                    sed -i '' "s/readonly FONTFORGE_VERSION=\"[^\"]*\"/readonly FONTFORGE_VERSION=\"$new_version\"/" "$build_script"
                    ;;
            esac
            log "Updated build script with new version"
        fi
        
        # Clean up backup
        rm -f "$FORMULA_PATH.backup"
    else
        error "Failed to update formula. Restoring backup."
        mv "$FORMULA_PATH.backup" "$FORMULA_PATH"
    fi
}

validate_formula() {
    log "Validating formula syntax..."
    
    # Check if brew is available
    if ! command -v brew &> /dev/null; then
        warn "Homebrew not found. Cannot validate formula syntax."
        return
    fi
    
    # Run brew audit
    if brew audit --strict "$FORMULA_PATH"; then
        log "Formula validation passed"
    else
        warn "Formula validation failed. Please review the changes."
    fi
}

check_for_updates() {
    log "Checking for available updates..."
    
    # This is a placeholder for automated update checking
    # In a real implementation, this would check GitHub releases, etc.
    cat << EOF
To check for updates manually:
  pdf2htmlEX: https://github.com/pdf2htmlEX/pdf2htmlEX/releases
  jpeg-turbo: https://github.com/libjpeg-turbo/libjpeg-turbo/releases
  poppler:    https://poppler.freedesktop.org/
  fontforge:  https://github.com/fontforge/fontforge/releases
EOF
}

main() {
    if [[ $# -eq 0 ]]; then
        show_current_versions
        echo
        check_for_updates
        return
    fi
    
    if [[ $# -eq 1 && "$1" == "--help" ]]; then
        usage
        return
    fi
    
    if [[ $# -ne 2 ]]; then
        error "Invalid number of arguments. Use --help for usage."
    fi
    
    local component="$1"
    local version="$2"
    
    # Validate component
    case "$component" in
        pdf2htmlex|jpeg-turbo|poppler|fontforge)
            ;;
        *)
            error "Unknown component: $component. Use --help for valid components."
            ;;
    esac
    
    # Validate version format (basic check)
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?(\.rc[0-9]+)?$ ]]; then
        warn "Version format looks unusual: $version"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Aborted by user"
            exit 0
        fi
    fi
    
    update_component "$component" "$version"
    validate_formula
    
    log "Update completed successfully!"
    log "Don't forget to test the updated formula:"
    log "  brew install --build-from-source $FORMULA_PATH"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
