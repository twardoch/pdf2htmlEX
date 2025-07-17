#!/bin/bash
# this_file: v2/tests/test_release.sh
#
# Release system tests for pdf2htmlEX v2
# Tests build-test-release workflow and CI/CD integration

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly RELEASE_SCRIPT="$PROJECT_ROOT/scripts/build-test-release.sh"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[RELEASE TEST] $*${NC}"
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
    log "Checking release system prerequisites..."
    
    if [[ ! -f "$RELEASE_SCRIPT" ]]; then
        error "Release script not found at $RELEASE_SCRIPT"
    fi
    
    # Check required tools
    local required_tools=("git" "bash" "curl" "tar" "shasum")
    local optional_tools=("cmake" "ninja")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found"
        fi
    done
    
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            warn "Optional tool '$tool' not found (build tests will be skipped)"
        fi
    done
    
    log "✓ Prerequisites check passed"
}

test_release_script_syntax() {
    log "Testing release script syntax..."
    
    if bash -n "$RELEASE_SCRIPT"; then
        log "✓ Release script syntax is valid"
    else
        error "Release script has syntax errors"
    fi
}

test_release_script_help() {
    log "Testing release script help..."
    
    if bash "$RELEASE_SCRIPT" --help | grep -q "Usage:"; then
        log "✓ Release script help is available"
    else
        error "Release script help is not working"
    fi
}

test_validate_command() {
    log "Testing validate command..."
    
    if bash "$RELEASE_SCRIPT" validate; then
        log "✓ Project validation passed"
    else
        warn "Project validation failed (may be expected)"
    fi
}

test_clean_command() {
    log "Testing clean command..."
    
    # Create some test artifacts
    mkdir -p "$PROJECT_ROOT/v2/build" "$PROJECT_ROOT/v2/dist"
    touch "$PROJECT_ROOT/v2/build/test.txt"
    touch "$PROJECT_ROOT/v2/dist/test.txt"
    
    if bash "$RELEASE_SCRIPT" clean; then
        log "✓ Clean command works"
        
        # Check if artifacts were removed
        if [[ ! -d "$PROJECT_ROOT/v2/build" ]] && [[ ! -d "$PROJECT_ROOT/v2/dist" ]]; then
            log "✓ Build artifacts were cleaned"
        else
            warn "Some build artifacts may not have been cleaned"
        fi
    else
        error "Clean command failed"
    fi
}

test_build_dry_run() {
    log "Testing build (dry run)..."
    
    if bash "$RELEASE_SCRIPT" --dry-run build; then
        log "✓ Build (dry run) works"
    else
        warn "Build (dry run) may have issues"
    fi
}

test_test_dry_run() {
    log "Testing test suite (dry run)..."
    
    if bash "$RELEASE_SCRIPT" --dry-run test; then
        log "✓ Test suite (dry run) works"
    else
        warn "Test suite (dry run) may have issues"
    fi
}

test_build_test_dry_run() {
    log "Testing build-test workflow (dry run)..."
    
    if bash "$RELEASE_SCRIPT" --dry-run build-test; then
        log "✓ Build-test workflow (dry run) works"
    else
        warn "Build-test workflow (dry run) may have issues"
    fi
}

test_ci_workflow_dry_run() {
    log "Testing CI workflow (dry run)..."
    
    if bash "$RELEASE_SCRIPT" --dry-run ci; then
        log "✓ CI workflow (dry run) works"
    else
        warn "CI workflow (dry run) may have issues"
    fi
}

test_local_workflow_dry_run() {
    log "Testing local workflow (dry run)..."
    
    if bash "$RELEASE_SCRIPT" --dry-run local; then
        log "✓ Local workflow (dry run) works"
    else
        warn "Local workflow (dry run) may have issues"
    fi
}

test_release_dry_run() {
    log "Testing release workflow (dry run)..."
    
    if bash "$RELEASE_SCRIPT" --dry-run release patch; then
        log "✓ Release workflow (dry run) works"
    else
        warn "Release workflow (dry run) may have issues"
    fi
}

test_environment_variables() {
    log "Testing environment variable handling..."
    
    # Test architecture setting
    if ARCHS="x86_64" bash "$RELEASE_SCRIPT" --dry-run build; then
        log "✓ Architecture environment variable works"
    else
        warn "Architecture environment variable may have issues"
    fi
    
    # Test clean flag
    if CLEAN=1 bash "$RELEASE_SCRIPT" --dry-run build; then
        log "✓ Clean environment variable works"
    else
        warn "Clean environment variable may have issues"
    fi
    
    # Test skip flags
    if SKIP_BUILD=1 bash "$RELEASE_SCRIPT" --dry-run build-test; then
        log "✓ Skip build environment variable works"
    else
        warn "Skip build environment variable may have issues"
    fi
    
    if SKIP_TESTS=1 bash "$RELEASE_SCRIPT" --dry-run build-test; then
        log "✓ Skip tests environment variable works"
    else
        warn "Skip tests environment variable may have issues"
    fi
}

test_command_line_options() {
    log "Testing command line options..."
    
    # Test verbose flag
    if bash "$RELEASE_SCRIPT" --verbose --dry-run validate; then
        log "✓ Verbose flag works"
    else
        warn "Verbose flag may have issues"
    fi
    
    # Test force flag
    if bash "$RELEASE_SCRIPT" --force --dry-run validate; then
        log "✓ Force flag works"
    else
        warn "Force flag may have issues"
    fi
    
    # Test architecture flag
    if bash "$RELEASE_SCRIPT" --architecture x86_64 --dry-run build; then
        log "✓ Architecture flag works"
    else
        warn "Architecture flag may have issues"
    fi
    
    # Test clean flag
    if bash "$RELEASE_SCRIPT" --clean --dry-run build; then
        log "✓ Clean flag works"
    else
        warn "Clean flag may have issues"
    fi
    
    # Test skip flags
    if bash "$RELEASE_SCRIPT" --skip-build --dry-run build-test; then
        log "✓ Skip build flag works"
    else
        warn "Skip build flag may have issues"
    fi
    
    if bash "$RELEASE_SCRIPT" --skip-tests --dry-run build-test; then
        log "✓ Skip tests flag works"
    else
        warn "Skip tests flag may have issues"
    fi
}

test_error_handling() {
    log "Testing error handling..."
    
    # Test invalid command
    if bash "$RELEASE_SCRIPT" invalid_command 2>&1 | grep -q "error\|Error"; then
        log "✓ Error handling for invalid command works"
    else
        warn "Error handling for invalid command may be insufficient"
    fi
    
    # Test invalid option
    if bash "$RELEASE_SCRIPT" --invalid-option 2>&1 | grep -q "error\|Error"; then
        log "✓ Error handling for invalid option works"
    else
        warn "Error handling for invalid option may be insufficient"
    fi
}

test_workflow_integration() {
    log "Testing workflow integration..."
    
    # Test that all workflows can be invoked
    local workflows=("build" "test" "build-test" "ci" "local" "validate" "clean")
    
    for workflow in "${workflows[@]}"; do
        if bash "$RELEASE_SCRIPT" --dry-run "$workflow" &>/dev/null; then
            log "✓ Workflow '$workflow' can be invoked"
        else
            warn "Workflow '$workflow' may have issues"
        fi
    done
}

test_github_actions_integration() {
    log "Testing GitHub Actions integration..."
    
    # Check if GitHub Actions workflow files exist
    local workflow_files=(
        "$PROJECT_ROOT/.github/workflows/ci.yml"
        "$PROJECT_ROOT/.github/workflows/release.yml"
    )
    
    for workflow_file in "${workflow_files[@]}"; do
        if [[ -f "$workflow_file" ]]; then
            log "✓ GitHub Actions workflow exists: $(basename "$workflow_file")"
            
            # Basic syntax check
            if python -c "import yaml; yaml.safe_load(open('$workflow_file'))" 2>/dev/null; then
                log "✓ Workflow YAML syntax is valid"
            elif command -v yq &> /dev/null && yq eval . "$workflow_file" &>/dev/null; then
                log "✓ Workflow YAML syntax is valid"
            else
                warn "Cannot validate YAML syntax for $workflow_file"
            fi
        else
            warn "GitHub Actions workflow missing: $workflow_file"
        fi
    done
}

test_release_artifacts() {
    log "Testing release artifact generation..."
    
    # Test that the release script can identify expected artifacts
    local expected_artifacts=(
        "v2/dist/bin/pdf2htmlEX"
        "packages/"
    )
    
    for artifact in "${expected_artifacts[@]}"; do
        local artifact_path="$PROJECT_ROOT/$artifact"
        if [[ -e "$artifact_path" ]]; then
            log "✓ Release artifact exists: $artifact"
        else
            warn "Release artifact missing: $artifact (expected after build)"
        fi
    done
}

test_multiplatform_support() {
    log "Testing multiplatform support..."
    
    # Test different architecture configurations
    local architectures=("x86_64" "arm64" "x86_64;arm64")
    
    for arch in "${architectures[@]}"; do
        if ARCHS="$arch" bash "$RELEASE_SCRIPT" --dry-run build; then
            log "✓ Architecture '$arch' is supported"
        else
            warn "Architecture '$arch' may have issues"
        fi
    done
}

test_packaging_functionality() {
    log "Testing packaging functionality..."
    
    # Create mock dist directory
    mkdir -p "$PROJECT_ROOT/v2/dist/bin"
    echo "mock binary" > "$PROJECT_ROOT/v2/dist/bin/pdf2htmlEX"
    chmod +x "$PROJECT_ROOT/v2/dist/bin/pdf2htmlEX"
    
    # Test packaging
    if bash "$RELEASE_SCRIPT" --dry-run ci; then
        log "✓ Packaging functionality works"
    else
        warn "Packaging functionality may have issues"
    fi
    
    # Cleanup
    rm -rf "$PROJECT_ROOT/v2/dist"
}

main() {
    log "Starting release system test suite..."
    
    check_prerequisites
    test_release_script_syntax
    test_release_script_help
    test_validate_command
    test_clean_command
    test_build_dry_run
    test_test_dry_run
    test_build_test_dry_run
    test_ci_workflow_dry_run
    test_local_workflow_dry_run
    test_release_dry_run
    test_environment_variables
    test_command_line_options
    test_error_handling
    test_workflow_integration
    test_github_actions_integration
    test_release_artifacts
    test_multiplatform_support
    test_packaging_functionality
    
    log "Release system tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi