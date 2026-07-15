# custom/docs/LIMITATIONS.md — this project's trade-offs & limitations log

Customization overlay for `.harness/docs/LIMITATIONS.md`. **This is where your project's own
limitation/trade-off rows go** (golden rule 5): when a change introduces a trade-off, bottleneck, or known
limitation, add a row **here** — not in the pristine `docs/LIMITATIONS.md`, which is plugin-owned and
refreshed on upgrade. Harness upgrades never touch this file. (See `.harness/custom/CLAUDE.md`.)

Each row: what it is, *why* it was chosen, its **impact**, and *when to revisit*.

## Escalation ladder shortened to 3 rungs (2026-07-13)

**What:** `config/facets.json .tiers.ladder` went from the template's 5 rungs
(haiku → sonnet/low → sonnet/medium → sonnet/high → opus/high) to **3 rungs:
haiku/null → claude-sonnet-5/medium → claude-opus-4-8/medium**. Dropped
sonnet/low and sonnet/high; changed the top rung from opus/high to opus/medium.

**Why:** fail-faster. On this project each attempt is ~30-45 min wall-clock (slow
iOS-simulator CI run at multiple gates), and tasks that are genuinely stuck (e.g.
T019/T020, which broke the whole UI suite and exhausted the old ladder to
`blocked`) waste a lot of time and spend grinding through redundant middle tiers.
A stuck task now blocks after at most 3 × MAX_ATTEMPTS = 6 attempts (was 10).

**Impact:**
- Escalation jumps haiku → sonnet/medium → opus/medium; a task solvable only by
  sonnet/low now uses sonnet/medium (slightly more compute), and the hardest
  tasks top out at opus/**medium** rather than opus/high (less capability, less
  spend at the ceiling).
- The 5 historical sonnet/low outcome rows go inert (their tier is no longer on
  the ladder — `tidx()` re-matches by (model,effort) each run, so no corruption,
  just cosmetic `succeededRung` drift). Those (layer×work-type) cells revert to
  cold-start behavior. Haiku calibration (12 rows) is preserved.

**When to revisit:** if too many tasks block that opus/high would have solved (a
sign the top is now too weak), add an opus/high rung back; or if the jump from
sonnet/medium to opus is too costly, reinstate a sonnet/high middle rung. Change
via `/implementation-harness-update-ladder`, loop stopped.

## Timing/animation visual verification moved to recorded video, not live observation (2026-07-15)

**What:** for a `## Done when` claim about a fast or timing-sensitive visual behavior (an animation
fading gracefully, a section never flickering back, a burst being visible), the builder/auditor
guidance (`custom/visual-verify-{build,audit}.md`) now requires `tools/record_ui_test.sh` (records
the simulator's own framebuffer via `simctl io recordVideo` while an XCUITest drives the
interaction) + `tools/extract_video_frame.swift` (pulls stills at chosen timestamps via
AVFoundation) — inspecting a sequence of frames — instead of a single screenshot or a human/agent
watching the interaction happen live in the simulator.

**Why:** this repo's build/verify loop had, in one interactive session, resorted to a workaround
that drove the real host mouse via CGEvent + AppleScript (to click into the Simulator window on the
actual screen) when asked to verify a live UI interaction a static screenshot couldn't prove —
because this machine has no `idb`/`cliclick`. That workaround visibly took over the operator's real
cursor/keyboard and could conflict with other work (including other projects' own harness loops
running concurrently on the same machine). Proven out on `SparkleBurst`'s check-off animation
(`Sources/Views/SparkleBurst.swift`): `record_ui_test.sh` + `extract_video_frame.swift` cleanly
captured the burst mid-flight across several timestamps, using only `simctl`'s own framebuffer
capture — the same mechanism as `simctl io screenshot` / XCUITest's `app.screenshot()` — never the
real screen. That same session's run also showed a *pre-existing* gap: the app's own step
screenshot (taken right after `waitForLabel` resolves) landed noticeably after the check-off tap,
because XCUITest's "wait for app to idle" settling ate the time in between — a single, precisely-timed
screenshot is not reliable for a fast animation even before considering the live-watch problem.

**Impact:**
- Every future task whose `## Done when` makes a timing/animation claim should use this pattern
  (baked into `custom/visual-verify-{build,audit}.md`, and already rewritten into T038's and T040's
  specs) rather than "watch it happen" language, which nudges a builder toward reinventing the
  CGEvent-style workaround.
- Frame timestamps are relative to when `record_ui_test.sh` starts `recordVideo`, not to the test's
  own internal clock — correlating "when did the interaction happen" to "what second of video is
  that" isn't exact (varies run to run with build/launch overhead) and currently needs a coarse
  sweep first (e.g. every 1-2s) to locate the interaction, then a finer sweep (0.1-0.2s) to inspect
  it. A test that logs (or the builder notes) roughly how many seconds after launch the interaction
  fires would narrow this; not automated yet.
- `tools/record_ui_test.sh` adds real wall-clock time per verification pass (a full `xcodebuild
  test` invocation, on top of whatever `record_ui_test.sh` itself costs) — heavier than a single
  `build_run.sh` screenshot, so it's reserved for genuinely timing-sensitive claims, not a blanket
  replacement for the existing static-screenshot path.

**When to revisit:** if the timestamp-correlation friction above becomes a recurring drag on
builder attempts, consider having `record_ui_test.sh` (or the test itself) emit a marker — e.g. a
log line with the wall-clock time the interaction under test fires — so a builder can compute the
video offset directly instead of sweeping for it.
