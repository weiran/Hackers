#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="${CI_DEVICE_NAME:-iPhone 17 Pro}"
XCODE_VERSION_FILE="${XCODE_VERSION_FILE:-.github/xcode-version}"
DIAGNOSTICS_PATH="${CI_DIAGNOSTICS_PATH:-artifacts/logs/simulator-diagnostics.txt}"
export DEVICE_NAME

print_diagnostics() {
  mkdir -p "$(dirname "$DIAGNOSTICS_PATH")"
  {
    echo "::group::Xcode and simulator diagnostics"
    xcodebuild -version || true
    xcrun simctl list runtimes || true
    xcrun simctl list devicetypes || true
    xcrun simctl list devices || true
    echo "::endgroup::"
  } | tee "$DIAGNOSTICS_PATH"
}

trap print_diagnostics ERR

if [[ -f "$XCODE_VERSION_FILE" ]]; then
  XCODE_VERSION="$(tr -d '[:space:]' < "$XCODE_VERSION_FILE")"
else
  XCODE_VERSION=""
fi

if [[ -n "$XCODE_VERSION" ]]; then
  for candidate in "/Applications/Xcode_${XCODE_VERSION}.app" "/Applications/Xcode-${XCODE_VERSION}.app"; do
    if [[ -d "$candidate" ]]; then
      sudo xcode-select -s "$candidate/Contents/Developer"
      break
    fi
  done
fi

echo "::group::Selected Xcode"
xcode-select -p
xcodebuild -version
echo "::endgroup::"

sudo xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS || true

RUNTIME_ID="$(
  xcrun simctl list runtimes -j | ruby -rjson -e '
    runtimes = JSON.parse(STDIN.read).fetch("runtimes", [])
    ios = runtimes.select { |runtime|
      runtime["platform"] == "iOS" && runtime["isAvailable"] != false
    }
    abort("No available iOS simulator runtime found") if ios.empty?
    puts ios.sort_by { |runtime| Gem::Version.new(runtime.fetch("version")) }.last.fetch("identifier")
  '
)"
export RUNTIME_ID

DEVICE_TYPE_ID="$(
  xcrun simctl list devicetypes -j | ruby -rjson -e '
    name = ENV.fetch("DEVICE_NAME")
    device = JSON.parse(STDIN.read).fetch("devicetypes", []).find { |item| item["name"] == name }
    abort("Simulator device type not found: #{name}") unless device
    puts device.fetch("identifier")
  '
)"

DEVICE_UDID="$(
  xcrun simctl list devices -j | ruby -rjson -e '
    name = ENV.fetch("DEVICE_NAME")
    runtime = ENV.fetch("RUNTIME_ID")
    devices = JSON.parse(STDIN.read).fetch("devices", {}).fetch(runtime, [])
    device = devices.find { |item| item["name"] == name && item["isAvailable"] != false }
    puts device.fetch("udid") if device
  '
)"

if [[ -z "$DEVICE_UDID" ]]; then
  DEVICE_UDID="$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE_ID" "$RUNTIME_ID")"
fi

xcrun simctl boot "$DEVICE_UDID" || true
xcrun simctl bootstatus "$DEVICE_UDID" -b

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "CI_DEVICE_UDID=$DEVICE_UDID" >> "$GITHUB_ENV"
  echo "CI_DESTINATION=platform=iOS Simulator,name=$DEVICE_NAME" >> "$GITHUB_ENV"
fi

print_diagnostics
