#!/bin/bash
set -euo pipefail

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
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
  -destination "$DESTINATION"
  -resultBundlePath "$RESULT_BUNDLE_PATH"
)

COMMAND+=("${TEST_SELECTION[@]}")

"${COMMAND[@]}"
