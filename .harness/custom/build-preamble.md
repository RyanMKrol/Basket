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
- **Test destination — always Basket's DEDICATED simulator, never the shared `iPhone 17 Pro`.**
  Two harness loops on one Mac that both resolve `iPhone 17 Pro` converge on the same booted device
  and stamp on each other (flip-flopping app, xctrunner launch failures). So target `Basket-Claude`
  (an iPhone 17 Pro that `tools/loop_sim.sh` creates-if-missing and prints the UDID of). Full suite:
  `./tools/loop_sim.sh >/dev/null && xcodegen generate && xcodebuild test -project Basket.xcodeproj
  -scheme Basket -destination 'platform=iOS Simulator,name=Basket-Claude'`.
  **This overrides any command text quoted in a task's spec or `verify`:** if a spec you are building
  still says `name=iPhone 17 Pro`, substitute `name=Basket-Claude` (with the `loop_sim.sh` prefix)
  when you actually run it. Likewise, any NEW script or tool a task has you create that boots or
  targets a simulator must default to `Basket-Claude` via `tools/loop_sim.sh`, never hard-code the
  shared `iPhone 17 Pro`. Fast pure-logic check: compile the `Sources` logic files with
  `tools/main.swift` and run it (README.md → Tests). `TipJar.swift` must stay OUT of the
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
