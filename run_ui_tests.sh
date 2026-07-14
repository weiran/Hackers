#!/bin/bash
set -euo pipefail

if [[ -n "${DESTINATION:-}" ]]; then
  TEST_DESTINATION="$DESTINATION"
elif [[ -n "${CI_DEVICE_UDID:-}" ]]; then
  TEST_DESTINATION="platform=iOS Simulator,id=$CI_DEVICE_UDID"
elif [[ -n "${CI_DESTINATION:-}" ]]; then
  TEST_DESTINATION="$CI_DESTINATION"
else
  TEST_DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
fi
MODE="${1:-smoke}"

case "$MODE" in
  smoke)
    TEST_SELECTION=(
      "-only-testing:HackersUITests/HackersUITests/testSmokeLaunchFeedAndSettings"
      "-only-testing:HackersUITests/HackersUITests/testSmokeOpenCustomBrowserFromFeed"
    )
    ;;
  full|--full)
    TEST_SELECTION=(
      "-skip-testing:HackersUITests/HackersScreenshotTests"
    )
    ;;
  *)
    echo "Unknown UI test mode: $MODE (expected smoke or full)" >&2
    exit 2
    ;;
esac

RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-artifacts/xcresults/Hackers-UITests.xcresult}"
rm -rf "$RESULT_BUNDLE_PATH"
mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"

COMMAND=(
  xcodebuild test
  -project Hackers.xcodeproj
  -scheme Hackers
  -destination "$TEST_DESTINATION"
  -resultBundlePath "$RESULT_BUNDLE_PATH"
)

COMMAND+=("${TEST_SELECTION[@]}")

"${COMMAND[@]}"

xcrun xcresulttool get test-results tests \
  --path "$RESULT_BUNDLE_PATH" \
  --compact | /usr/bin/python3 -c '
import json
import sys

mode = sys.argv[1]
root = json.load(sys.stdin)
cases = []

def visit(node):
    if isinstance(node, dict):
        if node.get("nodeType") == "Test Case":
            cases.append(node)
        for value in node.values():
            visit(value)
    elif isinstance(node, list):
        for value in node:
            visit(value)

visit(root)
identifiers = [test.get("nodeIdentifier", test["name"]) for test in cases]
failures = [test["name"] for test in cases if test.get("result") != "Passed"]
if failures:
    raise SystemExit("UI test result bundle contains non-passing cases: {}".format(", ".join(failures)))

if mode == "smoke":
    expected = [
        "HackersUITests/testSmokeLaunchFeedAndSettings()",
        "HackersUITests/testSmokeOpenCustomBrowserFromFeed()",
    ]
    if sorted(identifiers) != sorted(expected):
        raise SystemExit(f"Smoke result mismatch. Expected {expected!r}, got {identifiers!r}")
else:
    if not identifiers:
        raise SystemExit("Full UI test run contained no test cases")
    unexpected = [identifier for identifier in identifiers if not identifier.startswith("HackersUITests/")]
    if unexpected:
        raise SystemExit("Full UI test run included unexpected cases: {}".format(", ".join(unexpected)))

print(f"Verified {len(identifiers)} {mode} UI test case(s) in the result bundle.")
' "$MODE"
