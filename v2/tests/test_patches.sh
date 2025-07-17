#!/bin/bash
# this_file: v2/tests/test_patches.sh
#
# Patch application and validation tests for pdf2htmlEX v2
# Tests that patches apply correctly and fix intended issues

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly PATCHES_DIR="$PROJECT_ROOT/v2/patches"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[PATCH TEST] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $*${NC}"
}

error() {
    echo -e "${RED}[ERROR] $*${NC}"
    exit 1
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

check_prerequisites() {
    log "Checking patch test prerequisites..."
    
    if [[ ! -d "$PATCHES_DIR" ]]; then
        error "Patches directory not found at $PATCHES_DIR"
    fi
    
    # Check required tools
    local required_tools=("patch" "git" "curl" "tar")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found in PATH"
        fi
    done
    
    log "✓ Prerequisites check passed"
}

test_patch_files_exist() {
    log "Testing patch files existence..."
    
    local expected_patches=(
        "pdf2htmlEX-poppler24.patch"
        "pdf2htmlEX-cmake-fix.patch"
        "comprehensive-poppler24.patch"
    )
    
    for patch in "${expected_patches[@]}"; do
        if [[ -f "$PATCHES_DIR/$patch" ]]; then
            log "✓ Patch file exists: $patch"
        else
            error "Missing patch file: $patch"
        fi
    done
}

test_patch_syntax() {
    log "Testing patch file syntax..."
    
    for patch_file in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch_file" ]]; then
            local patch_name=$(basename "$patch_file")
            
            # Check if patch has proper format
            if head -20 "$patch_file" | grep -q "^---\|^+++\|^@@"; then
                log "✓ Patch syntax valid: $patch_name"
            else
                error "Invalid patch syntax: $patch_name"
            fi
            
            # Check for proper line endings
            if file "$patch_file" | grep -q "CRLF"; then
                warn "Patch has CRLF line endings: $patch_name"
            fi
        fi
    done
}

test_patch_headers() {
    log "Testing patch headers and metadata..."
    
    for patch_file in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch_file" ]]; then
            local patch_name=$(basename "$patch_file")
            
            # Check for descriptive headers
            if head -10 "$patch_file" | grep -q -E "^#|^;|^//|^/\*"; then
                log "✓ Patch has descriptive header: $patch_name"
            else
                warn "Patch lacks descriptive header: $patch_name"
            fi
            
            # Check for author information
            if grep -q -i "author\|from:" "$patch_file"; then
                log "✓ Patch has author info: $patch_name"
            else
                warn "Patch lacks author info: $patch_name"
            fi
        fi
    done
}

download_and_setup_source() {
    log "Downloading pdf2htmlEX source for patch testing..."
    
    local source_dir="$TEMP_DIR/pdf2htmlEX-source"
    
    # Download pdf2htmlEX source
    curl -sL "https://github.com/pdf2htmlEX/pdf2htmlEX/archive/v0.18.8.rc1.tar.gz" \
        -o "$TEMP_DIR/pdf2htmlex.tar.gz"
    
    if [[ $? -ne 0 ]]; then
        error "Failed to download pdf2htmlEX source"
    fi
    
    # Extract source
    tar -xzf "$TEMP_DIR/pdf2htmlex.tar.gz" -C "$TEMP_DIR"
    mv "$TEMP_DIR/pdf2htmlEX-0.18.8.rc1" "$source_dir"
    
    echo "$source_dir"
}

test_patch_application() {
    log "Testing patch application..."
    
    local source_dir
    source_dir=$(download_and_setup_source)
    
    for patch_file in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch_file" ]]; then
            local patch_name=$(basename "$patch_file")
            local test_dir="$TEMP_DIR/test-$patch_name"
            
            # Create a copy of source for each patch test
            cp -r "$source_dir" "$test_dir"
            cd "$test_dir"
            
            log "Testing patch application: $patch_name"
            
            # Try to apply patch
            if patch -p1 < "$patch_file" > "$TEMP_DIR/patch-$patch_name.log" 2>&1; then
                log "✓ Patch applies successfully: $patch_name"
                
                # Check if patch made expected changes
                if git diff --no-index "$source_dir" "$test_dir" > /dev/null 2>&1; then
                    warn "Patch made no changes: $patch_name"
                else
                    log "✓ Patch made changes: $patch_name"
                fi
            else
                error "Patch application failed: $patch_name"
            fi
            
            # Test reverse patch
            if patch -R -p1 < "$patch_file" > "$TEMP_DIR/patch-reverse-$patch_name.log" 2>&1; then
                log "✓ Patch reverses successfully: $patch_name"
            else
                warn "Patch reverse failed: $patch_name"
            fi
        fi
    done
}

test_cmake_fix_patch() {
    log "Testing CMake fix patch specifically..."
    
    local cmake_patch="$PATCHES_DIR/pdf2htmlEX-cmake-fix.patch"
    
    if [[ -f "$cmake_patch" ]]; then
        # Check if patch targets CMakeLists.txt
        if grep -q "CMakeLists.txt" "$cmake_patch"; then
            log "✓ CMake patch targets CMakeLists.txt"
        else
            warn "CMake patch doesn't target CMakeLists.txt"
        fi
        
        # Check if patch fixes known issues
        if grep -q -i "find_package\|target_link\|include_directories" "$cmake_patch"; then
            log "✓ CMake patch addresses build system issues"
        else
            warn "CMake patch doesn't address obvious build issues"
        fi
    else
        error "CMake fix patch not found"
    fi
}

test_poppler_compatibility_patch() {
    log "Testing Poppler compatibility patch..."
    
    local poppler_patch="$PATCHES_DIR/pdf2htmlEX-poppler24.patch"
    
    if [[ -f "$poppler_patch" ]]; then
        # Check if patch addresses Poppler API changes
        if grep -q -i "poppler\|gfx\|stream\|object" "$poppler_patch"; then
            log "✓ Poppler patch addresses API changes"
        else
            warn "Poppler patch doesn't address obvious API changes"
        fi
        
        # Check for version-specific fixes
        if grep -q "24\." "$poppler_patch"; then
            log "✓ Poppler patch targets version 24.x"
        else
            warn "Poppler patch doesn't specify version 24.x"
        fi
    else
        error "Poppler compatibility patch not found"
    fi
}

test_comprehensive_patch() {
    log "Testing comprehensive patch..."
    
    local comp_patch="$PATCHES_DIR/comprehensive-poppler24.patch"
    
    if [[ -f "$comp_patch" ]]; then
        # Check patch size (comprehensive patches should be substantial)
        local patch_size=$(wc -l < "$comp_patch")
        
        if [[ $patch_size -gt 50 ]]; then
            log "✓ Comprehensive patch is substantial ($patch_size lines)"
        else
            warn "Comprehensive patch is small ($patch_size lines)"
        fi
        
        # Check for multiple file changes
        local files_changed=$(grep -c "^---\|^+++" "$comp_patch" | head -1)
        
        if [[ $files_changed -gt 4 ]]; then
            log "✓ Comprehensive patch changes multiple files"
        else
            warn "Comprehensive patch changes few files"
        fi
    else
        error "Comprehensive patch not found"
    fi
}

test_patch_conflicts() {
    log "Testing for patch conflicts..."
    
    local source_dir
    source_dir=$(download_and_setup_source)
    local conflict_test_dir="$TEMP_DIR/conflict-test"
    cp -r "$source_dir" "$conflict_test_dir"
    cd "$conflict_test_dir"
    
    # Try to apply all patches in sequence
    local applied_patches=()
    
    for patch_file in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch_file" ]]; then
            local patch_name=$(basename "$patch_file")
            
            if patch -p1 < "$patch_file" > "$TEMP_DIR/conflict-$patch_name.log" 2>&1; then
                applied_patches+=("$patch_name")
                log "✓ Applied patch without conflict: $patch_name"
            else
                warn "Patch conflict detected: $patch_name"
                # Show conflict details
                if grep -q "CONFLICT\|conflict" "$TEMP_DIR/conflict-$patch_name.log"; then
                    warn "Conflict details in: $TEMP_DIR/conflict-$patch_name.log"
                fi
            fi
        fi
    done
    
    log "Successfully applied ${#applied_patches[@]} patches in sequence"
}

test_patch_documentation() {
    log "Testing patch documentation..."
    
    local readme_file="$PATCHES_DIR/README.md"
    
    if [[ -f "$readme_file" ]]; then
        log "✓ Patch documentation exists"
        
        # Check if documentation describes each patch
        for patch_file in "$PATCHES_DIR"/*.patch; do
            if [[ -f "$patch_file" ]]; then
                local patch_name=$(basename "$patch_file" .patch)
                
                if grep -q "$patch_name" "$readme_file"; then
                    log "✓ Patch documented: $patch_name"
                else
                    warn "Patch not documented: $patch_name"
                fi
            fi
        done
    else
        warn "Patch documentation not found"
    fi
}

main() {
    log "Starting patch test suite..."
    
    check_prerequisites
    test_patch_files_exist
    test_patch_syntax
    test_patch_headers
    test_patch_application
    test_cmake_fix_patch
    test_poppler_compatibility_patch
    test_comprehensive_patch
    test_patch_conflicts
    test_patch_documentation
    
    log "Patch tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi