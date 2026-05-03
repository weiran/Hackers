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

run_with_timeout() {
  local seconds="$1"
  shift

  "$@" &
  local pid=$!

  (
    sleep "$seconds"
    kill -TERM "$pid" 2>/dev/null || true
  ) &
  local watchdog=$!

  local status=0
  wait "$pid" || status=$?
  kill "$watchdog" 2>/dev/null || true
  wait "$watchdog" 2>/dev/null || true

  if [[ "$status" -eq 143 ]]; then
    echo "Command timed out after ${seconds}s: $*" >&2
  fi

  return "$status"
}

has_available_ios_runtime() {
  xcrun simctl list runtimes -j | ruby -rjson -e '
    runtimes = JSON.parse(STDIN.read).fetch("runtimes", [])
    exit(runtimes.any? { |runtime|
      runtime["platform"] == "iOS" && runtime["isAvailable"] != false
    } ? 0 : 1)
  '
}

if [[ -f "$XCODE_VERSION_FILE" ]]; then
  XCODE_VERSION="$(tr -d '[:space:]' < "$XCODE_VERSION_FILE")"
else
  XCODE_VERSION=""
fi

if [[ -n "$XCODE_VERSION" ]]; then
  shopt -s nullglob
  candidates=(
    "/Applications/Xcode_${XCODE_VERSION}.app"
    "/Applications/Xcode_${XCODE_VERSION}"*.app
    "/Applications/Xcode-${XCODE_VERSION}.app"
    "/Applications/Xcode-${XCODE_VERSION}"*.app
  )
  shopt -u nullglob

  for candidate in "${candidates[@]}"; do
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

run_with_timeout 300 sudo xcodebuild -runFirstLaunch

if has_available_ios_runtime; then
  echo "An available iOS simulator runtime is already installed."
else
  echo "No available iOS simulator runtime found; downloading iOS platform."
  run_with_timeout 900 xcodebuild -downloadPlatform iOS
fi

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
if ! run_with_timeout 180 xcrun simctl bootstatus "$DEVICE_UDID" -b; then
  echo "Simulator did not report a completed boot within the timeout; continuing with xcodebuild-managed boot."
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "CI_DEVICE_UDID=$DEVICE_UDID" >> "$GITHUB_ENV"
  echo "CI_DESTINATION=platform=iOS Simulator,name=$DEVICE_NAME" >> "$GITHUB_ENV"
fi

print_diagnostics
