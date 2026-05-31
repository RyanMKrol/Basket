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
# Usage: ./build_run.sh [simulator-name]   (default: "iPhone 17 Pro")

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Basket"
BUNDLE_ID="com.ryankrol.basket"
SIM_NAME="${1:-iPhone 17 Pro}"
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
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_NAME" >/dev/null 2>&1 || true
open -a Simulator || true

echo "▸ Installing + launching…"
xcrun simctl install "$SIM_NAME" "$APP_PATH"
xcrun simctl launch "$SIM_NAME" "$BUNDLE_ID"

mkdir -p "$SHOT_DIR"
sleep 3
xcrun simctl io "$SIM_NAME" screenshot "$SHOT_PATH" >/dev/null
echo "▸ Screenshot → $SHOT_PATH"
