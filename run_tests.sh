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
    "Domain:${BASE_DIR}/Domain"
    "Data:${BASE_DIR}/Data"
    "Networking:${BASE_DIR}/Networking"
    "DesignSystem:${BASE_DIR}/DesignSystem"
    "Shared:${BASE_DIR}/Shared"
    "Feed:${BASE_DIR}/Features/Feed"
    "Comments:${BASE_DIR}/Features/Comments"
    "Settings:${BASE_DIR}/Features/Settings"
    "Onboarding:${BASE_DIR}/Features/Onboarding"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

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

    # Look for Swift Testing failures (newer format)
    if grep -q "✘.*failed after.*with.*issue" "$output_file"; then
        print_status $RED "   📋 Failed Swift Tests:"
        grep -E "✘.*failed after.*with.*issue|✘.*recorded an issue at" "$output_file" | while read -r line; do
            # Extract test name and failure details
            if [[ $line =~ ✘[[:space:]]*Test[[:space:]]*\"([^\"]+)\" ]]; then
                test_name="${BASH_REMATCH[1]}"
                print_status $RED "      • $test_name"
            elif [[ $line =~ recorded\ an\ issue\ at\ ([^:]+):([0-9]+) ]]; then
                file_name="${BASH_REMATCH[1]}"
                line_number="${BASH_REMATCH[2]}"
                print_status $PURPLE "        └─ $file_name:$line_number"
            fi
        done
    fi

    # Look for XCTest failures (older format)
    if grep -q "Test Case.*failed" "$output_file"; then
        print_status $RED "   📋 Failed XCTests:"
        grep "Test Case.*failed" "$output_file" | while read -r line; do
            if [[ $line =~ Test\ Case\ \'([^\']+)\'.*failed ]]; then
                test_name="${BASH_REMATCH[1]}"
                print_status $RED "      • $test_name"
            fi
        done
    fi

    # Look for compilation errors
    if grep -q "error:" "$output_file"; then
        print_status $RED "   🔨 Compilation Errors:"
        grep "error:" "$output_file" | head -5 | while read -r line; do
            if [[ $line =~ ([^:]+):([0-9]+):[0-9]+:\ error:\ (.+) ]]; then
                file_name=$(basename "${BASH_REMATCH[1]}")
                line_number="${BASH_REMATCH[2]}"
                error_msg="${BASH_REMATCH[3]}"
                print_status $RED "      • $file_name:$line_number - $error_msg"
            fi
        done
    fi

    # Look for build failures
    if grep -q "BUILD FAILED" "$output_file" || grep -q "TEST FAILED" "$output_file"; then
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

    if [ "$VERBOSE" = true ]; then
        print_status $YELLOW "🧪 Running tests for ${module_name}..."
        print_status $BLUE "   📁 Path: ${module_path}"
    else
        print_status $YELLOW "🧪 Testing ${module_name}..."
    fi

    cd "$module_path"

    # Run the tests and capture output
    local exit_code=0
    if [ "$VERBOSE" = true ]; then
        xcodebuild test -scheme "$module_name" -destination "$DESTINATION" 2>&1 | tee "$temp_output" || exit_code=$?
    else
        xcodebuild test -scheme "$module_name" -destination "$DESTINATION" > "$temp_output" 2>&1 || exit_code=$?
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
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
        failed_modules+=("$module_name")
    fi

    echo
done

overall_end_time=$(date +%s)
total_duration=$((overall_end_time - overall_start_time))

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
