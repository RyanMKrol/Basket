# CLAUDE.md — working conventions for the Basket repo

Basket is a soft, friendly iOS shopping-list app (SwiftUI + SwiftData, on-device
only). This file is the source of truth for **how to work in this repo**. Follow
it on every task unless the user says otherwise.

## Golden rule: every task gets its own git worktree + branch

**Never work in the shared/primary checkout, and never commit to `main`.** Other
Claudes (and humans) may be working in this same repo at the same time — sharing
one working tree clashes over the checked-out branch, the generated
`Basket.xcodeproj`, the `build/` directory and the simulator. So **every** task —
a feature, a fix, even a one-line doc tweak — happens in its **own** git worktree,
on its **own** branch, cut from an up-to-date `main`:

```sh
# 0. sync main (in the primary checkout) and see who's already where
git -C <primary-checkout> checkout main && git -C <primary-checkout> pull --ff-only
git worktree list && git branch                       # avoid name/dir clashes

# 1. create YOUR isolated worktree on a UNIQUE branch, off main
git worktree add ../basket-<slug> -b <type>/<slug> main
cd ../basket-<slug>

# 2. do the work here, commit as it goes green (see "Definition of done")
git add -A && git commit -m "…"

# 3. integrate: resync main, merge your branch, publish
git checkout main && git pull --ff-only
git merge --no-ff <type>/<slug> && git push

# 4. clean up the worktree + branch
git worktree remove ../basket-<slug> && git branch -d <type>/<slug>
```

Notes:
- **Pick a unique slug/branch.** Another agent may already own `feat/<x>` — check
  `git branch` and `git worktree list` first, and never reuse, move, or delete a
  branch or worktree that isn't yours.
- The **primary checkout stays on a clean, current `main`** as the shared
  integration point — don't park a feature branch in it.
- **Build and test inside your worktree** (it has its own `Basket.xcodeproj` and
  `build/`); pin a dedicated simulator so you don't fight over one.
- We don't use pull requests — merge it yourself. **One worktree = one branch =
  one task.**

### Commit proactively — don't wait to be asked

Whenever you make a real change, **commit it to the branch without waiting for
permission**. Don't leave finished work sitting uncommitted in the working tree.
The repo is always rollback-able, so an extra commit is cheap and a lost change
is not. Commit in logical chunks as work reaches a green state (see "Definition
of done"); once a change is green, push the branch and merge it to `main` per the
flow above. The only things to still confirm first are destructive or
hard-to-undo actions (e.g. `push --force`, history rewrites, deleting remote
branches that aren't yours, anything outward-facing beyond the normal merge).

## Definition of done

A change is done when, on the branch:

- **Builds clean:** `./build_run.sh` reaches `** BUILD SUCCEEDED **` (it also
  launches the app on the simulator and saves a screenshot to `screenshots/`).
- **Tests pass:**
  - XCTest + XCUITest on the simulator — one command runs both, since
    `BasketUITests` is wired into the same scheme's test action:
    `xcodegen generate && xcodebuild test -project Basket.xcodeproj -scheme Basket -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
  - Native logic harness (fast, no simulator) — compile the pure-logic `Sources`
    files together with `tools/main.swift` and run it (see `README.md` → Tests).
- **Docs updated in the same commit:** keep `README.md` in step with behaviour.
- **Generated files regenerated, not hand-edited** (see below).

Both test commands above also run in CI (`.github/workflows/ci.yml`) on
**every branch push** — pre-merge signal for your worktree branch, post-merge
backstop on `main` (there's no PR review step; see the golden rule above). On
failure CI uploads the `.xcresult` (failure screenshots + audit logs) as an
artifact, and a scheduled nightly `flake-hunt` job reruns every test up to 5
times to surface only-fails-sometimes tests; the push-triggered job never
retries. It's a best-practice safety net, not something Apple requires for
App Store submission.

## Project map

- `project.yml` — XcodeGen spec; the `.xcodeproj` is **generated** (run
  `xcodegen generate`), never hand-edited. Add new files under `Sources/` and
  regenerate so they're picked up.
- `build_run.sh` — generate → build → install → launch → screenshot, from the
  CLI (no Xcode GUI). Resolves the simulator name to a concrete UDID.
- `Sources/` — the app:
  - `Models/` — `GroceryItem`, `KnownItem` (history), `Suggestion`.
  - `Views/` — `ShoppingListView`, `ItemRow`, `AddBar`, `EmptyStateView`.
  - `Services/` — `Emoji` (3-stage cascade), `SemanticEmoji` (NLEmbedding),
    `Suggestions`, `Formatting`, `Haptics`, `Measure` (smart units — classifies an
    item's measure type by its emoji glyph), `Seasonality` (time-of-day / holiday
    flourishes), `TipJar` (StoreKit 2 consumable tip jar), `ListLogic`
    (section partitioning + `CheckOffChoreography`, the check-off state
    machine — pure and unit-tested), `KnownItems` (suggestion-memory upsert),
    `TestHooks` + `AppClock` (the UI tests' determinism switchboard: launch
    args/env for animations-off, frozen clock, temp store — **route any new
    "current time" reads through `AppClock.now`** or they escape test
    control, and prefer `withAppAnimation`/`.unlessUITesting` over bare
    `withAnimation`/`.animation` so animations stay disable-able under test);
    **generated:** `EmojiTable.swift`, `SuggestionDictionary.swift`.
  - `Support/SharedFixtures.swift` — starter-item names, compiled into both
    the app and `BasketUITests` (see project.yml) so seed and tests can't
    drift.
  - `PrivacyInfo.xcprivacy` — Apple's required privacy manifest; declares the
    "required-reason" APIs the app touches (currently just `UserDefaults`, for
    `TipJar`'s tipped flag — reason `CA92.1`, own app's data only). App Store
    Connect rejects binaries missing a declaration for any required-reason API
    they use, so **add a new entry here** whenever new code starts using one
    (`UserDefaults`, file timestamps, system boot time, disk space, active
    keyboard — see Apple's required-reason API list).
- `StoreKit/Basket.storekit` — local StoreKit config for testing the tip jar.
  IAP can't be exercised by `build_run.sh` (it `simctl launch`es, bypassing the
  scheme's StoreKit config); `Tests/TipJarTests.swift` covers product
  *loading* via StoreKitTest's `SKTestSession` on this config — purchases
  themselves can't run in a plain unit-test host (`purchase()` hangs without
  a UI anchor; injected transactions need an .xctestplan-level StoreKit
  config the generated scheme doesn't have — see the note in that file), so
  test purchases by **Running from Xcode** (the generated scheme references
  the config) or via App Store Connect sandbox. `TipJar.swift` imports
  iOS-only StoreKit, so it's kept **out** of the `tools/main.swift`
  native-harness compile list.
- `Tests/` — XCTest: `BasketTests.swift` (pure logic), `ListLogicTests.swift`
  (sectioning + check-off choreography), `ModelTests.swift` (SwiftData
  in-memory: seed, suggestion-memory upsert), `TipJarTests.swift`
  (StoreKitTest), `SnapshotTests.swift` (reference-image tests of the core
  views; references in `Tests/__Snapshots__/`, recorded on iOS 26.x and
  auto-skipped on other majors).
- `UITests/` — XCUITest flow tests, driving a real simulator through the app's
  actual UI (add/suggestions/check-off/quantity-edit/empty-state/persistence
  flows), each step attaching a screenshot to the test report.
  `BasketUITestCase` (base class) launches the app with `-uiTesting`
  (isolated in-memory SwiftData store), `-uiTestingDisableAnimations` +
  `UITEST_FROZEN_DATE` (deterministic rendering — see `TestHooks`), and
  optionally `-uiTestingEmpty` (skip the starter items) or `UITEST_STORE_URL`
  (temp persistent store, for the relaunch tests) — see `BasketApp.init`.
  Wired into the `Basket` scheme's test action alongside `BasketTests`, so
  `xcodebuild test -scheme Basket` runs both. **House rule: never assert on
  live UI state directly** — use the base class's bounded waits
  (`waitForLabel` / `waitForValue` / `waitForGone` / `waitForToGetCount`),
  and query by `accessibilityIdentifier`, never display copy.
  - `AccessibilityAuditTests.swift` — `performAccessibilityAudit()` over the
    main screens; `.contrast`/`.textClipped`/`.dynamicType` excluded with
    reasons documented inline (soft palette + colour emoji + deliberately
    fixed-size pixel fonts), everything else must pass cleanly.
  - `TapJitter.swift` / `TapPrecisionTests.swift` — a seeded pseudo-random
    offset generator + `XCUIElement.tapJittered`, used to stress-test the
    smallest controls (stepper buttons, unit pills, check circle) with
    off-center taps standing in for real finger imprecision. Every trial is
    asserted individually (no averaged pass-rate threshold) and a failure at
    a given trial index is reproducible, since the seed is fixed.
- `tools/` — generators & audits (run from the repo root):
  - `gen_emoji.py` → `Sources/Services/EmojiTable.swift` (curated keyword→emoji
    table, from inline data + `emoji_supplement.txt`).
  - `gen_suggestions.py` → `Sources/Services/SuggestionDictionary.swift` (unifies
    `corpus/*.txt` with the emoji table's keyword vocabulary).
  - `audit_coverage.swift` — audits emoji coverage over `corpus/*.txt`.
  - `make_icon.swift` / `make_icon_options.swift` — legacy programmatic icon
    renderer, **superseded**: `Sources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
    is now the design agency's artwork, not generator output. Don't run these
    against the appiconset without checking with the user first.
  - `main.swift` — the native logic test harness.
  - `export_ui_screenshots.sh` / `rename_ui_screenshots.py` — run `UITests/`
    and export their `XCTAttachment` screenshots as plain PNGs into
    `screenshots/ui-tests/`, named after the test + attachment instead of
    Xcode's opaque `.xcresult` filenames.

## Emoji pipeline (when changing food→emoji mapping)

1. Edit the data in `tools/gen_emoji.py` (or `tools/emoji_supplement.txt`).
2. `python3 tools/gen_emoji.py Sources/Services/EmojiTable.swift`.
3. Re-audit: build `audit_coverage.swift` against `tools/corpus/*.txt` and check
   coverage stays high (target: 0 fall-throughs).
4. Run the native harness + XCTest.

Never hand-edit `EmojiTable.swift` or `SuggestionDictionary.swift` — they're
overwritten by their generators.

## Environment note

Requires Xcode's CLI tools + XcodeGen (`brew install xcodegen`) and an iOS
**simulator runtime matching the SDK** (else `xcodebuild test` and asset-catalog
/ app-icon compilation fail with "No simulator runtime version … available" —
fix with `xcodebuild -downloadPlatform iOS`).

## Autonomous build harness (`.harness/`)

This repo also carries an **autonomous implementation harness** — a single
sequential shell loop (`.harness/scripts/loop.sh`, run via
`.harness/scripts/supervise.sh`) that builds the `.harness/tracking/TASKS.json`
backlog one fully-verified task at a time, gated on green GitHub CI.
[`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) is the authoritative
design; `.harness/CLAUDE.md` (the authoring mandate) loads automatically when
working inside `.harness/`. The harness's flow **matches this repo's golden
rule** — the loop builds in its own isolation worktree (`../basket-loop`) on a
`tNNN` branch and merges to `main` itself on green CI, exactly like any other
worktree task.

Harness-specific rules that apply to ALL work in this repo:

### Backlog tasks carry facets (difficulty auto-tuning)

Every BUILDABLE task you add to `.harness/tracking/TASKS.json` MUST carry a
`"facets": { "layer": …, "workType": …, "risk": [...] }` object, with values
chosen ONLY from `.harness/config/facets.json`'s controlled vocabulary (use the
task's `scope` paths to pick the `layer`). The loop's policy reads facets to
choose each task's STARTING model/effort from escalation history; the
cold-start prior is the `harness.env` `MODEL`/`EFFORT` floor. **Never add
per-task `model`/`effort` fields — the loop ignores them.** `needs-human`
(gated) tasks are carved out — they get NO facets. Author through the
`/implementation-harness-add-to-backlog` skill when available; the rule holds
even on a direct `TASKS.json` edit.

### The loop is the sole writer of harness task status

Under the autonomous loop, only the LOOP flips a task's `"status"` in
`TASKS.json` (in a follow-up commit, once the build clears the structural
checks and audit gate). Never set `"status"` yourself while working on a
harness-driven task — doing so trips the scope gate. Working BY HAND (no loop
running), set the task's `"status": "done"` in the same commit as the work,
like any other doc update.

### Every harness attempt is fully cold

The harness measures whether a model can build a task *from the spec alone, in
one cold pass* — that signal drives difficulty calibration and the audit gate.
Never read `worklog/TNNN.md` as guidance and never resume a previous attempt's
partial work; build only from the task's `spec` (`## Do` / `## Done when`),
`scope`, and `verify`. A task that can't be done in one cold pass is mis-sized
and should be split, not resumed.

### Record trade-offs & limitations

When a change introduces or reveals a design trade-off or known limitation, add
a row to `.harness/custom/docs/LIMITATIONS.md` **in the same commit** — what it
is, why, the impact, and when to revisit. (Use the `custom/` overlay, never the
plugin-owned `.harness/docs/LIMITATIONS.md`, which is refreshed on upgrade.)

### Respect the needs-human gate

Tasks with `"gate": "needs-human"` need a one-time human step (credentials,
provisioning, spending real money). Prepare everything around it, record
`failed:blocked`, never auto-complete it.

### Customize in `.harness/custom/`, not in place

The harness's prose files (`.harness/CLAUDE.md`, `.harness/README.md`,
`.harness/docs/**`) are plugin-owned and refreshed by
`implementation-harness:implementation-harness-upgrade` — project-specific
additions go in the matching file under `.harness/custom/`.
