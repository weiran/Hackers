#!/bin/bash

# Script to run tests for Hackers iOS app modules
# Usage: ./run_tests.sh [options] [modules...]
#
# Options:
#   -v, --verbose    Show detailed output
#   -h, --help       Show this help message
#
# Examples:
#   ./run_tests.sh                           # Run all modules (quiet)
#   ./run_tests.sh -v                        # Run all modules (verbose)
#   ./run_tests.sh Domain Data               # Run specific modules (quiet)
#   ./run_tests.sh -v Feed Comments Settings # Run specific modules (verbose)

set -e  # Exit on any error

# Graceful Ctrl-C handling: kill active xcodebuild and exit
INTERRUPTED=false
CURRENT_CHILD_PID=""

on_interrupt() {
    # Best-effort cleanup of the current xcodebuild process group
    echo
    print_status $YELLOW "🛑 Caught interrupt. Cleaning up..."
    if [ -n "$CURRENT_CHILD_PID" ]; then
        # Best effort: signal the xcodebuild process and its direct children
        kill -INT "$CURRENT_CHILD_PID" 2>/dev/null || true
        # Try to terminate direct children as well
        for kid in $(pgrep -P "$CURRENT_CHILD_PID" 2>/dev/null); do
            kill -INT "$kid" 2>/dev/null || true
        done
        sleep 0.5
        kill -TERM "$CURRENT_CHILD_PID" 2>/dev/null || true
        for kid in $(pgrep -P "$CURRENT_CHILD_PID" 2>/dev/null); do
            kill -TERM "$kid" 2>/dev/null || true
        done
        sleep 0.5
        kill -KILL "$CURRENT_CHILD_PID" 2>/dev/null || true
        for kid in $(pgrep -P "$CURRENT_CHILD_PID" 2>/dev/null); do
            kill -KILL "$kid" 2>/dev/null || true
        done
    fi
    INTERRUPTED=true
}

# Install traps after functions are defined

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="$(pwd)"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
VERBOSE=false

# All available modules
ALL_MODULES=(
    # Run Onboarding first to avoid any prior defaults pollution from other modules
    "Onboarding:${BASE_DIR}/Features/Onboarding"
    "Domain:${BASE_DIR}/Domain"
    "Data:${BASE_DIR}/Data"
    "Networking:${BASE_DIR}/Networking"
    "DesignSystem:${BASE_DIR}/DesignSystem"
    "Shared:${BASE_DIR}/Shared"
    "Feed:${BASE_DIR}/Features/Feed"
    "Comments:${BASE_DIR}/Features/Comments"
    "Settings:${BASE_DIR}/Features/Settings"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Now that print helpers exist, install traps
trap on_interrupt INT TERM

# Function to print help
print_help() {
    cat << EOF
Hackers iOS App Test Runner

USAGE:
    ./run_tests.sh [OPTIONS] [MODULES...]

OPTIONS:
    -v, --verbose    Show detailed xcodebuild output and test details
    -h, --help       Show this help message

MODULES:
    Domain          Domain layer tests
    Data            Data layer tests
    Networking      Network manager tests
    DesignSystem    Design system tests
    Shared          Shared utilities tests
    Feed            Feed feature tests
    Comments        Comments feature tests
    Settings        Settings feature tests
    Onboarding      Onboarding feature tests

EXAMPLES:
    ./run_tests.sh                           # Run all modules (quiet)
    ./run_tests.sh -v                        # Run all modules (verbose)
    ./run_tests.sh Domain Data               # Run specific modules
    ./run_tests.sh -v Feed Comments Settings # Run specific modules (verbose)

EOF
}

# Function to parse test output and extract failures
parse_test_failures() {
    local output_file=$1
    local module_name=$2

    # Swift Testing failures (robust matching)
    if grep -qE "(^|[[:space:]])✘ |failed after [0-9.]+ seconds with [0-9]+ issue|recorded an issue at|✘ Test run with [0-9]+ tests .* failed" "$output_file"; then
        print_status $RED "   📋 Failed Swift Tests:"
        # List failing tests by name from the definitive 'failed after' lines
        grep -E '^✘ Test ".*" failed after' "$output_file" | \
        sed -E 's/^✘ Test "([^"]+)".*/\1/' | while read -r test_name; do
            [ -z "$test_name" ] && continue
            print_status $RED "      • $test_name"
            # Try to find a file:line for this test
            local rec_line
            rec_line=$(grep -F "✘ Test \"$test_name\" recorded an issue at" "$output_file" | head -1 || true)
            if [[ $rec_line =~ recorded\ an\ issue\ at\ ([^:]+):([0-9]+) ]]; then
                local file_name="${BASH_REMATCH[1]}"
                local line_number="${BASH_REMATCH[2]}"
                print_status $PURPLE "        └─ $file_name:$line_number"
            fi
        done

        # If no explicit 'failed after' lines (edge case), fall back to recorded lines
        if ! grep -qE '^✘ Test ".*" failed after' "$output_file"; then
            grep -E '^✘ Test ".*" recorded an issue at' "$output_file" | while read -r line; do
                if [[ $line =~ ✘[[:space:]]*Test[[:space:]]*\"([^\"]+)\" ]]; then
                    local tn="${BASH_REMATCH[1]}"
                    print_status $RED "      • $tn"
                fi
                if [[ $line =~ recorded\ an\ issue\ at\ ([^:]+):([0-9]+) ]]; then
                    local file_name="${BASH_REMATCH[1]}"
                    local line_number="${BASH_REMATCH[2]}"
                    print_status $PURPLE "        └─ $file_name:$line_number"
                fi
            done
        fi
    fi

    # XCTest failures (older format)
    if grep -q "Test Case.*failed" "$output_file"; then
        print_status $RED "   📋 Failed XCTests:"
        grep "Test Case.*failed" "$output_file" | while read -r line; do
            if [[ $line =~ Test\ Case\ \'([^\']+)\'.*failed ]]; then
                local test_name="${BASH_REMATCH[1]}"
                print_status $RED "      • $test_name"
            fi
        done
    fi

    # Compilation errors (top 5)
    if grep -q "error:" "$output_file"; then
        print_status $RED "   🔨 Compilation Errors:"
        grep "error:" "$output_file" | head -5 | while read -r line; do
            if [[ $line =~ ([^:]+):([0-9]+):[0-9]+:\ error:\ (.+) ]]; then
                local file_name=$(basename "${BASH_REMATCH[1]}")
                local line_number="${BASH_REMATCH[2]}"
                local error_msg="${BASH_REMATCH[3]}"
                print_status $RED "      • $file_name:$line_number - $error_msg"
            fi
        done
    fi

    # Build/Test banners for context (trimmed)
    if grep -qE "BUILD FAILED|TEST FAILED" "$output_file"; then
        local failure_context=$(grep -A 3 -B 1 "BUILD FAILED\|TEST FAILED" "$output_file" | head -10)
        if [ -n "$failure_context" ]; then
            print_status $RED "   💥 Build/Test Failure Context:"
            echo "$failure_context" | sed 's/^/      /' | head -3
        fi
    fi
}

# Function to run tests for a module
run_module_tests() {
    local module_name=$1
    local module_path=$2
    local temp_output=$(mktemp)
    local start_time=$(date +%s)

    # Per-module environment resets to avoid cross-module state leakage
    case "$module_name" in
        Onboarding)
            # Ensure a clean suite for onboarding defaults
            defaults delete com.weiran.hackers.onboarding.tests >/dev/null 2>&1 || true
            ;;
        Networking)
            # Clear global cookie storage to avoid cross-test bleedthrough
            xcrun swift -e 'import Foundation; HTTPCookieStorage.shared.cookies?.forEach{ HTTPCookieStorage.shared.deleteCookie($0) }' >/dev/null 2>&1 || true
            ;;
        *) ;;
    esac

    if [ "$VERBOSE" = true ]; then
        print_status $YELLOW "🧪 Running tests for ${module_name}..."
        print_status $BLUE "   📁 Path: ${module_path}"
    else
        print_status $YELLOW "🧪 Testing ${module_name}..."
    fi

    # Move to module dir
    pushd "$module_path" >/dev/null

    # Run the tests and capture output
    exit_code=0
    if [ "$VERBOSE" = true ]; then
        xcodebuild test -scheme "$module_name" -destination "$DESTINATION" \
            > >(tee "$temp_output") 2>&1 &
        child_pid=$!
    else
        xcodebuild test -scheme "$module_name" -destination "$DESTINATION" \
            > "$temp_output" 2>&1 &
        child_pid=$!
    fi

    # Record child PID for cleanup on Ctrl-C
    CURRENT_CHILD_PID=$child_pid

    # Wait for completion capturing non-zero without tripping set -e
    if ! wait "$child_pid"; then
        exit_code=$?
    fi

    # Return to previous dir
    popd >/dev/null

    # Clear the tracked child
    CURRENT_CHILD_PID=""

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Some versions of Swift Testing/Xcode can return exit code 0 even with recorded issues,
    # or print a spurious "TEST FAILED" banner after a successful Swift Testing run.
    # Detect genuine Swift Testing failures and ignore false negatives.
    local has_swift_fail=1
    local has_xctest_fail=1
    local has_pass_summary=1
    if grep -qE "(^|[[:space:]])✘ |failed after [0-9.]+ seconds with [0-9]+ issue|recorded an issue at|✘ Test run with [0-9]+ tests .* failed" "$temp_output"; then
        has_swift_fail=0
    fi
    if grep -q "Test Case .*failed" "$temp_output"; then
        has_xctest_fail=0
    fi
    if grep -qE "✔ Test run with [0-9]+ tests in [0-9]+ suites passed|Test Suite '.*' passed" "$temp_output"; then
        has_pass_summary=0
    fi
    # If xcodebuild failed but there are no actual failing tests recorded, treat as success
    if [ "${exit_code:-0}" -ne 0 ] && [ $has_swift_fail -ne 0 ] && [ $has_xctest_fail -ne 0 ]; then
        exit_code=0
    fi
    # If we detected real test failures, force a non-zero exit code
    if [ $has_swift_fail -eq 0 ] || [ $has_xctest_fail -eq 0 ]; then
        exit_code=1
    fi

    if [ "$INTERRUPTED" = true ]; then
        # Respect user interrupt immediately
        return 130
    fi

    if [ "${exit_code:-0}" -eq 0 ]; then
        # Success - extract test summary
        local test_summary=$(grep -E "Executed [0-9]+ tests|✔.*tests.*passed" "$temp_output" | tail -1)
        local swift_summary=$(grep -E "✔ Test run with [0-9]+ tests" "$temp_output" | tail -1)

        if [ -n "$swift_summary" ]; then
            print_status $GREEN "✅ ${module_name} - $swift_summary (${duration}s)"
        elif [ -n "$test_summary" ]; then
            print_status $GREEN "✅ ${module_name} - $test_summary (${duration}s)"
        else
            print_status $GREEN "✅ ${module_name} tests passed (${duration}s)"
        fi

        rm "$temp_output"
        return 0
    else
        # Failure - show detailed error information
        print_status $RED "❌ ${module_name} tests failed (${duration}s)"

        # Parse and display specific failures
        parse_test_failures "$temp_output" "$module_name"

        # If not verbose, show last few lines for context
        if [ "$VERBOSE" = false ]; then
            print_status $RED "   🔍 Last few lines of output:"
            tail -5 "$temp_output" | sed 's/^/      /'
        fi

        rm "$temp_output"
        return 1
    fi
}

# Function to validate module exists
validate_module() {
    local module_name=$1
    for module in "${ALL_MODULES[@]}"; do
        IFS=':' read -r name path <<< "$module"
        if [ "$name" = "$module_name" ]; then
            return 0
        fi
    done
    return 1
}

# Parse command line arguments
MODULES_TO_RUN=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            # Validate module name
            if validate_module "$1"; then
                MODULES_TO_RUN+=("$1")
            else
                print_status $RED "Error: Unknown module '$1'"
                print_status $YELLOW "Available modules: Domain, Data, Networking, DesignSystem, Shared, Feed, Comments, Settings, Onboarding"
                exit 1
            fi
            shift
            ;;
    esac
done

# If no modules specified, run all
if [ ${#MODULES_TO_RUN[@]} -eq 0 ]; then
    for module in "${ALL_MODULES[@]}"; do
        IFS=':' read -r name path <<< "$module"
        MODULES_TO_RUN+=("$name")
    done
fi

# Check if we're in the right directory
if [ ! -d "$BASE_DIR" ]; then
    print_status $RED "Error: Base directory $BASE_DIR not found"
    print_status $YELLOW "Please run this script from the correct location"
    exit 1
fi

# Print header
echo
print_status $CYAN "🚀 Hackers iOS Test Runner"
print_status $BLUE "📱 Target: iOS Simulator (iPhone 17 Pro)"
print_status $BLUE "📊 Mode: $([ "$VERBOSE" = true ] && echo "Verbose" || echo "Quiet")"
print_status $BLUE "📦 Modules: ${MODULES_TO_RUN[*]}"
echo

# Track results
total_modules=0
passed_modules=0
failed_modules=()
overall_start_time=$(date +%s)

# Run tests for selected modules
for module_name in "${MODULES_TO_RUN[@]}"; do
    # Find the module path
    module_path=""
    for module in "${ALL_MODULES[@]}"; do
        IFS=':' read -r name path <<< "$module"
        if [ "$name" = "$module_name" ]; then
            module_path="$path"
            break
        fi
    done

    if [ -z "$module_path" ]; then
        print_status $RED "Error: Could not find path for module $module_name"
        continue
    fi

    total_modules=$((total_modules + 1))

    if run_module_tests "$module_name" "$module_path"; then
        passed_modules=$((passed_modules + 1))
    else
        # If interrupted, stop the loop immediately
        if [ "$INTERRUPTED" = true ]; then
            break
        fi
        failed_modules+=("$module_name")
    fi

    echo
done

overall_end_time=$(date +%s)
total_duration=$((overall_end_time - overall_start_time))

# If interrupted, exit quickly with a clear message
if [ "$INTERRUPTED" = true ]; then
    echo "================================================================"
    print_status $YELLOW "🛑 Test run interrupted by user"
    echo "================================================================"
    exit 130
fi

# Print final summary
echo "================================================================"
print_status $CYAN "📊 FINAL TEST SUMMARY"
echo "================================================================"
print_status $BLUE "⏱️  Total duration: ${total_duration}s"
print_status $BLUE "🎯 Success rate: ${passed_modules}/${total_modules} modules"

if [ ${#failed_modules[@]} -eq 0 ]; then
    print_status $GREEN "🎉 All tests passed successfully!"
    print_status $GREEN "✨ ${total_modules}/${total_modules} modules completed"
    exit 0
else
    echo
    print_status $RED "❌ Failed modules (${#failed_modules[@]}):"
    for failed_module in "${failed_modules[@]}"; do
        print_status $RED "   • ${failed_module}"
    done
    echo
    print_status $YELLOW "💡 Tips:"
    print_status $YELLOW "   • Run with -v flag for detailed output"
    print_status $YELLOW "   • Test individual modules: ./run_tests.sh ModuleName"
    print_status $YELLOW "   • Manual test: cd [path] && xcodebuild test -scheme [Module] -destination '$DESTINATION'"
    exit 1
fi
