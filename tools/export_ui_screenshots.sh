#!/usr/bin/env bash
#
# export_ui_screenshots.sh — run BasketUITests and export their XCTAttachment
# screenshots as plain PNGs into screenshots/ui-tests/, so the flows can be
# reviewed without opening Xcode's Report Navigator.
#
# Usage: ./tools/export_ui_screenshots.sh [simulator-name]   (default: "iPhone 17 Pro")

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

SIM_NAME="${1:-iPhone 17 Pro}"
RESULT_BUNDLE="$PROJECT_DIR/build/UITestResults.xcresult"
OUT_DIR="$PROJECT_DIR/screenshots/ui-tests"

rm -rf "$RESULT_BUNDLE"
mkdir -p "$OUT_DIR"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

echo "▸ Running BasketUITests on '$SIM_NAME'…"
xcodebuild test \
  -project Basket.xcodeproj -scheme Basket \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -only-testing:BasketUITests \
  -resultBundlePath "$RESULT_BUNDLE" \
  | tail -20

echo "▸ Exporting screenshots…"
EXPORT_DIR="$(mktemp -d)"
xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$EXPORT_DIR"

python3 "$PROJECT_DIR/tools/rename_ui_screenshots.py" "$EXPORT_DIR" "$OUT_DIR"
rm -rf "$EXPORT_DIR"

echo "▸ Screenshots → $OUT_DIR"
