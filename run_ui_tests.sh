#!/bin/bash
set -euo pipefail

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
MODE="${1:-smoke}"

ONLY_TESTING=(
  "-only-testing:HackersUITests/HackersUITests/testSmokeLaunchFeedAndSettings"
  "-only-testing:HackersUITests/HackersUITests/testSmokeOpenCustomBrowserFromFeed"
)

if [[ "$MODE" == "full" || "$MODE" == "--full" ]]; then
  ONLY_TESTING=()
fi

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

if [[ ${#ONLY_TESTING[@]} -gt 0 ]]; then
  COMMAND+=("${ONLY_TESTING[@]}")
fi

"${COMMAND[@]}"
