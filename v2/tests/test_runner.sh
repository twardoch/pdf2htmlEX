#!/bin/bash
# this_file: v2/tests/test_runner.sh
#
# Master test runner for pdf2htmlEX v2 test suite
# Runs all tests and provides comprehensive reporting

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TEST RUNNER] $*${NC}"
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

# Test suite configuration
declare -A TEST_SUITES=(
    ["basic"]="$SCRIPT_DIR/test_basic.sh"
    ["integration"]="$SCRIPT_DIR/test_integration.sh"
    ["fonts"]="$SCRIPT_DIR/test_fonts.sh"
    ["build"]="$SCRIPT_DIR/test_build.sh"
    ["patches"]="$SCRIPT_DIR/test_patches.sh"
    ["edge_cases"]="$SCRIPT_DIR/test_edge_cases.sh"
    ["formula"]="$SCRIPT_DIR/test_formula.sh"
    ["api_fixes"]="$SCRIPT_DIR/test_api_fixes.sh"
)

# Test results tracking
declare -A TEST_RESULTS=()
declare -A TEST_TIMES=()

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TEST_SUITE...]

Run pdf2htmlEX v2 test suite(s)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Verbose output
    -q, --quiet         Quiet output (errors only)
    -t, --timeout SEC   Test timeout in seconds (default: 300)
    -o, --output FILE   Output results to file
    -f, --format FMT    Output format: text, json, xml (default: text)
    -c, --continue      Continue on test failures
    -p, --parallel      Run tests in parallel (experimental)
    --no-cleanup        Don't cleanup test artifacts

TEST_SUITES:
    basic              Basic functionality tests
    integration        Integration and installation tests
    fonts              Font handling tests
    build              Build system tests
    patches            Patch application tests
    edge_cases         Edge cases and error handling
    formula            Homebrew formula validation
    api_fixes          API compatibility fix scripts
    all                Run all test suites (default)

Examples:
    $0                          # Run all tests
    $0 basic fonts              # Run basic and font tests
    $0 --verbose --timeout 600  # Run with verbose output and 10min timeout
    $0 --output results.json --format json  # Output results as JSON
EOF
}

parse_arguments() {
    VERBOSE=false
    QUIET=false
    TIMEOUT=300
    OUTPUT_FILE=""
    OUTPUT_FORMAT="text"
    CONTINUE_ON_FAILURE=false
    PARALLEL=false
    NO_CLEANUP=false
    SELECTED_TESTS=()
    
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
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -c|--continue)
                CONTINUE_ON_FAILURE=true
                shift
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            --no-cleanup)
                NO_CLEANUP=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                SELECTED_TESTS+=("$1")
                shift
                ;;
        esac
    done
    
    # Default to all tests if none specified
    if [[ ${#SELECTED_TESTS[@]} -eq 0 ]]; then
        SELECTED_TESTS=("all")
    fi
    
    # Expand "all" to all test suites
    if [[ " ${SELECTED_TESTS[*]} " =~ " all " ]]; then
        SELECTED_TESTS=($(printf '%s\n' "${!TEST_SUITES[@]}" | sort))
    fi
}

check_test_prerequisites() {
    log "Checking test prerequisites..."
    
    # Check test scripts exist
    for test_name in "${SELECTED_TESTS[@]}"; do
        if [[ -n "${TEST_SUITES[$test_name]:-}" ]]; then
            local test_script="${TEST_SUITES[$test_name]}"
            if [[ ! -f "$test_script" ]]; then
                error "Test script not found: $test_script"
            fi
            
            # Make executable
            chmod +x "$test_script"
        else
            error "Unknown test suite: $test_name"
        fi
    done
    
    # Check required tools
    local required_tools=("bash" "timeout")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found"
        fi
    done
    
    log "✓ Prerequisites check passed"
}

run_single_test() {
    local test_name="$1"
    local test_script="${TEST_SUITES[$test_name]}"
    local log_file="$TEMP_DIR/test_${test_name}.log"
    local start_time end_time duration
    
    info "Running test suite: $test_name"
    
    start_time=$(date +%s)
    
    # Run test with timeout
    local exit_code=0
    if timeout "$TIMEOUT" bash "$test_script" > "$log_file" 2>&1; then
        TEST_RESULTS["$test_name"]="PASS"
        if [[ "$VERBOSE" == "true" ]]; then
            cat "$log_file"
        fi
    else
        exit_code=$?
        TEST_RESULTS["$test_name"]="FAIL"
        
        if [[ "$QUIET" != "true" ]]; then
            error "Test suite failed: $test_name"
            if [[ -f "$log_file" ]]; then
                echo "=== Test output ==="
                cat "$log_file"
                echo "=================="
            fi
        fi
    fi
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    TEST_TIMES["$test_name"]=$duration
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "Test suite '$test_name' completed in ${duration}s"
    fi
    
    return $exit_code
}

run_tests_sequential() {
    log "Running tests sequentially..."
    
    local failed_tests=()
    
    for test_name in "${SELECTED_TESTS[@]}"; do
        if run_single_test "$test_name"; then
            if [[ "$QUIET" != "true" ]]; then
                log "✓ $test_name"
            fi
        else
            failed_tests+=("$test_name")
            if [[ "$QUIET" != "true" ]]; then
                error "✗ $test_name"
            fi
            
            if [[ "$CONTINUE_ON_FAILURE" != "true" ]]; then
                error "Stopping due to test failure"
            fi
        fi
    done
    
    return ${#failed_tests[@]}
}

run_tests_parallel() {
    log "Running tests in parallel..."
    
    local pids=()
    
    # Start all tests
    for test_name in "${SELECTED_TESTS[@]}"; do
        run_single_test "$test_name" &
        pids+=($!)
    done
    
    # Wait for all tests to complete
    local failed_count=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            ((failed_count++))
        fi
    done
    
    return $failed_count
}

generate_text_report() {
    echo "=============================================="
    echo "pdf2htmlEX v2 Test Suite Results"
    echo "=============================================="
    echo "Date: $(date)"
    echo "Tests run: ${#SELECTED_TESTS[@]}"
    echo ""
    
    local passed=0
    local failed=0
    
    for test_name in "${SELECTED_TESTS[@]}"; do
        local result="${TEST_RESULTS[$test_name]}"
        local time="${TEST_TIMES[$test_name]}"
        
        printf "%-20s %s (%ds)\n" "$test_name" "$result" "$time"
        
        if [[ "$result" == "PASS" ]]; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    echo "Summary: $passed passed, $failed failed"
    echo "=============================================="
}

generate_json_report() {
    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"total_tests\": ${#SELECTED_TESTS[@]},"
    echo "  \"results\": {"
    
    local first=true
    for test_name in "${SELECTED_TESTS[@]}"; do
        if [[ "$first" == "false" ]]; then
            echo ","
        fi
        first=false
        
        local result="${TEST_RESULTS[$test_name]}"
        local time="${TEST_TIMES[$test_name]}"
        
        echo "    \"$test_name\": {"
        echo "      \"status\": \"$result\","
        echo "      \"duration\": $time"
        echo -n "    }"
    done
    
    echo ""
    echo "  }"
    echo "}"
}

generate_xml_report() {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<testsuite>'
    echo "  <timestamp>$(date -u +%Y-%m-%dT%H:%M:%SZ)</timestamp>"
    echo "  <total>${#SELECTED_TESTS[@]}</total>"
    
    for test_name in "${SELECTED_TESTS[@]}"; do
        local result="${TEST_RESULTS[$test_name]}"
        local time="${TEST_TIMES[$test_name]}"
        
        echo "  <testcase name=\"$test_name\" time=\"$time\">"
        if [[ "$result" == "FAIL" ]]; then
            echo "    <failure>Test failed</failure>"
        fi
        echo "  </testcase>"
    done
    
    echo '</testsuite>'
}

generate_report() {
    local output=""
    
    case "$OUTPUT_FORMAT" in
        "text")
            output=$(generate_text_report)
            ;;
        "json")
            output=$(generate_json_report)
            ;;
        "xml")
            output=$(generate_xml_report)
            ;;
        *)
            error "Unknown output format: $OUTPUT_FORMAT"
            ;;
    esac
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$output" > "$OUTPUT_FILE"
        log "Results written to: $OUTPUT_FILE"
    else
        echo "$output"
    fi
}

main() {
    log "Starting pdf2htmlEX v2 test suite..."
    
    parse_arguments "$@"
    check_test_prerequisites
    
    # Run tests
    local start_time end_time total_duration
    start_time=$(date +%s)
    
    if [[ "$PARALLEL" == "true" ]]; then
        run_tests_parallel
    else
        run_tests_sequential
    fi
    
    local test_result=$?
    
    end_time=$(date +%s)
    total_duration=$((end_time - start_time))
    
    # Generate report
    generate_report
    
    # Summary
    if [[ "$QUIET" != "true" ]]; then
        log "All tests completed in ${total_duration}s"
        
        if [[ $test_result -eq 0 ]]; then
            log "All tests passed!"
        else
            error "$test_result test(s) failed"
        fi
    fi
    
    # Cleanup
    if [[ "$NO_CLEANUP" != "true" ]]; then
        cleanup
    fi
    
    exit $test_result
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi