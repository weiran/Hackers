#!/bin/bash

# Regression tests for run_tests.sh. xcodebuild is stubbed so these cases never
# invoke Xcode or a simulator.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUN_TESTS_SCRIPT="${RUN_TESTS_SCRIPT:-$REPO_ROOT/run_tests.sh}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/xcodebuild" <<'STUB'
#!/bin/bash
printf '%s\n' "${HARNESS_OUTPUT:-}"
exit "${HARNESS_EXIT_CODE:-0}"
STUB
chmod +x "$TMP_DIR/xcodebuild"

run_case() {
    local name="$1"
    local expected="$2"
    local output="$3"
    local exit_code="$4"
    local expected_summary="${5:-}"
    local actual

    if (
        cd "$REPO_ROOT" && \
        HARNESS_OUTPUT="$output" HARNESS_EXIT_CODE="$exit_code" \
            PATH="$TMP_DIR:$PATH" CI_DESTINATION="stub" \
            bash "$RUN_TESTS_SCRIPT" Domain >"$TMP_DIR/$name.log" 2>&1
    ); then
        actual=0
    else
        actual=$?
    fi

    if [ "$actual" -ne "$expected" ]; then
        echo "FAIL: $name (expected exit $expected, got $actual)"
        sed 's/^/  /' "$TMP_DIR/$name.log"
        return 1
    fi
    if [ -n "$expected_summary" ] && ! grep -Fq "$expected_summary" "$TMP_DIR/$name.log"; then
        echo "FAIL: $name (missing summary: $expected_summary)"
        sed 's/^/  /' "$TMP_DIR/$name.log"
        return 1
    fi
    echo "PASS: $name"
}

failures=0

run_case "nonzero_with_passing_banner" 1 \
    "Test Suite 'DomainTests' passed" 65
failures=$((failures + $?))
run_case "nonzero_with_positive_summary" 1 \
    "✔ Test run with 2 tests in 2 suites passed after 0.1 seconds." 65
failures=$((failures + $?))
run_case "zero_without_summary" 1 "Build Succeeded" 0
failures=$((failures + $?))
run_case "zero_with_zero_tests" 1 \
    "✔ Test run with 0 tests in 1 suite passed after 0.1 seconds." 0
failures=$((failures + $?))
run_case "positive_swift_testing" 0 \
    "✔ Test run with 1 test in 1 suite passed after 0.1 seconds." 0
failures=$((failures + $?))
# A singular Swift Testing result must take precedence over XCTest's empty
# summary; accepting the process while displaying zero tests is misleading.
run_case "singular_swift_summary_over_empty_xctest" 0 \
    $'Executed 0 tests, with 0 failures (0 unexpected)\n✔ Test run with 1 test in 1 suite passed after 0.1 seconds.' 0 \
    "✅ Domain - ✔ Test run with 1 test in 1 suite passed"
failures=$((failures + $?))
run_case "positive_xctest" 0 \
    "Executed 1 test, with 0 failures (0 unexpected) in 0.1 seconds" 0
failures=$((failures + $?))
run_case "truncated_xctest_summary" 1 "Executed 2 tests" 0
failures=$((failures + $?))
run_case "xctest_failure_summary" 1 "Executed 1 test, with 1 failure" 0
failures=$((failures + $?))
run_case "xctest_unexpected_result" 1 \
    "Executed 1 test, with 0 failures (1 unexpected)" 0
failures=$((failures + $?))
run_case "swift_summary_with_spurious_banner" 0 \
    $'✔ Test run with 1 test in 1 suite passed after 0.1 seconds.\nTEST FAILED' 0
failures=$((failures + $?))
run_case "explicit_failure_marker" 1 \
    "Test Case '-[DomainTests testFailure]' failed" 0
failures=$((failures + $?))
run_case "positive_summary_with_swift_failure" 1 \
    $'✔ Test run with 2 tests in 1 suite passed after 0.1 seconds.\n✘ Test example recorded an issue at Example.swift:12:3' 0
failures=$((failures + $?))
run_case "positive_summary_with_compiler_error" 1 \
    $'Executed 2 tests, with 0 failures (0 unexpected)\nExample.swift:12:3: error: compilation failed' 0
failures=$((failures + $?))
run_case "positive_summary_with_crash" 1 \
    $'Executed 2 tests, with 0 failures (0 unexpected)\nProcess crashed' 0
failures=$((failures + $?))
run_case "interrupted_with_positive_summary" 1 \
    "Executed 2 tests, with 0 failures (0 unexpected)" 130
failures=$((failures + $?))

if [ "$failures" -ne 0 ]; then
    exit 1
fi

echo "All run_tests.sh harness cases passed."
