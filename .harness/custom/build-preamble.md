# Basket — standing rules for every build (injected into every builder prompt)

- **Never hand-edit generated files.** `Sources/Services/EmojiTable.swift` and
  `Sources/Services/SuggestionDictionary.swift` are generator output. Change behaviour by editing
  `tools/gen_emoji.py` / `tools/emoji_supplement.txt` / `tools/gen_suggestions.py` / `tools/corpus/`
  and regenerating (`python3 tools/gen_emoji.py Sources/Services/EmojiTable.swift`;
  `python3 tools/gen_suggestions.py Sources/Services/SuggestionDictionary.swift`). Likewise
  `Basket.xcodeproj` and `Sources/Info.plist` are XcodeGen output — edit `project.yml` and run
  `xcodegen generate`.
- **Determinism discipline:** new "current time" reads go through `AppClock.now`, never bare
  `.now`/`Date()`. Animations go through `withAppAnimation` / `.unlessUITesting`, never bare
  `withAnimation` / `.animation` — otherwise the change escapes the UI tests' control
  (`Sources/Services/TestHooks.swift`).
- **Test destination:** the pinned simulator is `iPhone 17 Pro`. Full suite:
  `xcodegen generate && xcodebuild test -project Basket.xcodeproj -scheme Basket -destination
  'platform=iOS Simulator,name=iPhone 17 Pro'`. Fast pure-logic check: compile the `Sources` logic
  files with `tools/main.swift` and run it (README.md → Tests). `TipJar.swift` must stay OUT of the
  native-harness compile list (it imports iOS-only StoreKit).
- **UI tests follow the house rules:** query by `accessibilityIdentifier` (never display copy);
  use `BasketUITestCase`'s bounded waits; never assert live UI state directly.
- **Never run the superseded icon tools** (`tools/make_icon*.swift`, `tools/make_basket_*.swift`)
  against `Sources/Assets.xcassets/AppIcon.appiconset/` — the shipping icon is agency artwork.
- **No real purchases:** never attempt to exercise StoreKit purchases during verification —
  product *loading* is covered by `Tests/TipJarTests.swift`; purchase flows are human-only
  (Xcode-run or App Store sandbox).
- **Required-reason APIs:** if your change starts using `UserDefaults`, file timestamps, boot
  time, disk space, or keyboard APIs, add the matching entry to `Sources/PrivacyInfo.xcprivacy`
  in the same change.
- **Copy style:** no em dashes in any user-facing string.
