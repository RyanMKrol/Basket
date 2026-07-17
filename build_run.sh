#!/usr/bin/env bash
#
# build_run.sh — generate, build, install, launch, and screenshot Basket on the
# iOS simulator, entirely from the CLI (no Xcode GUI).
#
# Notes baked in from this machine's Xcode 26.5 / XcodeGen 2.45.4 combo:
#   * The generated *scheme* reports an empty supported-platforms list, so the
#     usual `-scheme … -destination 'platform=iOS Simulator,…'` matches nothing.
#     We therefore build by `-target` with an explicit SUPPORTED_PLATFORMS + SYMROOT.
#   * The installed simulator runtime is iOS 26.2; SDK is 26.5 — fine for the sim.
#
# Usage: ./build_run.sh [simulator-name-or-udid]
#   Default (no arg): this project's DEDICATED simulator (tools/loop_sim.sh), so
#   concurrent harness loops for other projects on the same Mac never fight over
#   one shared "iPhone 17 Pro" device. Pass a name or UDID to override.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Basket"
BUNDLE_ID="com.ryankrol.basket"
# No explicit arg → resolve (and create-if-missing) the project's dedicated device
# via loop_sim.sh, which prints its UDID. An explicit name/UDID arg overrides.
SIM_NAME="${1:-$("$PROJECT_DIR/tools/loop_sim.sh")}"
# Resolve the argument to a concrete UDID. A device *name* can be ambiguous (the
# same model exists per installed runtime), so prefer an already-booted match,
# else the last (newest-runtime) available one. Pass a UDID to pin a specific
# simulator (e.g. to avoid clashing with another agent on a shared machine) —
# it's detected by shape and used as-is (the dedicated-device default already is one).
# The `|| true` on each pipeline matters: under `set -euo pipefail`, a grep that
# finds nothing returns non-zero and would otherwise abort the whole script
# *silently* (before the first echo) whenever the named device isn't booted.
if [[ "$SIM_NAME" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}$ ]]; then
  SIM="$SIM_NAME"
else
  SIM_ID="$(xcrun simctl list devices booted | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
  if [ -z "$SIM_ID" ]; then
    SIM_ID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | tail -1 || true)"
  fi
  SIM="${SIM_ID:-$SIM_NAME}"
fi
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Debug-iphonesimulator/$APP_NAME.app"
SHOT_DIR="$PROJECT_DIR/screenshots"
SHOT_PATH="$SHOT_DIR/latest.png"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

echo "▸ Building $APP_NAME for the simulator…"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -target "$APP_NAME" \
  -sdk iphonesimulator \
  -configuration Debug \
  build \
  SUPPORTED_PLATFORMS="iphonesimulator" \
  SYMROOT="$BUILD_DIR" \
  | tail -3

echo "▸ Booting simulator '$SIM_NAME'…"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" >/dev/null 2>&1 || true
open -a Simulator || true

echo "▸ Installing + launching…"
xcrun simctl install "$SIM" "$APP_PATH"
xcrun simctl launch "$SIM" "$BUNDLE_ID"

mkdir -p "$SHOT_DIR"
sleep 3
xcrun simctl io "$SIM" screenshot "$SHOT_PATH" >/dev/null
echo "▸ Screenshot → $SHOT_PATH"

# Check console for errors using xclog if available
XCLOG="${XCLOG:-$(ls -d "$HOME"/.claude/plugins/cache/axiom-marketplace/axiom/*/bin/xclog 2>/dev/null | sort -V | tail -1)}"
if [ -z "$XCLOG" ] || [ ! -x "$XCLOG" ]; then
  echo "xclog not found, skipping console error check"
else
  CONSOLE_LOG="$SHOT_DIR/console-errors.log"
  "$XCLOG" show "$APP_NAME" --device "$SIM" --last 2m --filter '(?i)error|fault' > "$CONSOLE_LOG" 2>/dev/null || true
  if [ -s "$CONSOLE_LOG" ]; then
    echo "▸ Console errors detected during launch:"
    cat "$CONSOLE_LOG"
  else
    rm -f "$CONSOLE_LOG"
    echo "▸ No console errors during launch"
  fi
fi
