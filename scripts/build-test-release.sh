#!/usr/bin/env bash
# this_file: scripts/build-test-release.sh
#
# Complete build, test, and release automation script for pdf2htmlEX
# This script handles the full workflow from build to release

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly VERSION_SCRIPT="$SCRIPT_DIR/version.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BUILD-TEST-RELEASE] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $*${NC}"
}

error() {
    echo -e "${RED}[ERROR] $*${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $*${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Complete build, test, and release automation for pdf2htmlEX

COMMANDS:
    build                   Build the project
    test                    Run test suite
    build-test             Build and test
    release [TYPE]         Build, test, and create release
    ci                     CI workflow (build, test, package)
    local                  Local development workflow
    validate               Validate project state
    clean                  Clean build artifacts
    
OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Verbose output
    -n, --dry-run           Show what would be done without executing
    -f, --force             Force operation (skip validation)
    --no-push               Don't push to remote
    --skip-build            Skip build step
    --skip-tests            Skip test step
    --parallel              Run operations in parallel where possible
    --architecture ARCH     Build for specific architecture (x86_64, arm64, universal)
    --clean                 Clean before building
    
VERSION TYPES (for release):
    major                   Major version release
    minor                   Minor version release  
    patch                   Patch version release
    
EXAMPLES:
    $0 build                # Build the project
    $0 test                 # Run test suite
    $0 build-test           # Build and test
    $0 release patch        # Create patch release
    $0 ci                   # Run CI workflow
    $0 validate             # Validate project state
    
ENVIRONMENT VARIABLES:
    ARCHS                   Target architectures (x86_64;arm64)
    CLEAN                   Clean build (1 to enable)
    PARALLEL                Parallel operations (1 to enable)
    SKIP_BUILD              Skip build step (1 to enable)
    SKIP_TESTS              Skip test step (1 to enable)
    
EOF
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required tools
    local required_tools=("git" "bash" "cmake" "ninja" "curl" "tar" "shasum")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found"
        fi
    done
    
    # Check version script
    if [[ ! -f "$VERSION_SCRIPT" ]]; then
        error "Version script not found: $VERSION_SCRIPT"
    fi
    
    # Check build script
    if [[ ! -f "$PROJECT_ROOT/v2/scripts/build.sh" ]]; then
        error "Build script not found: $PROJECT_ROOT/v2/scripts/build.sh"
    fi
    
    # Check test runner
    if [[ ! -f "$PROJECT_ROOT/v2/tests/test_runner.sh" ]]; then
        error "Test runner not found: $PROJECT_ROOT/v2/tests/test_runner.sh"
    fi
    
    log "✓ Prerequisites check passed"
}

# Clean build artifacts
clean_build() {
    log "Cleaning build artifacts..."
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would clean build artifacts"
        return 0
    fi
    
    # Clean v2 build artifacts
    local v2_build_dir="$PROJECT_ROOT/v2/build"
    local v2_dist_dir="$PROJECT_ROOT/v2/dist"
    local v2_deps_dir="$PROJECT_ROOT/v2/deps"
    
    if [[ -d "$v2_build_dir" ]]; then
        rm -rf "$v2_build_dir"
        log "Cleaned: $v2_build_dir"
    fi
    
    if [[ -d "$v2_dist_dir" ]]; then
        rm -rf "$v2_dist_dir"
        log "Cleaned: $v2_dist_dir"
    fi
    
    if [[ -d "$v2_deps_dir" ]]; then
        rm -rf "$v2_deps_dir"
        log "Cleaned: $v2_deps_dir"
    fi
    
    # Clean log files
    find "$PROJECT_ROOT" -name "*.log" -o -name "*.err" -o -name "build.log.txt" -o -name "build.err.txt" | while read -r logfile; do
        rm -f "$logfile"
        log "Cleaned: $logfile"
    done
    
    log "✓ Build artifacts cleaned"
}

# Build the project
build_project() {
    log "Building project..."
    
    if [[ "${SKIP_BUILD:-}" == "true" ]]; then
        log "Skipping build step"
        return 0
    fi
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would build project"
        return 0
    fi
    
    # Set build environment
    local build_env=()
    
    if [[ "${CLEAN:-}" == "true" ]]; then
        build_env+=("CLEAN=1")
    fi
    
    if [[ -n "${ARCHS:-}" ]]; then
        build_env+=("ARCHS=${ARCHS}")
    fi
    
    if [[ "${PARALLEL:-}" == "true" ]]; then
        build_env+=("PARALLEL=1")
    fi
    
    # Run build
    local build_cmd="${build_env[*]} $PROJECT_ROOT/v2/scripts/build.sh"
    info "Running: $build_cmd"
    
    if eval "$build_cmd"; then
        log "✓ Build completed successfully"
    else
        error "Build failed"
    fi
    
    # Validate build output
    local pdf2htmlex_binary="$PROJECT_ROOT/v2/dist/bin/pdf2htmlEX"
    if [[ -f "$pdf2htmlex_binary" ]]; then
        log "✓ Build output validated: $pdf2htmlex_binary"
        
        # Check if it's a universal binary
        if command -v lipo &> /dev/null; then
            local arch_info
            arch_info=$(lipo -info "$pdf2htmlex_binary" 2>/dev/null || echo "single arch")
            log "Binary architecture: $arch_info"
        fi
    else
        error "Build output not found: $pdf2htmlex_binary"
    fi
}

# Run test suite
run_tests() {
    log "Running test suite..."
    
    if [[ "${SKIP_TESTS:-}" == "true" ]]; then
        log "Skipping test step"
        return 0
    fi
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would run test suite"
        return 0
    fi
    
    # Set test environment
    local test_env=()
    
    if [[ "${VERBOSE:-}" == "true" ]]; then
        test_env+=("--verbose")
    fi
    
    if [[ "${PARALLEL:-}" == "true" ]]; then
        test_env+=("--parallel")
    fi
    
    # Run tests
    local test_cmd="$PROJECT_ROOT/v2/tests/test_runner.sh ${test_env[*]}"
    info "Running: $test_cmd"
    
    if eval "$test_cmd"; then
        log "✓ All tests passed"
    else
        error "Test suite failed"
    fi
}

# Package artifacts
package_artifacts() {
    log "Packaging artifacts..."
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would package artifacts"
        return 0
    fi
    
    local current_version
    current_version=$(bash "$VERSION_SCRIPT" current)
    
    local package_dir="$PROJECT_ROOT/packages"
    local package_name="pdf2htmlEX-${current_version}-$(uname -m)"
    local package_path="$package_dir/$package_name"
    
    mkdir -p "$package_dir"
    
    # Create package directory
    if [[ -d "$package_path" ]]; then
        rm -rf "$package_path"
    fi
    mkdir -p "$package_path"
    
    # Copy artifacts
    if [[ -d "$PROJECT_ROOT/v2/dist" ]]; then
        cp -r "$PROJECT_ROOT/v2/dist"/* "$package_path/"
        log "Copied build artifacts to package"
    fi
    
    # Create archive
    local archive_name="${package_name}.tar.gz"
    local archive_path="$package_dir/$archive_name"
    
    (cd "$package_dir" && tar -czf "$archive_name" "$package_name")
    
    # Generate checksum
    local checksum_file="$package_dir/$archive_name.sha256"
    (cd "$package_dir" && shasum -a 256 "$archive_name" > "$checksum_file")
    
    log "✓ Package created: $archive_path"
    log "✓ Checksum created: $checksum_file"
    
    # Cleanup temporary directory
    rm -rf "$package_path"
}

# Create release
create_release() {
    local version_type="${1:-patch}"
    
    log "Creating release: $version_type"
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would create $version_type release"
        return 0
    fi
    
    # Validate git state
    if [[ "${FORCE:-}" != "true" ]]; then
        bash "$VERSION_SCRIPT" validate
    fi
    
    # Create release
    local release_env=()
    
    if [[ "${NO_PUSH:-}" == "true" ]]; then
        release_env+=("--no-push")
    fi
    
    if [[ "${FORCE:-}" == "true" ]]; then
        release_env+=("--force")
    fi
    
    local release_cmd="$VERSION_SCRIPT bump $version_type ${release_env[*]}"
    info "Running: $release_cmd"
    
    if eval "$release_cmd"; then
        log "✓ Release created successfully"
    else
        error "Release creation failed"
    fi
}

# CI workflow
ci_workflow() {
    log "Running CI workflow..."
    
    # Build
    build_project
    
    # Test
    run_tests
    
    # Package
    package_artifacts
    
    log "✓ CI workflow completed"
}

# Local development workflow
local_workflow() {
    log "Running local development workflow..."
    
    # Clean if requested
    if [[ "${CLEAN:-}" == "true" ]]; then
        clean_build
    fi
    
    # Build
    build_project
    
    # Test
    run_tests
    
    # Validate
    validate_project
    
    log "✓ Local workflow completed"
}

# Validate project state
validate_project() {
    log "Validating project state..."
    
    # Validate version
    bash "$VERSION_SCRIPT" validate
    
    # Check build output
    local pdf2htmlex_binary="$PROJECT_ROOT/v2/dist/bin/pdf2htmlEX"
    if [[ -f "$pdf2htmlex_binary" ]]; then
        log "✓ Build output exists: $pdf2htmlex_binary"
        
        # Test basic functionality
        if "$pdf2htmlex_binary" --version &> /dev/null; then
            log "✓ Binary is functional"
        else
            warn "Binary may not be functional"
        fi
    else
        warn "Build output not found: $pdf2htmlex_binary"
    fi
    
    # Check test results
    local test_output="$PROJECT_ROOT/test_results.txt"
    if [[ -f "$test_output" ]]; then
        log "✓ Test results found: $test_output"
    fi
    
    log "✓ Project validation completed"
}

# Main function
main() {
    # Parse command line arguments
    DRY_RUN=false
    VERBOSE=false
    FORCE=false
    NO_PUSH=false
    SKIP_BUILD=false
    SKIP_TESTS=false
    PARALLEL=false
    CLEAN=false
    ARCHS=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --no-push)
                NO_PUSH=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --parallel)
                PARALLEL=true
                shift
                ;;
            --architecture)
                if [[ $# -lt 2 ]]; then
                    error "--architecture requires argument"
                fi
                ARCHS="$2"
                shift 2
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            build)
                check_prerequisites
                build_project
                exit 0
                ;;
            test)
                check_prerequisites
                run_tests
                exit 0
                ;;
            build-test)
                check_prerequisites
                build_project
                run_tests
                exit 0
                ;;
            release)
                local version_type="${2:-patch}"
                check_prerequisites
                build_project
                run_tests
                package_artifacts
                create_release "$version_type"
                exit 0
                ;;
            ci)
                check_prerequisites
                ci_workflow
                exit 0
                ;;
            local)
                check_prerequisites
                local_workflow
                exit 0
                ;;
            validate)
                check_prerequisites
                validate_project
                exit 0
                ;;
            clean)
                clean_build
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                error "Unknown command: $1"
                ;;
        esac
    done
    
    # Default action: local workflow
    check_prerequisites
    local_workflow
}

# Export environment variables for child processes
export DRY_RUN VERBOSE FORCE NO_PUSH SKIP_BUILD SKIP_TESTS PARALLEL CLEAN ARCHS

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi