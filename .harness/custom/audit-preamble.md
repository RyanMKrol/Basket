# Basket — standing rules for every audit (injected into every auditor prompt)

Beyond the task's `## Done when`, FAIL the audit if the diff violates any of these repo
invariants:

- **Generated files edited by hand:** any diff hunk in `Sources/Services/EmojiTable.swift` or
  `Sources/Services/SuggestionDictionary.swift` without a corresponding change to their generator
  inputs (`tools/gen_emoji.py`, `tools/emoji_supplement.txt`, `tools/corpus/`,
  `tools/gen_suggestions.py`) is a hand-edit — fail. Same for `Basket.xcodeproj` /
  `Sources/Info.plist` changes without a `project.yml` change.
- **Determinism leaks:** new code reading bare `.now` / `Date()` instead of `AppClock.now`, or
  using bare `withAnimation` / `.animation(...)` instead of `withAppAnimation` /
  `.unlessUITesting` — fail (it escapes the UI tests' frozen clock / animations-off switchboard).
- **UI-test house-rule violations:** new XCUITest code querying by display copy instead of
  `accessibilityIdentifier`, or asserting live UI state directly instead of using
  `BasketUITestCase`'s bounded waits — fail.
- **Missing privacy-manifest entry:** the diff starts using a required-reason API (`UserDefaults`,
  file timestamps, boot time, disk space, keyboard) with no matching addition to
  `Sources/PrivacyInfo.xcprivacy` — fail (App Store Connect rejects this).
- **Copy style:** an em dash introduced in a user-facing string — fail.
- **Docs lockstep:** the change alters user-visible behaviour but README.md wasn't updated in the
  same change — fail.
