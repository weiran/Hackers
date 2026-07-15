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

SMOKE_TESTS=(
  testSmokeLaunchFeedAndSettings
  testSmokeOpenCustomBrowserFromFeed
)

FULL_TESTS=(
  testSmokeLaunchFeedAndSettings
  testSmokeOpenCustomBrowserFromFeed
  testCustomBrowserCommentsSheetCollapsedPreview
  testCustomBrowserExpandedCommentsChrome
  testCustomBrowserTitlePillTapCollapsesExpandedComments
  testCustomBrowserTitlePillDragCollapsesExpandedComments
  testCustomBrowserTopChromeDragCollapsesExpandedComments
  testCustomBrowserSheetContentDragCollapsesExpandedComments
  testCustomBrowserCollapsedHandleDragExpandsComments
  testCustomBrowserPreservesCommentScrollPositionAcrossCollapse
  testCustomBrowserCommentsReturnToTopAfterLongScroll
  testCustomBrowserLargeCommentListReturnsToTopAfterLongScroll
  testCustomBrowserLargeCommentBranchCollapsesAndExpands
  testSystemBackSwipeFromCustomBrowserCollapsedComments
  testSystemBackSwipeFromCustomBrowserExpandedComments
  testSystemBackSwipeFromComments
  testOpenCommentsFromFeed
  testLaunchesDirectCommentsRoute
  testLaunchesDirectCollapsedStoryRoute
  testLaunchesDirectExpandedStoryRoute
  testNextCommentButtonStartsAtFirstCommentThenAdvances
  testCollapsingCommentKeepsRootContextAvailable
  testSearchUsesMockedAlgoliaResults
  testCategoryMenuUsesMockedFeeds
  testLoginFailureAndSuccessUseMockedAuthentication
)

case "$MODE" in
  smoke)
    SELECTED_TESTS=("${SMOKE_TESTS[@]}")
    ;;
  full|--full)
    MODE=full
    SELECTED_TESTS=("${FULL_TESTS[@]}")
    ;;
  *)
    echo "Unknown UI test mode: $MODE (expected smoke or full)" >&2
    exit 2
    ;;
esac

/usr/bin/python3 - HackersUITests/HackersUITests.swift "${FULL_TESTS[@]}" <<'PY'
import re
import sys

source_path, *manifest = sys.argv[1:]
source = open(source_path, encoding="utf-8").read()
discovered = re.findall(r"^    func (test[A-Za-z0-9_]+)\(", source, re.MULTILINE)

if len(manifest) != len(set(manifest)):
    raise SystemExit("Full UI test manifest contains duplicate test names")
if manifest != discovered:
    missing = [name for name in discovered if name not in manifest]
    stale = [name for name in manifest if name not in discovered]
    raise SystemExit(
        "Full UI test manifest does not match HackersUITests.swift. "
        f"Missing: {missing!r}; stale: {stale!r}; "
        f"expected source order: {discovered!r}"
    )
PY

TEST_SELECTION=()
EXPECTED_IDENTIFIERS=()
for test_name in "${SELECTED_TESTS[@]}"; do
  TEST_SELECTION+=("-only-testing:HackersUITests/HackersUITests/$test_name")
  EXPECTED_IDENTIFIERS+=("HackersUITests/$test_name()")
done

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
expected = sys.argv[2:]
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

if len(identifiers) != len(set(identifiers)):
    raise SystemExit(f"{mode.capitalize()} result contains duplicate test cases: {identifiers!r}")
if sorted(identifiers) != sorted(expected):
    missing = sorted(set(expected) - set(identifiers))
    unexpected = sorted(set(identifiers) - set(expected))
    raise SystemExit(
        f"{mode.capitalize()} result mismatch. Missing: {missing!r}; "
        f"unexpected: {unexpected!r}; got: {identifiers!r}"
    )

print(f"Verified {len(identifiers)} {mode} UI test case(s) in the result bundle.")
' "$MODE" "${EXPECTED_IDENTIFIERS[@]}"
