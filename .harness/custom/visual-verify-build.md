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

Record in the worklog which screenshots you captured (paths) and one line on what you observed.
