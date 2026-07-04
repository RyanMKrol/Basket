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
  - XCTest on the simulator —
    `xcodegen generate && xcodebuild test -project Basket.xcodeproj -scheme Basket -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
  - Native logic harness (fast, no simulator) — compile the pure-logic `Sources`
    files together with `tools/main.swift` and run it (see `README.md` → Tests).
- **Docs updated in the same commit:** keep `README.md` in step with behaviour.
- **Generated files regenerated, not hand-edited** (see below).

Both test commands above also run in CI (`.github/workflows/ci.yml`) on every
push to `main` — the only backstop this repo has, since there's no PR review
step (see the golden rule above). It's a best-practice safety net, not
something Apple requires for App Store submission.

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
    flourishes), `TipJar` (StoreKit 2 consumable tip jar); **generated:**
    `EmojiTable.swift`, `SuggestionDictionary.swift`.
  - `PrivacyInfo.xcprivacy` — Apple's required privacy manifest; declares the
    "required-reason" APIs the app touches (currently just `UserDefaults`, for
    `TipJar`'s tipped flag — reason `CA92.1`, own app's data only). App Store
    Connect rejects binaries missing a declaration for any required-reason API
    they use, so **add a new entry here** whenever new code starts using one
    (`UserDefaults`, file timestamps, system boot time, disk space, active
    keyboard — see Apple's required-reason API list).
- `StoreKit/Basket.storekit` — local StoreKit config for testing the tip jar.
  IAP can't be exercised by `build_run.sh` (it `simctl launch`es, bypassing the
  scheme's StoreKit config); test purchases by **Running from Xcode** (the
  generated scheme references the config) or via App Store Connect sandbox.
  `TipJar.swift` imports iOS-only StoreKit, so it's kept **out** of the
  `tools/main.swift` native-harness compile list.
- `Tests/BasketTests.swift` — XCTest (logic).
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
