# FUSION baseline screenshots

This directory is intentionally light. The Chrome MCP harness used during WP1 captures screenshots inline (returned as session-bound image references) but `save_to_disk: true` does not return a path on this MCP setup, so on-disk PNGs are not produced automatically.

## What WP1 captured

Inline screenshot IDs from the 2026-04-26 capture session, recorded in `../baseline-measurements.md` §5:

| Viewport | Screenshot ID |
|----------|---------------|
| 1280     | `ss_0733egg62` |
| 900      | `ss_1319qu8qi` |
| 700      | `ss_2231sdljc` |
| 526¹     | `ss_3369ioal0` |

¹ Chrome window minimum on macOS prevented hitting 375px directly; 526 is the smallest reachable. Real 375 must be tested separately.

## How to regenerate (or capture fresh PNGs once tooling allows)

From a Claude Code session with Chrome MCP connected:

1. Connect Chrome and confirm HA is logged in (`http://homeassistant.local:8123`).
2. Set the panel: call `input_select.select_option` with `option: home` for `input_select.fusion_panel`.
3. For each width in `[1280, 900, 700, 375]`:
   - `mcp__Claude_in_Chrome__resize_window` with `{width, height: 900}`
   - Wait 1s for layout to settle.
   - `mcp__Claude_in_Chrome__computer` with `action: screenshot`, `save_to_disk: true`. (If the tool returns a path, move the file to `baseline_<width>px.png` in this directory. Otherwise record the screenshot ID in `../baseline-measurements.md`.)

## Disk-based screenshots (when available)

Once a tooling path produces real PNGs, drop them here as:
- `baseline_1280px.png`
- `baseline_900px.png`
- `baseline_700px.png`
- `baseline_375px.png`

Subsequent WPs run the same capture flow and visually diff against these. WP3 + WP4 are expected to fix the phone breakage — they should overwrite `baseline_375px.png` and `baseline_700px.png` with the post-fix versions and update `../baseline-measurements.md` accordingly.
