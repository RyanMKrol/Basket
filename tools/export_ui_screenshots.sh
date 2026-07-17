#!/usr/bin/env bash
#
# export_ui_screenshots.sh — run BasketUITests and export their XCTAttachment
# screenshots as plain PNGs into screenshots/ui-tests/, so the flows can be
# reviewed without opening Xcode's Report Navigator.
#
# Usage: ./tools/export_ui_screenshots.sh [--failures-only] [simulator-name]
#   --failures-only: export only failure-associated attachments to screenshots/ui-tests/failures/
#   Default (no arg): Basket's DEDICATED simulator (Basket-Claude, ensured by
#   tools/loop_sim.sh) rather than the shared "iPhone 17 Pro", so a second harness
#   loop on the same Mac can't collide on the same booted device. Pass a name to override.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Parse flags and arguments
FAILURES_ONLY=false
SIM_NAME="Basket-Claude"
for arg in "$@"; do
  if [[ "$arg" == "--failures-only" ]]; then
    FAILURES_ONLY=true
  else
    SIM_NAME="$arg"
  fi
done

# Ensure Basket's dedicated device exists.
"$PROJECT_DIR/tools/loop_sim.sh" >/dev/null
RESULT_BUNDLE="$PROJECT_DIR/build/UITestResults.xcresult"

if [[ "$FAILURES_ONLY" == true ]]; then
  OUT_DIR="$PROJECT_DIR/screenshots/ui-tests/failures"
else
  OUT_DIR="$PROJECT_DIR/screenshots/ui-tests"
fi

rm -rf "$RESULT_BUNDLE"
mkdir -p "$OUT_DIR"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

echo "▸ Running BasketUITests on '$SIM_NAME'…"
LOG="$PROJECT_DIR/build/export_ui_screenshots.log"
mkdir -p "$PROJECT_DIR/build"

# Create a timestamp marker for crash triage
RUN_MARKER="$(mktemp)"

TEST_FAILED=0
if ! xcodebuild test \
     -project Basket.xcodeproj -scheme Basket \
     -destination "platform=iOS Simulator,name=$SIM_NAME" \
     -only-testing:BasketUITests \
     -resultBundlePath "$RESULT_BUNDLE" \
     >"$LOG" 2>&1; then
  TEST_FAILED=1
  echo "xcodebuild test failed. Last 40 lines of $LOG:" >&2
  tail -40 "$LOG" >&2
else
  tail -20 "$LOG"
fi

echo "▸ Exporting screenshots…"
EXPORT_DIR="$(mktemp -d)"
XCRESULT_EXPORT_FLAGS="--path $RESULT_BUNDLE --output-path $EXPORT_DIR"
if [[ "$FAILURES_ONLY" == true ]]; then
  XCRESULT_EXPORT_FLAGS="$XCRESULT_EXPORT_FLAGS --only-failures"
fi
xcrun xcresulttool export attachments $XCRESULT_EXPORT_FLAGS

python3 "$PROJECT_DIR/tools/rename_ui_screenshots.py" "$EXPORT_DIR" "$OUT_DIR"
rm -rf "$EXPORT_DIR"

echo "▸ Screenshots → $OUT_DIR"

# Crash triage sweep (only if test run failed)
if [[ "$TEST_FAILED" == 1 ]]; then
  CRASHES=$(find "$HOME/Library/Logs/DiagnosticReports" -name 'Basket*.ips' -newer "$RUN_MARKER" 2>/dev/null || true)

  if [[ -z "$CRASHES" ]]; then
    echo "▸ No app crash reports produced by this test run"
  else
    # Try to locate xcsym, honor env override, then discover newest Axiom plugin install
    XCSYM="${XCSYM:-$(ls -d "$HOME"/.claude/plugins/cache/axiom-marketplace/axiom/*/bin/xcsym 2>/dev/null | sort -V | tail -1)}"

    if [[ -z "$XCSYM" ]] || [[ ! -x "$XCSYM" ]]; then
      echo "▸ App crash reports (unsymbolicated, Axiom plugin xcsym not found):"
      echo "$CRASHES"
    else
      echo "▸ App crash reports:"
      while IFS= read -r crash_file; do
        echo "--- $crash_file ---"
        "$XCSYM" crash "$crash_file" --format=summary || true
      done <<< "$CRASHES"
    fi
  fi
fi

rm -f "$RUN_MARKER"

exit "$TEST_FAILED"
