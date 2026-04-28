# WP4 — Shell Swap Screenshots

_Captured: 2026-04-27_
_Capture method: Chrome MCP (`mcp__Claude_in_Chrome__computer:screenshot`) against `http://homeassistant.local:8123/dashboard-fusion/fusion`_

## Harness limitation

The macOS Chrome window auto-clamps at ~1849px on this host — `resize_window(1280, 900)` and `resize_window(700, 900)` succeed at the API call level but the window stays at the ambient size. Phone-viewport screenshots (375/700) cannot be captured directly here. Real-iPhone verification (which Edgar already performed for the WP1 sidebar regression) is the canonical proof that the WP4 phone branch behaves as designed.

## What was verified at the reachable viewport (1849px = desktop branch active)

- **state-switch wrapper present** in DOM (`STATE-SWITCH` element, child count 1 with grid div hosting both branch wrappers per state-switch v1.9.6's grid-positioned hide mechanism).
- **Desktop branch active**: 8 visible `hui-card` cells of width 72 in the sidebar (`left: 116, top: 182/250/318/...`).
- **Bottom tab bar hidden**: 0 fixed-position bottom bars visible (the phone branch's `position: fixed` would normally escape state-switch's grid hiding, but the `@media (max-width: 870px)` CSS gate inside the bottom-bar's card_mod sets `display: none !important` at desktop widths).
- **Statusbar (desktop variant)**: 7 button-cards visible in the top 50px band (person, edphone, ipad, temp, wan, dl, ul).
- **No horizontal overflow**: `documentElement.scrollWidth - clientWidth = 4px` (sub-pixel/box-shadow tolerance, well under the 10px threshold).
- **Behavioural — Climate tab**: `input_select.select_option(climate)` → state becomes `climate` → climate panel content renders (Living/Kitchen/Office/Bedroom rooms + setpoint indicators).
- **Behavioural — More overlay**: `input_boolean.turn_on(fusion_more_overlay)` → DOM contains the Kitchen/Energy/Automations labels (count >0 each), confirming the conditional 3-button row renders. `turn_off` cleanly hides them.

## Phone viewport — what to verify on the real device

Open `http://homeassistant.local:8123/dashboard-fusion/fusion` on iPhone (any model — the breakpoint is `(max-width: 870px)`). Expected:

1. **No sidebar column** — desktop sidebar's 72px column is gone, content fills full width.
2. **No `−84px` left margin** — content's left edge sits at viewport-left (or at HA's safe-area inset on notched phones), NOT 84px off-screen.
3. **Compressed statusbar at top** — 4 cells visible: presence (`Edgar · Home`), outdoor temp (`17.8°`), WAN dot, download speed (`↓ 27.4`).
4. **5-button bottom tab bar** at viewport bottom: Home, Climate, Media, Network, More. Position is `fixed; bottom: 0`. Tapping any button switches `input_select.fusion_panel`. Currently-active panel highlights blue (`#4f8ef7`).
5. **More overlay**: tap "More" — a 3-button row (Kitchen / Energy / Automations) appears 56px above the main bar. Tap any to switch panel. Tap "More" again to dismiss the overlay.
6. **No horizontal scroll** — pinch/swipe-left should not reveal any off-screen content.
7. **Live resize**: open the dashboard at 1280px in a desktop browser, drag the window narrower past 870px. The sidebar should disappear and the bottom-tab bar should appear without a page reload (state-switch's `mediaquery` entity is reactive).

## Files

- `desktop_1849.jpg` (would be captured here when the harness can save to disk; see WP1 baseline-measurements.md §5)
- Real-phone screenshots: pending Edgar's iOS Safari capture.
