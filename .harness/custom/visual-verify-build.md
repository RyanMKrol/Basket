# Basket visual-verification guidance — BUILDER prompt

Capture: run `./build_run.sh` from the repo root (worktree). It generates, builds, installs,
launches the app on the simulator and saves a screenshot into `screenshots/` — open and LOOK at
that PNG, don't just check the build succeeded. If your change is behind an interaction (quantity
editor open, item checked, suggestion chips visible, a toast showing), a launch screenshot won't
show it — additionally run the relevant XCUITest and export its step screenshots with
`tools/export_ui_screenshots.sh` (PNGs land in `screenshots/ui-tests/`, named per test step), then
look at the steps that exercise your change.

What "renders correctly" means for Basket:

- The **Pastel Dots theme** is intact: creamy cards on the soft green pixel-dot backdrop, pixel
  fonts (VT323 / Silkscreen) rendering — not a fallback system font.
- **Rows read cleanly**: emoji + name + (when set) the quantity chip on one line; long names
  truncate without pushing the chip or check circle out of place; nothing overlaps the add bar.
- **New controls belong**: anything you added matches the soft, rounded, pastel look — no default
  iOS blue buttons or sharp corners dropped into the pixel aesthetic.
- **The add bar stays pinned** at the bottom, above the keyboard, with suggestion chips floating
  above it when relevant.

**Fast or timing-sensitive claims (an animation must fade gracefully, a section must never flash
back, a burst must be visible) need more than one screenshot** — a still can't prove absence over
time, and XCUITest's own "wait for app to idle" settling can land a step screenshot *after* the
moment you actually needed, not during it. Never satisfy a claim like this by watching it happen
live and eyeballing it — that requires taking over the real screen/cursor/keyboard, which this repo
avoids (see README.md's UI-test section). Instead:

```sh
./tools/record_ui_test.sh "BasketUITests/<Suite>/<test>"   # → screenshots/ui-tests/recordings/<test>.mov
swift tools/extract_video_frame.swift screenshots/ui-tests/recordings/<test>.mov 2.3 frame.png
```

Records the simulator's own framebuffer (same mechanism as `simctl io screenshot` /
`app.screenshot()` — never the real host screen) while a UI test drives the interaction, then pull
frames at several timestamps across the window that matters (every 0.2-0.3s) and look at the
sequence for continuity — a smooth trend in opacity/scale/position across frames, not a sudden cut.
If a test exercising the exact interaction doesn't exist yet, write one (or a temporary one) rather
than reaching for anything that drives the real mouse/keyboard.

Record in the worklog which screenshots (or recording + extracted frames) you captured and one line
on what you observed.
