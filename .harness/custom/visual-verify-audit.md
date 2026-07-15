# Basket visual-verification guidance — AUDITOR prompt

Capture independently: `./build_run.sh` (launch screenshot into `screenshots/`), and for
interaction states, run the task's XCUITests and export their step screenshots via
`tools/export_ui_screenshots.sh` (`screenshots/ui-tests/`). Judge the pixels, not the build log.

If the `## Done when` makes a fast or timing-sensitive claim (fades gracefully, never flickers
back, a burst is visible), a single screenshot is not sufficient evidence either way — re-capture it
yourself with `./tools/record_ui_test.sh` + `swift tools/extract_video_frame.swift` (README.md's
UI-test section) and judge a sequence of frames across the window that matters, not one still. Treat
a worklog claim of "watched it happen live" or similar, with no recording/frame sequence attached,
as unverified — a live watch can't be independently re-checked by you, and this repo never drives
the real screen/cursor/keyboard to verify a UI change (see README.md).

FAIL the audit if any of these hold:

- Any visual claim in the task's `## Done when` is not evidenced by an actual capture (e.g. "a
  toast appears" with no screenshot showing the toast, or a fade/flicker claim with no frame
  sequence covering the moment it happens).
- Text is clipped, truncated mid-glyph, or overlapping another element; a row's emoji, name,
  quantity chip, or check circle is displaced or missing.
- The pixel fonts (VT323 / Silkscreen) fell back to a system font, or the Pastel Dots theme's
  backdrop/cards are broken or missing.
- A newly added control visibly clashes with the soft pastel aesthetic (default-styled iOS
  controls, hard corners, saturated system blue) when the task claimed a theme-consistent look.
- An item row shows no emoji (the cascade should always produce at least 🧺), or shows a
  visibly wrong glyph for a food the task's spec names.
- The add bar is obscured, unpinned, or the keyboard covers content the task claims is visible.

A capture that cannot be produced (build_run.sh fails, UI test crashes) is itself a FAIL — do not
pass on "probably fine".
