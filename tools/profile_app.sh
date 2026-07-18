#!/usr/bin/env bash
#
# profile_app.sh — record a CPU profile trace of Basket running a UI test workload,
# using xcprof (from the Axiom plugin) to attach xctrace to the running process.
#
# This script can run entirely headless and unattended. It records a trace around
# a specified UI test, analyzes it to JSON, and optionally refreshes a baseline
# snapshot for A/B performance comparison.
#
# Traces are stored under build/perf-traces/ (covered by .gitignore) and never
# committed. Baseline snapshots (tools/perf-baseline/baseline.json) are created
# ONLY on explicit --refresh-baseline and ONLY when a non-empty, Basket-attributed
# trace is captured — that precondition fails on this machine due to xctrace --attach
# not observing the Simulator-hosted process, so baseline recording is a human-only
# step on suitable hardware.
#
# Usage: ./tools/profile_app.sh [--help] [test-identifier] [simulator-name] [output-label]
#   --help, -h                  Print this usage and exit 0 (help checked before xcprof lookup)
#   test-identifier             Default: BasketUITests/SuggestionsFlowTests/testTappingSuggestionChipAddsItem
#   simulator-name              Default: Basket-Claude (ensured by tools/loop_sim.sh)
#   output-label                Default: ISO 8601 timestamp; used as the .trace/.json basename
#
# Optional flags:
#   --refresh-baseline          After a successful trace, copy the analyze JSON to
#                               tools/perf-baseline/baseline.json (pretty-printed via jq).
#                               This flag only succeeds when a non-empty trace with Basket
#                               frames is captured — on this machine it will fail, which is
#                               expected and signals that baseline recording is a human step.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Parse --help before anything else, so help works without xcprof installed
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat << 'EOF'
profile_app.sh — CPU profiling via xcprof (Axiom plugin)

Usage: ./tools/profile_app.sh [--help] [test-identifier] [simulator-name] [output-label] [--refresh-baseline]

Arguments:
  test-identifier       UI test to drive during profiling. Default:
                        BasketUITests/SuggestionsFlowTests/testTappingSuggestionChipAddsItem
  simulator-name        Target simulator device. Default: Basket-Claude (dedicated device)
  output-label          Basename for trace/json artifacts under build/perf-traces/.
                        Default: ISO 8601 timestamp.

Flags:
  --help, -h            Print this message and exit.
  --refresh-baseline    After capturing a trace, copy the JSON analysis to
                        tools/perf-baseline/baseline.json (only succeeds with a
                        non-empty, Basket-attributed trace).

Description:
  Records a CPU profile trace of Basket running a specified UI test workload, using
  xcprof --attach to bind xctrace to the running Basket process. The trace is analyzed
  to JSON and printed as human-readable Markdown to stdout. The exact xcprof compare
  command for A/B testing is also echoed at the end.

  Traces and JSON analyses are stored under build/perf-traces/ (ignored by .gitignore).
  On this machine, xctrace --attach may not observe the Simulator-hosted process while
  alive, so baseline snapshots cannot be reliably captured unattended — baseline recording
  is a human-only step using suitable hardware; see README.md for details.

EOF
  exit 0
fi

# Defaults
DEFAULT_TEST_ID="BasketUITests/SuggestionsFlowTests/testTappingSuggestionChipAddsItem"
TEST_ID="${1:-$DEFAULT_TEST_ID}"
REFRESH_BASELINE=0

# Parse remaining arguments
if [[ $# -gt 1 ]] && [[ ! "$2" =~ ^-- ]]; then
  "$PROJECT_DIR/tools/loop_sim.sh" >/dev/null  # ensure Basket's dedicated device exists
  SIM_NAME="$2"
  shift 2
else
  "$PROJECT_DIR/tools/loop_sim.sh" >/dev/null
  SIM_NAME="Basket-Claude"
  shift 1
fi

# output-label (optional third positional arg)
if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; then
  OUTPUT_LABEL="$1"
  shift 1
else
  OUTPUT_LABEL="$(date -u +'%Y-%m-%dT%H-%M-%S')"
fi

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh-baseline) REFRESH_BASELINE=1; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Locate xcprof with graceful degradation
XCPROF=""
if command -v xcprof &>/dev/null; then
  XCPROF="xcprof"
else
  # Glob for the plugin cache directory, pick highest version
  XCPROF_CANDIDATES=("$HOME"/.claude/plugins/cache/axiom-marketplace/axiom/*/bin/xcprof)
  if [[ -e "${XCPROF_CANDIDATES[0]}" ]]; then
    mapfile -t sorted < <(
      for f in "${XCPROF_CANDIDATES[@]}"; do
        [[ -x "$f" ]] && echo "$f"
      done | sort -V
    )
    if [[ ${#sorted[@]} -gt 0 ]]; then
      XCPROF="${sorted[-1]}"
    fi
  fi
fi

if [[ -z "$XCPROF" ]]; then
  cat >&2 << EOF
xcprof not found in PATH or Axiom plugin cache.

To use this script, install the Axiom plugin from the Claude Code marketplace
(the Axiom plugin includes xcprof, which provides CPU profiling via xctrace).

Expected plugin cache path (if it existed):
  $HOME/.claude/plugins/cache/axiom-marketplace/axiom/*/bin/xcprof

For details, see: README.md → Performance profiling (CPU) → why attach may see nothing
EOF
  exit 2
fi

# Check xctrace availability
if ! "$XCPROF" doctor >/dev/null 2>&1; then
  cat >&2 << EOF
xcprof doctor check failed: xctrace is not available on this system.

xctrace is part of the Xcode command-line tools. Ensure Xcode's command-line
tools are installed and selected:

  sudo xcode-select --install
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

Then try again.
EOF
  exit 2
fi

# Trace output paths
TRACES_DIR="$PROJECT_DIR/build/perf-traces"
mkdir -p "$TRACES_DIR"
TRACE_PATH="$TRACES_DIR/$OUTPUT_LABEL.trace"
JSON_PATH="$TRACES_DIR/$OUTPUT_LABEL.json"

# Clean up any partial artifacts
rm -f "$TRACE_PATH" "$JSON_PATH"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

# Resolve simulator name to UDID
SIM_ID="$(xcrun simctl list devices booted | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
if [ -z "$SIM_ID" ]; then
  SIM_ID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | tail -1 || true)"
fi
SIM="${SIM_ID:-$SIM_NAME}"

echo "▸ Booting simulator '$SIM_NAME' ($SIM)…"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" >/dev/null 2>&1 || true

echo "▸ Starting xcodebuild test in the background…"
LOG="$PROJECT_DIR/build/profile_app.log"
mkdir -p "$PROJECT_DIR/build"

xcodebuild test \
  -project Basket.xcodeproj -scheme Basket \
  -destination "platform=iOS Simulator,id=$SIM" \
  -only-testing:"$TEST_ID" \
  >"$LOG" 2>&1 &
XCODEBUILD_PID=$!

# Always clean up the background test process on exit
cleanup() {
  if kill -0 "$XCODEBUILD_PID" 2>/dev/null; then
    kill "$XCODEBUILD_PID" 2>/dev/null || true
    wait "$XCODEBUILD_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Poll for the Basket process to appear (bounded ~60s)
echo "▸ Waiting for Basket process to launch (polling for ~60s)…"
POLL_COUNT=0
POLL_MAX=60
while [[ $POLL_COUNT -lt $POLL_MAX ]]; do
  if pgrep -x Basket >/dev/null 2>&1; then
    echo "▸ Basket process detected, starting CPU trace capture…"
    break
  fi
  sleep 1
  POLL_COUNT=$((POLL_COUNT + 1))
done

if [[ $POLL_COUNT -ge $POLL_MAX ]]; then
  echo "▸ Basket process did not launch within 60s, continuing anyway…" >&2
fi

# Record CPU trace (30s limit)
echo "▸ Recording CPU trace ($TRACE_PATH)…"
"$XCPROF" record --preset cpu --attach Basket --no-prompt --time-limit 30s \
  --output "$TRACE_PATH" >/dev/null 2>&1 || true

# Wait for the test to complete
echo "▸ Waiting for test to complete…"
if ! wait $XCODEBUILD_PID; then
  echo "⚠ xcodebuild test failed (see $LOG). Trace may still have been captured." >&2
fi
tail -20 "$LOG"

# Check if trace exists and is non-empty
if [[ ! -e "$TRACE_PATH" ]]; then
  cat >&2 << EOF
▸ Trace file was not created. This may indicate:
  1. xcprof --attach did not successfully attach to the Basket process.
  2. xctrace encountered an environment issue (e.g., missing device pairing).

See README.md → Performance profiling (CPU) → why attach may see nothing
for details on known limitations of --attach on this machine.
EOF
  exit 1
fi

TRACE_SIZE=$(stat -f%z "$TRACE_PATH" 2>/dev/null || stat -c%s "$TRACE_PATH" 2>/dev/null || echo 0)
if [[ $TRACE_SIZE -lt 1000 ]]; then
  cat >&2 << EOF
▸ Trace file is suspiciously small ($TRACE_SIZE bytes), likely empty or corrupted.
  This often indicates that xctrace --attach did not observe the Simulator-hosted
  Basket process while alive.

See README.md → Performance profiling (CPU) → why attach may see nothing
for details and the human baseline-recording workflow.
EOF
  rm -f "$TRACE_PATH"
  exit 1
fi

# Analyze the trace
echo "▸ Analyzing trace → $JSON_PATH"
if ! "$XCPROF" analyze "$TRACE_PATH" --json >"$JSON_PATH" 2>&1; then
  cat >&2 << EOF
▸ xcprof analyze failed. The trace may be corrupted or in an unexpected format.
  See $JSON_PATH for details.
EOF
  exit 1
fi

# Check if the JSON contains any Basket-attributed frames (guard against empty traces)
if ! grep -q '"Basket"' "$JSON_PATH" 2>/dev/null; then
  cat >&2 << EOF
▸ Trace analysis completed, but no Basket-attributed frames found in the JSON.
  This indicates that xctrace --attach did not observe the Basket process while alive.

See README.md → Performance profiling (CPU) → why attach may see nothing
for details and the human baseline-recording workflow.
EOF
  rm -f "$TRACE_PATH" "$JSON_PATH"
  exit 1
fi

# Print human-readable analysis
echo ""
echo "✓ Trace recorded and analyzed successfully."
echo ""
echo "## CPU Profile Summary"
echo ""
echo "- **Trace:** $TRACE_PATH"
echo "- **Analysis JSON:** $JSON_PATH"
echo ""
cat "$JSON_PATH" | grep -E '"function"|"time"|"count"' | head -20 || true
echo ""
echo "## Next steps"
echo ""
echo "To compare this trace against a baseline:"
echo ""
echo "  \$ xcprof compare tools/perf-baseline/baseline.json $TRACE_PATH --fail-on-regression"
echo ""
echo "Exit code 3 signals a regression. See README.md → Performance profiling (CPU)"
echo "for the full A/B workflow."
echo ""

# --refresh-baseline: copy analyze JSON to baseline (only if non-empty trace succeeded)
if [[ $REFRESH_BASELINE -eq 1 ]]; then
  BASELINE_DIR="$PROJECT_DIR/tools/perf-baseline"
  mkdir -p "$BASELINE_DIR"
  BASELINE_PATH="$BASELINE_DIR/baseline.json"

  if jq . "$JSON_PATH" >"$BASELINE_PATH" 2>/dev/null; then
    echo "▸ Baseline updated: $BASELINE_PATH"
  else
    echo "▸ Failed to update baseline (jq formatting error)" >&2
    exit 1
  fi
fi
