# Basket 🧺

A friendly, whimsical pixel-art iOS shopping list. Adding is frictionless (a
pinned bottom bar with history-backed suggestions); checking an item off pops a
spark burst and an animated strikethrough, then slides it into a faded "Got it"
section that clears itself after an hour.

Built with **SwiftUI + SwiftData**, on-device only (no account, no backend).

The look is **Pastel Dots** — creamy cards on a soft green pixel-dot backdrop,
with pixel fonts (VT323 + Silkscreen) and fresh fruity accents. The pixel fonts
scale with the user's Dynamic Type setting: `Theme.body`/`Theme.title`
(`Sources/Theme/Theme.swift`) build every custom font via
`Font.custom(_:size:relativeTo:)`, so Larger Text keeps the retro typeface
while still growing with the chosen text style. `Theme`'s unused `.rounded`
and `.monospaced` font kinds (no active theme uses them) still build a plain
`.system(size:weight:design:)` and do not yet participate in Dynamic Type —
revisit if a non-custom theme is ever added.

**Dynamic Type note:** a handful of spots genuinely can't grow past
`.accessibility2` without their fixed-size row/badge overflowing — each is
capped there explicitly via `.dynamicTypeSize(...DynamicTypeSize.accessibility2)`
rather than left to clip or overlap: `EmptyStateView`'s rotating title (long
lines in a fixed-width screen), `QuantityEditor`'s value display (a
stepper/value/clear-button row with no more room to give), and `AboutView`'s
tip badges, subtitle, and tip prompt (a compact fixed-size card and a sheet
whose `.medium`/`.large` detents leave little vertical room). Everything else
scales the full Dynamic Type range uncapped. See the row of test evidence in
`DynamicTypeTests.testLargestAccessibilitySizeScreensRenderWithoutBreaking`.

## Features

- **Quick add** — always-visible bottom bar with a green **＋** add button; as you
  type, suggestions float up as one-tap chips: your personal history first (things
  you've bought in the last month, ranked by frequency + recency), then a built-in
  food dictionary (`SuggestionDictionary`) for instant autocomplete. That
  dictionary unifies the grocery + regional corpora with the emoji table's whole
  vocabulary, so anything the app can put an emoji on it can also suggest (e.g.
  "cord" → Cordial). Items already on the list are filtered out. Focusing the
  field before typing anything isn't a dead end either — it surfaces up to
  `combinedMax` **"usuals"** chips, your most-frequent recent items ranked the
  same frequency + recency way (`Suggestions.usuals`), in the same tappable
  chip UI. Nothing shows for a fresh install with no history.
- **Tap the check circle** to check an item off — the check pops with a burst of
  gold sparks while a strikethrough draws left-to-right, then the row glides into
  a dimmed **"Got it"** section (tap it to restore it). The spark burst respects
  Reduce Motion (a calm check-circle animation takes its place). Check several off
  at once and they hold their place until the last spark finishes, then glide down
  together — so the list never shuffles under your taps.
- **Tap the row** (or its faint **"+ Qty"** chip) to set a quantity. An inline
  stepper slides down with a **smart default unit** guessed from the item — pour-y
  things start in ml, weighed things in g, everything else as a plain count. You
  can switch units freely from a pill row: **every item can be counted in plain
  "units"**, and unrecognised items offer the full set (ml/L/g/kg/units), since we
  can't always know what you mean ("300 ml of milk" vs "1 bottle"). Switching
  ml↔L or g↔kg keeps the amount; switching to a different kind of unit starts
  fresh (so it never shows "500 units"). **Tap the number itself** (between the −
  and +) to type an exact amount on the keyboard — so a big quantity doesn't mean
  tapping + over and over. The field is forgiving: it ignores the unit letters
  ("750 ml" → 750), takes a comma or dot decimal, rounds plain counts to whole
  numbers, and quietly keeps the old amount if you clear it or type nonsense. The
  amount shows as a small chip on the row; long names truncate so the chip keeps
  its place.
- **Tap an item's name** to rename it inline — the name swaps for a prefilled
  text field; commit with return. A mistyped or changed-your-mind item doesn't
  need deleting and re-adding: the emoji re-derives for the new name, any set
  quantity resets to unset (the old amount may no longer make sense), and the
  item keeps its place in the list. An empty name is rejected, leaving the old
  one in place. This tap target is additive — the rest of the row (and the
  "+ Qty" chip) still opens the quantity editor exactly as before.
- **1-hour TTL** on the "Got it" section, so it tidies itself between shops — or
  tap **Clear all** in the section header to empty it immediately. Cleared items
  vanish right away, but a soft **"Cleared N items — Undo"** toast floats above
  the add bar for a few seconds in case that was a mis-tap: tap **Undo** to bring
  everything back exactly as it was (name, quantity, checked state), or let the
  toast expire to commit the clear. Under the hood the items are only *hidden*
  until the toast expires, not deleted, so undo restores the real rows instead of
  re-inserting copies. The toast respects Reduce Motion and announces itself to
  VoiceOver.
- **Duplicate-aware** — re-adding something already listed bumps + flashes the
  existing row instead of creating a copy.
- **"Hey Siri, add milk to my Basket"** — an `AddToBasketIntent` App Intent,
  registered as an App Shortcut (`Sources/Services/AddToBasketIntent.swift`),
  lets Siri and the Shortcuts app add an item without opening the app. It
  writes through the same shared App Group SwiftData store the app reads
  (`AppGroup`), derives the emoji and dedupe/bump behaviour exactly like
  typing it into the add bar (`AddItem.perform`, shared with
  `ShoppingListView`), and records the item in the suggestion memory.
- **Deep-link quick-add** — the `basket://add` URL scheme opens the app with
  the add bar focused and the keyboard up, ready to type. Works whether the app
  is already running or launching cold. This is the target for the Home Screen
  widget's quick-add button, letting you add an item with one tap and one swipe,
  no app icons needed.
- **About sheet** — the ⓘ in the header opens a small sheet with the app version
  and an optional **tip jar** (☕ / 🥪 / 🎁, in-app purchases via StoreKit). Basket
  is free; tipping unlocks nothing — but once you've tipped, the **Basket** title
  turns into a per-letter rainbow with a solid red heart; tap it to toggle between
  the rainbow and classic looks (your choice persists), as a small thank-you.
- **Little touches** — a sub-second basket flourish on cold launch (never on
  resume), a full-screen "All done!" celebration when you check off the last
  item with a success haptic pulse, and quiet living details: a faint time-of-day
  tint and the occasional seasonal accent (🎃, 🎄…) on the empty state.
- **Playful auto-emoji** per item, via a three-stage cascade
  (`Sources/Services/Emoji.swift`):
  1. **Curated table** (`EmojiTable`, ~1750 entries, generated by
     `tools/gen_emoji.py` from inline data + `tools/emoji_supplement.txt`)
     covering produce, proteins, dairy, bakery, grains, pantry, drinks, snacks,
     frozen, prepared dishes, household/toiletry/baby/pet/health goods, **and
     global cuisines** — East/South/Southeast Asian, Middle Eastern, African,
     Latin American and European staples. The matcher prefers the longest keyword
     match, so prefix collisions resolve correctly (peach≠pea, ginger≠gin,
     hamburger≠ham).
  2. **Semantic fallback** (`SemanticEmoji`) — Apple's on-device word embeddings
     (`NLEmbedding`, fully offline) map novel items to the nearest "anchor" food
     word's emoji (e.g. "Flounder" → 🐟). This also collapses variants:
     "Frozen peas" resolves to the same glyph as "Peas".
  3. **Basket default** (🧺) when nothing else fits.

  Coverage is audited against a ~3650-item global grocery corpus
  (`tools/corpus/*.txt`, spanning world cuisines) with
  `tools/audit_coverage.swift` — currently **100%** (0 fall-throughs; ~91%
  curated, ~9% semantic).
- A warm tri-colour (green/yellow/tomato) background bloom.
- **VoiceOver support** — every interactive control (check circle, quantity
  stepper and unit pills, add bar, tip buttons, an item's name — its own
  "Rename <name>" stop, distinct from the row's quantity/restore action) has
  a proper label, hint, and action, and purely decorative flourishes
  (sparkles, the launch splash, empty state's basket emoji) are hidden from
  the accessibility tree instead of cluttering it.

## Build & run (CLI, no Xcode GUI)

Requires Xcode's command-line tools and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```sh
./build_run.sh                 # generate → build → install → launch → screenshot
./build_run.sh "iPhone 17"     # target a different simulator (name or UDID)
```

With no argument, `build_run.sh` targets a **dedicated simulator** (default name
`Basket-Claude`, an iPhone 17 Pro), resolved and created-if-missing by
`tools/loop_sim.sh`. This keeps Basket off the shared `iPhone 17 Pro` device so a
second harness loop for another project on the same Mac can't collide on it —
without a dedicated device, both loops resolve the same booted `iPhone 17 Pro`,
each re-installs and launches its own app onto it (the running app visibly
flip-flops), and `xcodebuild test` intermittently fails to launch the xctrunner.
The harness `LOCAL_DOD` (in `.harness/config/harness.env`) targets the same
dedicated device by name. Set `BASKET_SIM_NAME` to use a different one.

`build_run.sh` builds by `-target` with an explicit `SUPPORTED_PLATFORMS` because
this machine's Xcode generates a scheme whose supported-platforms list is empty.

### Signing for a device

Simulator builds need no signing. To run on a physical device, drop your Apple
Team ID into a git-ignored override (the committed project stays team-agnostic):

```sh
echo 'DEVELOPMENT_TEAM = ABCDE12345' > Signing.local.xcconfig
xcodegen generate
```

`Signing.xcconfig` (committed) optionally includes `Signing.local.xcconfig`, so
without the local file the build still works for the simulator.

## Lint

[SwiftLint](https://github.com/realm/SwiftLint) (`brew install swiftlint`) checks style
consistency, configured in `.swiftlint.yml`:

```sh
swiftlint lint
```

Generated files (`Sources/Services/EmojiTable.swift`,
`Sources/Services/SuggestionDictionary.swift`), `tools/`, `build/`, and
`Tests/__Snapshots__/` are excluded. Errors fail the build (CI runs `swiftlint lint`
before the build/test steps); warnings are advisory.

## Tests

Coverage is layered like a pyramid — pure logic at the bottom (fast, no
simulator), SwiftData/StoreKit/snapshot tests in the middle, full UI flows on
top:

- `Tests/` — the XCTest suite, run on the simulator:

  ```sh
  ./tools/loop_sim.sh >/dev/null   # ensure Basket's dedicated device exists
  xcodegen generate
  xcodebuild test -project Basket.xcodeproj -scheme Basket \
    -destination 'platform=iOS Simulator,name=Basket-Claude'
  ```

  This same command also runs `UITests/` (below) — both are wired into the
  `Basket` scheme's test action, so one `xcodebuild test` covers both
  (with code coverage gathered; view it in Xcode's Report Navigator or via
  `xcrun xccov`). Beyond the pure-logic tests in `BasketTests.swift`, this
  target holds the middle layer:

  When `Tests/` (BasketTests) hosts the app, `TestHooks.isHostedByXCTest`
  fires (`NSClassFromString("XCTestCase") != nil` — XCTest is only ever
  loaded in-process when the app is acting as a unit-test host) and
  `BasketApp.init` swaps in an inert in-memory store with no starter-item
  seeding, instead of opening and seeding the real on-device App Group
  store. `UITests/` (XCUITest) still launches the app as a separate process
  that never links XCTest, so this hook stays false there and every
  `-uiTesting` / `UITEST_STORE_URL` behaviour is unaffected. See
  `Tests/TestHostTests.swift` for the pinning assertion.

  This bypass is deliberately **partial**: only the store and starter-item
  seeding are made inert under a unit-test host. `registerFonts()` and the
  `TipJar` `@State` property still run their production paths unconditionally
  — `SnapshotTests.swift`'s reference images were recorded with the bundled
  pixel fonts registered by `BasketApp.init`, and `TipJarTests.swift`
  constructs its own `TipJar` instances, so both need the init side effects
  they already depend on to keep working.

  - `ListLogicTests.swift` — the section partitioning (to-get / recently-got
    / TTL-expired), the check-off spark→commit state machine
    (`CheckOffChoreography`), and the "Clear all" soft-delete/undo state
    machine (`ClearChoreography`), extracted from `ShoppingListView` into
    `Services/ListLogic.swift` precisely so they're testable without a
    simulator.
  - `ModelTests.swift` — SwiftData semantics against an in-memory
    `ModelContainer`: the first-launch seed (`BasketApp.seedIfEmpty`), the
    `KnownItems.rememberAdd` suggestion-memory upsert, and the
    `GroceryItem.unit` raw-string round-trip.
  - `TipJarTests.swift` — the tip jar's product loading through a local
    `SKTestSession` (StoreKitTest) on `StoreKit/Basket.storekit`. Purchases
    themselves can't run in a plain unit-test host (no UI anchor for the
    confirmation; transaction injection needs a test-plan-level StoreKit
    config) — see the scope note in the file.
  - `SnapshotTests.swift` — pixel-level reference images
    ([swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing))
    of the core views (`ItemRow` states, `QuantityEditor`, the empty state),
    stored in `Tests/__Snapshots__/`. Unlike the flow tests' screenshots
    (review aids), these are assertions — a visual regression fails the
    build. Recorded on iOS 26.x and skipped (`XCTSkip`) on other majors,
    where OS text rendering would diff without a real regression. The empty
    state's background (`BasketBackground`) takes an injectable `now:` for
    exactly the same reason as `EmptyStateView.now` — it renders a subtle
    time-of-day tint, and without pinning it the snapshot flakes against
    whatever the real wall clock says when the test happens to run.

- `tools/main.swift` — the **same source files** run natively on macOS (fast, no
  simulator needed):

  ```sh
  swiftc Sources/Services/Emoji.swift Sources/Services/EmojiTable.swift \
         Sources/Services/SemanticEmoji.swift Sources/Services/Suggestions.swift \
         Sources/Services/SuggestionDictionary.swift Sources/Models/Suggestion.swift \
         Sources/Services/Formatting.swift \
         Sources/Services/Measure.swift Sources/Services/Seasonality.swift \
         tools/main.swift -o /tmp/basket_check && /tmp/basket_check
  ```

- `tools/audit_coverage.swift` — two modes for emoji emoji mapping quality:
  - **Coverage audit** (default): counts how many of the ~3900-item corpus resolve
    via curated table vs semantic embedding vs fall back to the basket default.
    ```sh
    mkdir -p /tmp/ab && cp tools/audit_coverage.swift /tmp/ab/main.swift
    swiftc Sources/Services/EmojiTable.swift Sources/Services/SemanticEmoji.swift \
           Sources/Services/Emoji.swift /tmp/ab/main.swift -o /tmp/audit && /tmp/audit
    ```
  - **Correctness mode** (`-correctness` flag): regression testing. Runs ~180 golden
    item → emoji pairs spanning 8+ categories (food staples, UK/US synonyms,
    household, toiletries, pharmacy, baby, pet, brands, and fixed regressions
    from earlier tasks) through the real cascade and fails non-zero if any
    expectation mismatches. Use this to ensure semantic changes don't regress
    prior emoji assignments:
    ```sh
    /tmp/audit -correctness
    ```

- `UITests/` — XCUITest flow tests (add an item, suggestions, check one off,
  restore/clear "Got it", edit quantity, rename an item, empty state,
  "All done!" celebration, keyboard dismiss, persistence across relaunch)
  driving a real
  simulator through the actual UI, backed by an isolated in-memory SwiftData
  store (see `-uiTesting` / `-uiTestingEmpty` in `BasketApp.init`; the
  persistence tests point `UITEST_STORE_URL` at their own temp file instead).

  Tests run **deterministically** by default (`Services/TestHooks.swift`):
  `-uiTestingDisableAnimations` turns off UIKit/SwiftUI animations and
  shrinks the 0.55s check-commit delay, and `UITEST_FROZEN_DATE` freezes the
  wall clock (an ordinary July morning) so TTL cutoffs, holiday flourishes,
  and the day-rotating empty-state line render identically on every run —
  one check-off flow opts back into `realTiming` to keep the production
  choreography covered. Assertions never read live UI state bare: every
  state check is a bounded wait (`waitForLabel` / `waitForValue` /
  `waitForGone` / `waitForToGetCount` in `BasketUITestCase`), because
  XCUITest gives no guarantee a tap's effects have rendered by the next
  line — a bare assert can fail on a slow run or falsely pass on a stale
  read. Every step attaches a screenshot to the test report
  (`XCTAttachment`, `.lifetime = .keepAlways`), viewable in Xcode's Report
  Navigator — or export them as plain PNGs:

  ```sh
  ./tools/export_ui_screenshots.sh                 # → screenshots/ui-tests/
  ./tools/export_ui_screenshots.sh "iPhone 17"     # target a different simulator
  ```

  Interactive elements carry stable `.accessibilityIdentifier`s (`addBar.*`,
  `itemRow.*`, `quantityEditor.*`, `header.*`) so tests query by identifier
  rather than matching on copy, which is free to change independently.

  UI tests run against the simulator via the accessibility tree (XCUITest
  injects synthetic touch events into the simulator process) — they don't
  drive your physical mouse/trackpad, and can run with no visible Simulator
  window (`xcrun simctl boot` without opening `Simulator.app`).

  For a fast or timing-sensitive animation (a spark burst, a fade, a flicker)
  that a single screenshot can't prove one way or the other — and that
  XCUITest's own "wait for app to idle" settling can cause a step screenshot
  to land *after*, not during — record the simulator's own framebuffer while
  a UI test drives the interaction, same no-real-input guarantee as above:

  ```sh
  ./tools/record_ui_test.sh "BasketUITests/CheckOffFlowTests/testCheckingItemOffMovesToGotSection"
  # → screenshots/ui-tests/recordings/<test>.mov
  swift tools/extract_video_frame.swift screenshots/ui-tests/recordings/<test>.mov 2.3 frame.png
  ```

  `extract_video_frame.swift` pulls one still frame at a given timestamp via
  AVFoundation — call it a few times across the window you care about (every
  0.2-0.3s) to build a flipbook, then inspect the PNGs like any other
  screenshot.

  - `AccessibilityAuditTests.swift` runs XCTest's built-in
    `performAccessibilityAudit()` over the main list, quantity editor, empty
    state, and About sheet — catching hit-region/label/trait regressions
    automatically.
    `.contrast` and `.textClipped` are excluded wholesale (with reasons
    documented inline: the soft/pastel palette and colour emoji don't fit
    those heuristics). `.dynamicType` stays enabled — see the Dynamic Type
    note below for the small, identifier-scoped set of capped elements it
    still narrowly suppresses (documented inline, not silently ignored).
  - `DynamicTypeTests.swift` proves the Dynamic Type scaling end to end:
    launches the app once at the default content size and once at
    `UICTContentSizeCategoryAccessibilityM`, then asserts the "Milk" row's
    name label (`A11yID.ItemRow.nameLabel`) renders strictly taller under the
    larger category. `testLargestAccessibilitySizeScreensRenderWithoutBreaking`
    launches at the largest possible category
    (`UICTContentSizeCategoryAccessibilityXXXL`) and screenshots the main
    list, quantity editor, empty state, and About sheet, as visual evidence
    that nothing overlaps or clips.
  - `TapPrecisionTests.swift` stress-tests the app's smallest controls (the
    +/- stepper buttons, unit pills, the check circle) with taps offset from
    dead-center at a fixed, seeded jitter — standing in for a real finger's
    imprecision, since XCUITest's default tap always lands exactly on
    center. Every trial is asserted individually; nothing is averaged into a
    pass-rate threshold, so a real hit-target problem fails the suite
    instead of being tolerated.

> Note: `xcodebuild test` and app-icon (asset catalog) compilation require an
> installed iOS **simulator runtime matching the SDK**. If you hit "No simulator
> runtime version … available", run `xcodebuild -downloadPlatform iOS`.

### CI

`.github/workflows/ci.yml` runs the full suite (simulator tests + native
harness) on **every branch push** — pre-merge signal for worktree branches,
post-merge backstop on `main`. On failure it uploads the `.xcresult` bundle
(which contains the failure screenshots and audit logs) as a workflow
artifact. The push-triggered job retries a failed test once
(`-retry-tests-on-failure -test-iterations 2`) — a test only fails the gate if
it fails both attempts.

### Releasing to TestFlight

`.github/workflows/release.yml` is a manually-triggered (`workflow_dispatch`)
workflow — run it from the Actions tab when you want a new build on
TestFlight. It re-runs the test suite as a gate, then archives, signs, and
uploads straight to App Store Connect via `xcodebuild -exportArchive`
(`method: app-store-connect`, `destination: upload` — no `altool`/Transporter/
fastlane needed). `CFBundleVersion` (build number) is bumped to the run number
on the runner only, not committed back to the repo. Every job first selects
the newest Xcode 26 (`.github/actions/select-xcode`) so the archive builds
against the iOS 26 SDK Apple requires, rather than whatever the runner's
default Xcode happens to be.

**Bumping the marketing version.** App Store Connect closes a version's
pre-release train once that version is approved, so before uploading again you
must raise `CFBundleShortVersionString` (e.g. `1.0` → `1.0.1`). Set it in
**`project.yml`** (`targets.Basket.info.properties`), not in
`Sources/Info.plist` — the plist is **generated** by `xcodegen generate` (run
in every build and CI job) and any hand-edit is overwritten on the next
generate, with unlisted keys reset to XcodeGen's defaults. After editing
`project.yml`, run `xcodegen generate` and commit the regenerated plist too.

Requires four repo secrets, generated once from an [App Store Connect API
key](https://appstoreconnect.apple.com) (Users and Access → Integrations →
App Store Connect API). Auto-managed signing for the archive needs the key's
role to be **Admin** (App Manager can upload but can't create the distribution
profile):

- `APPSTORE_API_KEY` — the downloaded `.p8` key file's contents
- `APPSTORE_KEY_ID` / `APPSTORE_ISSUER_ID` — shown alongside the key
- `APPSTORE_TEAM_ID` — Membership details on developer.apple.com (also the
  `DEVELOPMENT_TEAM` value in your local, git-ignored `Signing.local.xcconfig`)

Once uploaded, the build appears under App Store Connect → TestFlight after
Apple finishes processing (~10-30 min) and is immediately installable by
internal testers.

## Autonomous backlog (implementation harness)

The repo carries an autonomous build harness in [`.harness/`](./.harness/README.md):
a sequential loop that builds `.harness/tracking/TASKS.json` one fully-verified
task at a time, gated on the same CI suite above. Current backlog status:

| Task | Title | Status |
|------|-------|--------|
| T001 | Fix tautological Seasonality assertion in the native harness | pending |
| T002 | UI-test launch arguments accumulate across relaunches | pending |
| T003 | flash() reads a possibly-deleted SwiftData model after 0.9s | pending |
| T004 | Log silent try? failures in persistence paths | pending |
| T005 | Model initializer defaults bypass AppClock | pending |
| T006 | Remove non-default themes; hardcode the Pastel Dots look | pending |
| T007 | Stable tie-break in emoji keyword sort (generator) | pending |
| T008 | Fix ~20 semantically wrong emoji mappings + generator duplicate warning | pending |
| T009 | Exact-word matching for short emoji keywords (kills pap/paper class) | pending |
| T010 | Head-noun preference in compound emoji matching | pending |
| T011 | Household/toiletries/pharmacy/baby/pet/brands vocabulary + corpus files | pending |
| T012 | Golden-subset correctness mode for the emoji coverage audit | pending |
| T013 | Port Measure/Seasonality/Formatting checks into XCTest | pending |
| T014 | Measure.parse rejects negative and malformed input | pending |
| T015 | SwiftLint config + CI lint step | pending |
| T016 | Delete superseded icon/art generator tools (~1,900 lines) | pending |
| T017 | Shared A11yID constants between app and UI tests | pending |
| T019 | Rename an item by tapping its name | pending |
| T020 | Undo toast for Clear all | pending |
| T021 | 'Usuals' suggestion chips on empty add-bar focus | pending |
| T023 | Success haptic on the All done! celebration + restore haptic | pending |
| T024 | Formatting cleanup: wrap over-long lines + consistent MARK usage | pending |
| T025 | Refactor ShoppingListView (extract sections + quantity handlers) | pending |
| T026 | App Group + shared SwiftData container (foundation for Siri/widgets) 🔒 | pending |
| T027 | 'Add to Basket' App Intent + App Shortcut (Siri add) | pending |
| T028 | Quick-add deep link (basket://add focuses the add bar + keyboard) | pending |
| T029 | View-only Home Screen widget (small + medium) | pending |
| T030 | Interactive widget: tap an item to check it off | pending |
| T031 | Quick-add '+' widget button + add/combined widget variants | pending |

Preview with `DRY_RUN=1 .harness/scripts/loop.sh`; run with
`.harness/scripts/supervise.sh` (from a real terminal).
