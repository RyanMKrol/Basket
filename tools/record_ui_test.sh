#!/usr/bin/env bash
#
# record_ui_test.sh — run ONE XCUITest while recording the simulator's own
# internal framebuffer to a video, for verifying fast or timing-sensitive
# animations (a burst, a fade, a flicker) that a single screenshot can't
# prove one way or the other, and that a human watching live can't easily
# scrub back through.
#
# Crucially, `xcrun simctl io recordVideo` captures the SIMULATOR's own
# framebuffer via simctl, the same mechanism `simctl io screenshot` and
# XCUITest's own `app.screenshot()` use — never the real host screen, cursor,
# or keyboard. Like the rest of this repo's UI tests, this needs no manual
# interaction and doesn't take over your Mac while it runs.
#
# After recording, pull specific frames out with tools/extract_video_frame.swift
# — e.g. every 0.2-0.3s across the window you care about — and inspect them
# like any other screenshot.
#
# Usage: ./tools/record_ui_test.sh <test-identifier> [simulator-name] [output.mov]
#   test-identifier   required, passed straight to -only-testing:, e.g.
#                      BasketUITests/CheckOffFlowTests/testCheckingItemOffMovesToGotSection
#   simulator-name     default: Basket's dedicated device (Basket-Claude, ensured by
#                      tools/loop_sim.sh) rather than the shared "iPhone 17 Pro"
#   output.mov          default screenshots/ui-tests/recordings/<sanitized-test-id>.mov

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TEST_ID="${1:?usage: record_ui_test.sh <test-identifier> [simulator-name] [output.mov]}"
"$PROJECT_DIR/tools/loop_sim.sh" >/dev/null   # ensure Basket's dedicated device exists
SIM_NAME="${2:-Basket-Claude}"
SAFE_NAME="$(echo "$TEST_ID" | tr '/:' '__')"
OUT_PATH="${3:-$PROJECT_DIR/screenshots/ui-tests/recordings/$SAFE_NAME.mov}"

mkdir -p "$(dirname "$OUT_PATH")"
rm -f "$OUT_PATH"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

# Resolve the simulator name to a concrete UDID, same approach as build_run.sh —
# recordVideo and xcodebuild test must target the exact same device.
SIM_ID="$(xcrun simctl list devices booted | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
if [ -z "$SIM_ID" ]; then
  SIM_ID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | tail -1 || true)"
fi
SIM="${SIM_ID:-$SIM_NAME}"

echo "▸ Booting simulator '$SIM_NAME' ($SIM)…"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" >/dev/null 2>&1 || true

echo "▸ Recording $SIM's display → $OUT_PATH"
xcrun simctl io "$SIM" recordVideo --force "$OUT_PATH" &
RECORD_PID=$!

# Always stop the recording, whether the test passes, fails, or this script
# is interrupted — an orphaned recordVideo process otherwise keeps running.
cleanup() {
  if kill -0 "$RECORD_PID" 2>/dev/null; then
    kill -INT "$RECORD_PID" 2>/dev/null || true
    wait "$RECORD_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

sleep 1   # let recordVideo actually start capturing before the test launches

echo "▸ Running $TEST_ID on '$SIM_NAME'…"
xcodebuild test \
  -project Basket.xcodeproj -scheme Basket \
  -destination "platform=iOS Simulator,id=$SIM" \
  -only-testing:"$TEST_ID" \
  | tail -20

echo "▸ Recording saved → $OUT_PATH"
echo "▸ Pull frames with: swift tools/extract_video_frame.swift \"$OUT_PATH\" <seconds> <out.png>"
