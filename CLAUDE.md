# CLAUDE.md — working conventions for the Basket repo

Basket is a soft, friendly iOS shopping-list app (SwiftUI + SwiftData, on-device
only). This file is the source of truth for **how to work in this repo**. Follow
it on every task unless the user says otherwise.

## Golden rule: never work directly on `main`

Every change happens on a branch, created from an up-to-date `main`.

```sh
git checkout main && git pull --ff-only      # 1. sync main to the remote first
git checkout -b <type>/<short-slug>          # 2. branch (e.g. fix/ws-reconnect)
# … do the work, keep it green (see "Definition of done") …
git add -A && git commit -m "…"              # 3. commit on the branch
git push -u origin <branch>                  # 4. publish the branch
git checkout main && git pull --ff-only      # 5. resync main
git merge --no-ff <branch> && git push       # 6. integrate + publish
git branch -d <branch>                       # 7. clean up (also delete remote)
git push origin --delete <branch>            # 7b. remove the remote branch
```

You end back on a clean, current `main`, ready for the next task. We don't use
pull requests — merge it yourself once it's green and the user has asked for it.

### Use a git worktree for concurrent work

If more than one task may be in flight at once, isolate each in its own **git
worktree** so they never clash over the working tree or branch:

```sh
git worktree add ../basket-<slug> -b <type>/<slug> main   # new isolated checkout
# work in ../basket-<slug>, follow the branch flow above
git worktree remove ../basket-<slug>                       # when merged & done
```

Build/test inside the worktree; merge to `main` from there or from the primary
checkout. One worktree = one branch = one task.

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
    `Suggestions`, `Formatting`, `Haptics`; **generated:** `EmojiTable.swift`,
    `SuggestionDictionary.swift`.
- `Tests/BasketTests.swift` — XCTest (logic).
- `tools/` — generators & audits (run from the repo root):
  - `gen_emoji.py` → `Sources/Services/EmojiTable.swift` (curated keyword→emoji
    table, from inline data + `emoji_supplement.txt`).
  - `gen_suggestions.py` → `Sources/Services/SuggestionDictionary.swift` (from
    `corpus/grocery_corpus.txt`).
  - `audit_coverage.swift` — audits emoji coverage over `corpus/*.txt`.
  - `make_icon.swift` / `make_icon_options.swift` — render the app icon.
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
