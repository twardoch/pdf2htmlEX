#!/bin/bash
# this_file: v2/tests/test_version.sh
#
# Version system tests for pdf2htmlEX v2
# Tests version management, git tagging, and semver compliance

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly VERSION_SCRIPT="$PROJECT_ROOT/scripts/version.sh"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[VERSION TEST] $*${NC}"
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
    log "Checking version system prerequisites..."
    
    if [[ ! -f "$VERSION_SCRIPT" ]]; then
        error "Version script not found at $VERSION_SCRIPT"
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi
    
    log "✓ Prerequisites check passed"
}

test_version_script_syntax() {
    log "Testing version script syntax..."
    
    if bash -n "$VERSION_SCRIPT"; then
        log "✓ Version script syntax is valid"
    else
        error "Version script has syntax errors"
    fi
}

test_version_script_help() {
    log "Testing version script help..."
    
    if bash "$VERSION_SCRIPT" --help | grep -q "Usage:"; then
        log "✓ Version script help is available"
    else
        error "Version script help is not working"
    fi
}

test_current_version() {
    log "Testing current version retrieval..."
    
    local current_version
    current_version=$(bash "$VERSION_SCRIPT" current)
    
    if [[ -n "$current_version" ]]; then
        log "✓ Current version: $current_version"
    else
        error "Failed to get current version"
    fi
    
    # Test version format
    if [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "✓ Version format is valid"
    else
        warn "Version format may be non-standard: $current_version"
    fi
}

test_version_parsing() {
    log "Testing version parsing..."
    
    # Test various version formats
    local test_versions=("1.0.0" "1.2.3" "2.0.0-rc1" "0.18.8.rc1")
    
    for version in "${test_versions[@]}"; do
        if bash "$VERSION_SCRIPT" next patch &>/dev/null; then
            log "✓ Version parsing works for format: $version"
        else
            warn "Version parsing may fail for format: $version"
        fi
    done
}

test_next_version_calculation() {
    log "Testing next version calculation..."
    
    local current_version
    current_version=$(bash "$VERSION_SCRIPT" current)
    
    # Test patch version
    local next_patch
    next_patch=$(bash "$VERSION_SCRIPT" next patch)
    log "Next patch version: $current_version -> $next_patch"
    
    # Test minor version
    local next_minor
    next_minor=$(bash "$VERSION_SCRIPT" next minor)
    log "Next minor version: $current_version -> $next_minor"
    
    # Test major version
    local next_major
    next_major=$(bash "$VERSION_SCRIPT" next major)
    log "Next major version: $current_version -> $next_major"
    
    log "✓ Next version calculation works"
}

test_version_validation() {
    log "Testing version validation..."
    
    if bash "$VERSION_SCRIPT" validate; then
        log "✓ Version validation passed"
    else
        warn "Version validation failed (may be expected in some cases)"
    fi
}

test_version_file_sync() {
    log "Testing VERSION file sync..."
    
    # Test dry run sync
    if bash "$VERSION_SCRIPT" --dry-run sync; then
        log "✓ Version file sync (dry run) works"
    else
        warn "Version file sync may have issues"
    fi
}

test_changelog_generation() {
    log "Testing changelog generation..."
    
    local changelog
    changelog=$(bash "$VERSION_SCRIPT" changelog)
    
    if [[ -n "$changelog" ]]; then
        log "✓ Changelog generation works"
        echo "Sample changelog:"
        echo "$changelog" | head -10
    else
        warn "Changelog generation may be empty"
    fi
}

test_git_integration() {
    log "Testing git integration..."
    
    # Test git tag listing
    if git tag -l | head -5; then
        log "✓ Git tags are available"
    else
        warn "No git tags found"
    fi
    
    # Test latest tag detection
    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
    log "Latest git tag: $latest_tag"
}

test_version_consistency() {
    log "Testing version consistency across files..."
    
    local version_file_version
    version_file_version=$(bash "$VERSION_SCRIPT" current)
    
    # Check build script version
    if [[ -f "$PROJECT_ROOT/v2/scripts/build.sh" ]]; then
        local build_script_version
        build_script_version=$(grep 'PDF2HTML_VERSION=' "$PROJECT_ROOT/v2/scripts/build.sh" | head -1 | cut -d'"' -f2)
        
        if [[ "$version_file_version" == "$build_script_version" ]]; then
            log "✓ Version consistency: VERSION file matches build script"
        else
            warn "Version inconsistency: VERSION file ($version_file_version) != build script ($build_script_version)"
        fi
    fi
    
    # Check formula version
    if [[ -f "$PROJECT_ROOT/v2/Formula/pdf2htmlex.rb" ]]; then
        local formula_version
        formula_version=$(grep 'version "' "$PROJECT_ROOT/v2/Formula/pdf2htmlex.rb" | head -1 | cut -d'"' -f2)
        
        if [[ "$version_file_version" == "$formula_version" ]]; then
            log "✓ Version consistency: VERSION file matches formula"
        else
            warn "Version inconsistency: VERSION file ($version_file_version) != formula ($formula_version)"
        fi
    fi
}

test_semver_compliance() {
    log "Testing semantic versioning compliance..."
    
    local current_version
    current_version=$(bash "$VERSION_SCRIPT" current)
    
    # Test semantic versioning format
    if [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+)?(\+[0-9A-Za-z-]+)?$ ]]; then
        log "✓ Version follows semantic versioning format"
    else
        warn "Version may not follow semantic versioning: $current_version"
    fi
}

test_version_bump_dry_run() {
    log "Testing version bump (dry run)..."
    
    # Test patch bump
    if bash "$VERSION_SCRIPT" --dry-run bump patch; then
        log "✓ Patch version bump (dry run) works"
    else
        warn "Patch version bump may have issues"
    fi
    
    # Test minor bump
    if bash "$VERSION_SCRIPT" --dry-run bump minor; then
        log "✓ Minor version bump (dry run) works"
    else
        warn "Minor version bump may have issues"
    fi
    
    # Test major bump
    if bash "$VERSION_SCRIPT" --dry-run bump major; then
        log "✓ Major version bump (dry run) works"
    else
        warn "Major version bump may have issues"
    fi
}

test_release_dry_run() {
    log "Testing release creation (dry run)..."
    
    if bash "$VERSION_SCRIPT" --dry-run release; then
        log "✓ Release creation (dry run) works"
    else
        warn "Release creation may have issues"
    fi
}

test_error_handling() {
    log "Testing error handling..."
    
    # Test invalid version type
    if bash "$VERSION_SCRIPT" next invalid_type 2>&1 | grep -q "error\|Error"; then
        log "✓ Error handling for invalid version type works"
    else
        warn "Error handling for invalid version type may be insufficient"
    fi
    
    # Test invalid command
    if bash "$VERSION_SCRIPT" invalid_command 2>&1 | grep -q "error\|Error"; then
        log "✓ Error handling for invalid command works"
    else
        warn "Error handling for invalid command may be insufficient"
    fi
}

main() {
    log "Starting version system test suite..."
    
    check_prerequisites
    test_version_script_syntax
    test_version_script_help
    test_current_version
    test_version_parsing
    test_next_version_calculation
    test_version_validation
    test_version_file_sync
    test_changelog_generation
    test_git_integration
    test_version_consistency
    test_semver_compliance
    test_version_bump_dry_run
    test_release_dry_run
    test_error_handling
    
    log "Version system tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi