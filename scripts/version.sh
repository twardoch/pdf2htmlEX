#!/usr/bin/env bash
# this_file: scripts/version.sh
# 
# Git-tag-based semversioning system for pdf2htmlEX
# Manages version numbers, tagging, and release automation

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly VERSION_FILE="$PROJECT_ROOT/VERSION"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[VERSION] $*${NC}"
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

Git-tag-based semversioning system for pdf2htmlEX

COMMANDS:
    current                 Show current version
    next [TYPE]             Show next version for TYPE (major, minor, patch)
    bump [TYPE]             Bump version and create git tag
    tag [VERSION]           Create git tag for specific version
    release [VERSION]       Create release (tag + push + trigger CI)
    validate                Validate version and git state
    sync                    Sync VERSION file with latest git tag
    changelog               Generate changelog for current version
    
OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Verbose output
    -n, --dry-run           Show what would be done without executing
    -f, --force             Force operation (skip validation)
    --no-push               Don't push tags to remote
    --pre-release           Mark as pre-release
    
EXAMPLES:
    $0 current              # Show current version
    $0 next patch           # Show next patch version
    $0 bump minor           # Bump minor version and create tag
    $0 release              # Create release from current version
    $0 tag v1.2.3           # Create tag for specific version
    $0 validate             # Validate current state
    
VERSION TYPES:
    major      - Incompatible API changes (1.0.0 -> 2.0.0)
    minor      - Backward-compatible functionality (1.0.0 -> 1.1.0)
    patch      - Backward-compatible bug fixes (1.0.0 -> 1.0.1)
    
EOF
}

# Get current version from VERSION file
get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        error "VERSION file not found at $VERSION_FILE"
    fi
}

# Get latest git tag version
get_latest_git_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0"
}

# Parse version string into components
parse_version() {
    local version="$1"
    # Remove 'v' prefix if present
    version="${version#v}"
    
    # Split into major.minor.patch
    IFS='.' read -r MAJOR MINOR PATCH <<< "$version"
    
    # Handle pre-release suffixes (e.g., 1.0.0-rc1)
    if [[ "$PATCH" =~ ^([0-9]+)(-.*)?$ ]]; then
        PATCH="${BASH_REMATCH[1]}"
        PRE_RELEASE="${BASH_REMATCH[2]}"
    fi
    
    # Validate numeric components
    if [[ ! "$MAJOR" =~ ^[0-9]+$ ]] || [[ ! "$MINOR" =~ ^[0-9]+$ ]] || [[ ! "$PATCH" =~ ^[0-9]+$ ]]; then
        error "Invalid version format: $1"
    fi
}

# Calculate next version
get_next_version() {
    local version_type="$1"
    local current_version
    current_version=$(get_current_version)
    
    parse_version "$current_version"
    
    case "$version_type" in
        major)
            echo "$((MAJOR + 1)).0.0"
            ;;
        minor)
            echo "$MAJOR.$((MINOR + 1)).0"
            ;;
        patch)
            echo "$MAJOR.$MINOR.$((PATCH + 1))"
            ;;
        *)
            error "Invalid version type: $version_type. Use: major, minor, patch"
            ;;
    esac
}

# Validate git repository state
validate_git_state() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi
    
    # Check if working directory is clean
    if ! git diff-index --quiet HEAD --; then
        error "Working directory has uncommitted changes"
    fi
    
    # Check if we're on the main branch
    local current_branch
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        warn "Not on main/master branch (current: $current_branch)"
    fi
    
    # Check if we can push to remote
    if ! git ls-remote --exit-code origin > /dev/null 2>&1; then
        warn "Cannot reach remote origin"
    fi
}

# Update VERSION file
update_version_file() {
    local new_version="$1"
    echo "$new_version" > "$VERSION_FILE"
    log "Updated VERSION file to: $new_version"
}

# Update version in build scripts
update_build_scripts() {
    local new_version="$1"
    
    # Update v2/scripts/build.sh if it exists
    local build_script="$PROJECT_ROOT/v2/scripts/build.sh"
    if [[ -f "$build_script" ]]; then
        # Update PDF2HTML_VERSION variable
        sed -i.bak "s/PDF2HTML_VERSION=\"[^\"]*\"/PDF2HTML_VERSION=\"$new_version\"/" "$build_script"
        rm -f "$build_script.bak"
        log "Updated $build_script with version: $new_version"
    fi
    
    # Update Homebrew formula if it exists
    local formula="$PROJECT_ROOT/v2/Formula/pdf2htmlex.rb"
    if [[ -f "$formula" ]]; then
        # Update version line in formula
        sed -i.bak "s/version \"[^\"]*\"/version \"$new_version\"/" "$formula"
        rm -f "$formula.bak"
        log "Updated $formula with version: $new_version"
    fi
}

# Generate changelog entry
generate_changelog_entry() {
    local version="$1"
    local date
    date=$(date +%Y-%m-%d)
    
    # Get commits since last tag
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    local commits
    if [[ -n "$last_tag" ]]; then
        commits=$(git log --oneline "${last_tag}..HEAD" | sed 's/^/- /')
    else
        commits=$(git log --oneline | sed 's/^/- /')
    fi
    
    cat << EOF

## [v$version] - $date

### Changes
$commits

EOF
}

# Create git tag
create_git_tag() {
    local version="$1"
    local tag_name="v$version"
    local message="Release $tag_name"
    
    if [[ "${PRE_RELEASE:-}" == "true" ]]; then
        message="Pre-release $tag_name"
    fi
    
    # Create annotated tag
    git tag -a "$tag_name" -m "$message"
    log "Created git tag: $tag_name"
    
    return 0
}

# Push tags to remote
push_tags() {
    local version="$1"
    local tag_name="v$version"
    
    if [[ "${NO_PUSH:-}" == "true" ]]; then
        warn "Skipping push due to --no-push flag"
        return 0
    fi
    
    # Push tag to origin
    if git push origin "$tag_name"; then
        log "Pushed tag $tag_name to origin"
    else
        error "Failed to push tag $tag_name to origin"
    fi
    
    # Also push current branch
    if git push origin HEAD; then
        log "Pushed current branch to origin"
    else
        warn "Failed to push current branch to origin"
    fi
}

# Bump version and create tag
bump_version() {
    local version_type="$1"
    local new_version
    new_version=$(get_next_version "$version_type")
    
    info "Bumping $version_type version: $(get_current_version) -> $new_version"
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would update version to $new_version"
        return 0
    fi
    
    # Validate git state unless forced
    if [[ "${FORCE:-}" != "true" ]]; then
        validate_git_state
    fi
    
    # Update version in files
    update_version_file "$new_version"
    update_build_scripts "$new_version"
    
    # Commit version changes
    git add "$VERSION_FILE"
    git add "$PROJECT_ROOT/v2/scripts/build.sh" 2>/dev/null || true
    git add "$PROJECT_ROOT/v2/Formula/pdf2htmlex.rb" 2>/dev/null || true
    
    local commit_msg="Bump version to $new_version"
    git commit -m "$commit_msg"
    log "Committed version changes: $commit_msg"
    
    # Create tag
    create_git_tag "$new_version"
    
    # Push if not disabled
    push_tags "$new_version"
    
    log "Version bump completed: $new_version"
}

# Create release
create_release() {
    local version="${1:-$(get_current_version)}"
    
    info "Creating release for version: $version"
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would create release for version $version"
        return 0
    fi
    
    # Validate git state unless forced
    if [[ "${FORCE:-}" != "true" ]]; then
        validate_git_state
    fi
    
    # Create tag if it doesn't exist
    if ! git tag -l | grep -q "v$version"; then
        create_git_tag "$version"
    fi
    
    # Push tags
    push_tags "$version"
    
    # Generate changelog entry
    local changelog_entry
    changelog_entry=$(generate_changelog_entry "$version")
    
    # Update CHANGELOG.md
    if [[ -f "$PROJECT_ROOT/CHANGELOG.md" ]]; then
        # Insert new entry at the top
        local temp_file
        temp_file=$(mktemp)
        echo "$changelog_entry" > "$temp_file"
        cat "$PROJECT_ROOT/CHANGELOG.md" >> "$temp_file"
        mv "$temp_file" "$PROJECT_ROOT/CHANGELOG.md"
        
        # Commit changelog update
        git add "$PROJECT_ROOT/CHANGELOG.md"
        git commit -m "Update CHANGELOG.md for v$version"
        git push origin HEAD
        
        log "Updated CHANGELOG.md for v$version"
    fi
    
    log "Release created: v$version"
    log "GitHub Actions should now trigger automatically"
}

# Sync VERSION file with latest git tag
sync_version() {
    local latest_tag
    latest_tag=$(get_latest_git_tag)
    local tag_version="${latest_tag#v}"
    
    info "Syncing VERSION file with latest git tag: $latest_tag"
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY RUN: Would sync VERSION file to $tag_version"
        return 0
    fi
    
    update_version_file "$tag_version"
    update_build_scripts "$tag_version"
    
    log "Synced VERSION file to: $tag_version"
}

# Validate version and git state
validate_version() {
    local current_version
    current_version=$(get_current_version)
    
    info "Validating version: $current_version"
    
    # Parse version to validate format
    parse_version "$current_version"
    log "✓ Version format is valid: $current_version"
    
    # Check git state
    validate_git_state
    log "✓ Git state is valid"
    
    # Check if version matches latest tag
    local latest_tag
    latest_tag=$(get_latest_git_tag)
    local tag_version="${latest_tag#v}"
    
    if [[ "$current_version" == "$tag_version" ]]; then
        log "✓ VERSION file matches latest git tag: $latest_tag"
    else
        warn "VERSION file ($current_version) doesn't match latest git tag ($tag_version)"
    fi
    
    # Check if version exists in build scripts
    local build_script="$PROJECT_ROOT/v2/scripts/build.sh"
    if [[ -f "$build_script" ]]; then
        if grep -q "PDF2HTML_VERSION=\"$current_version\"" "$build_script"; then
            log "✓ Build script has correct version: $current_version"
        else
            warn "Build script version doesn't match VERSION file"
        fi
    fi
    
    log "Validation completed"
}

# Main function
main() {
    # Parse command line arguments
    DRY_RUN=false
    VERBOSE=false
    FORCE=false
    NO_PUSH=false
    PRE_RELEASE=false
    
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
            --pre-release)
                PRE_RELEASE=true
                shift
                ;;
            current)
                get_current_version
                exit 0
                ;;
            next)
                if [[ $# -lt 2 ]]; then
                    error "next command requires version type (major, minor, patch)"
                fi
                get_next_version "$2"
                exit 0
                ;;
            bump)
                if [[ $# -lt 2 ]]; then
                    error "bump command requires version type (major, minor, patch)"
                fi
                bump_version "$2"
                exit 0
                ;;
            tag)
                if [[ $# -lt 2 ]]; then
                    error "tag command requires version"
                fi
                create_git_tag "${2#v}"
                exit 0
                ;;
            release)
                local version="${2:-$(get_current_version)}"
                create_release "$version"
                exit 0
                ;;
            validate)
                validate_version
                exit 0
                ;;
            sync)
                sync_version
                exit 0
                ;;
            changelog)
                generate_changelog_entry "$(get_current_version)"
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
    
    # Default action: show current version
    get_current_version
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi