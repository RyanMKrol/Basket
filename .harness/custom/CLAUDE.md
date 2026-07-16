# .harness/custom/CLAUDE.md — your project-specific harness instructions

This is the **customization overlay** for `.harness/CLAUDE.md`. Anything you add here loads automatically
(the pristine `.harness/CLAUDE.md` imports it with `@custom/CLAUDE.md`), and **harness upgrades never touch
this file** — so this is where your edits belong.

## Why this file exists — the overlay rule

The harness's own prose files (`.harness/CLAUDE.md`, `README.md`, and everything under `docs/`) are
**plugin-owned**: `implementation-harness:implementation-harness-upgrade` refreshes them from the latest plugin version. If you
edit them in place, your changes collide with every future upgrade and force a manual reconcile. Instead,
put project-specific additions in the matching file under `.harness/custom/` — this tree **mirrors** the
harness layout (`custom/CLAUDE.md`, `custom/README.md`, `custom/docs/HARNESS.md`, …). The pristine files
then stay byte-identical to the plugin and upgrade cleanly, while your customizations ride along untouched.

(Scripts and config are NOT covered by this prose overlay — customize the loop via `config/harness.env`,
and if you need a script change, flag it to upstream into the plugin rather than hand-editing in place.)

Add your project's harness-authoring conventions, house rules, and reminders below.

## Basket-specific authoring conventions (apply to every task spec)

When authoring or reviewing backlog tasks for this repo, bake these repo rules into the spec's
`## Do` / `## Done when` — the cold builder only sees the spec, so restating them there is what
makes them hold:

- **Time:** any new "current time" read must go through `AppClock.now` (never bare `.now` /
  `Date()`), and animations through `withAppAnimation` / `.unlessUITesting` — otherwise the change
  escapes the UI tests' determinism switchboard (`TestHooks`). Specs for tasks touching views or
  time-dependent logic should say so explicitly.
- **Generated files:** `Sources/Services/EmojiTable.swift` and
  `Sources/Services/SuggestionDictionary.swift` are generator output (`tools/gen_emoji.py`,
  `tools/gen_suggestions.py`). A task that changes emoji/suggestion behaviour edits the GENERATOR
  or its data and regenerates — a spec must never instruct a hand-edit of the generated files.
  After emoji-data changes, the coverage audit (`tools/audit_coverage.swift` over
  `tools/corpus/*.txt`) must stay at 0 fall-throughs.
- **UI tests:** specs requiring XCUITests must require the house rules: query by
  `accessibilityIdentifier` (never display copy), use `BasketUITestCase`'s bounded waits
  (`waitForLabel` / `waitForValue` / `waitForGone` / `waitForToGetCount`) — never assert live UI
  state directly — and attach step screenshots.
- **Simulator:** the pinned local test destination is Basket's DEDICATED device `Basket-Claude`
  (an iPhone 17 Pro that `tools/loop_sim.sh` ensures exists), NEVER the shared `iPhone 17 Pro` —
  otherwise two harness loops on one Mac collide on the same booted device. The full-suite command is
  `./tools/loop_sim.sh >/dev/null && xcodegen generate && xcodebuild test -project Basket.xcodeproj
  -scheme Basket -destination 'platform=iOS Simulator,name=Basket-Claude'`. Any new task that authors
  a simulator-driving script must default it to `Basket-Claude` via `loop_sim.sh`, not the shared
  device. The fast pure-logic check is the native harness (compile `Sources` logic files +
  `tools/main.swift` — see README.md → Tests).
- **Privacy manifest:** any task whose change starts using a required-reason API (`UserDefaults`,
  file timestamps, boot time, disk space, active keyboard) must add the matching entry to
  `Sources/PrivacyInfo.xcprivacy` in the same change — App Store Connect rejects binaries without it.
- **Copy style:** no em dashes in user-facing copy (App Store text, IAP descriptions, in-app UI
  strings).
- **Layer picking:** `Sources/Theme/` counts as the `views` layer; `tools/gen_*` + `tools/corpus/`
  + the two generated Swift files are `generators`; `tools/main.swift` and everything under
  `Tests/`/`UITests/` is `tests`.
