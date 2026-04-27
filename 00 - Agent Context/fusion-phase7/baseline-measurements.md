# FUSION Phase 7 — Baseline Measurements

_Captured: 2026-04-26_
_Capture method: Chrome MCP (`mcp__Claude_in_Chrome__*`) against `http://homeassistant.local:8123/dashboard-fusion/fusion`_
_Active panel during capture: `input_select.fusion_panel = home`_

This file is the empirical baseline that WP1's test suite asserts against. Every WP after WP1 starts by running the suite — the numbers below are what "OK" looks like before the responsive overhaul lands.

---

## 1. `hui-view-container` padding-left by viewport

The brief's documented root cause: HA's `hui-view-container` has `padding-left: 100px` at wide viewports and collapses to `0px` once the HA `narrow` breakpoint trips. The dashboard's outer layout-card uses `margin-left: -84px` to compensate for the 100px — when padding goes to 0, the dashboard shifts 84px off-screen.

| Viewport (requested × min reachable inner) | `hui-view-container` padding-left | `padding-right` | `width` |
|----------|----------------------------------|----|----|
| 1280 × 1280 | **100px** | 0px | 1024 |
| 900 × 900   | **100px** | 0px | 644  |
| 700 × 700   | **0px**   | 0px | 700  |
| 375 × 526¹  | **0px**   | 0px | 526  |

¹ Chrome MCP minimum reachable inner-width on this setup was 526px when 375 was requested. Real iPhone (375 CSS px) cannot be tested via this harness — the 526px reading is a best-effort proxy. Manual phone test or DevTools device emulation is required to verify the 375 case directly.

**Conclusion:** narrow breakpoint sits between **700 and 900** (matches the brief's "~870px"). Below it, `hui-view-container` padding collapses and the dashboard's negative margin runs the layout off the left edge.

---

## 2. Sidebar nav icon left edge by viewport

Sample: first nav cell (a `hui-card` whose firstElementChild is `BUTTON-CARD` and whose width ≈ 72px). Position is reported in viewport CSS pixels (left edge of the cell, including the cell's own margin).

| Viewport | First nav cell `left` | Visible? | Notes |
|----------|----------------------|----------|-------|
| 1280     | **272px**             | ✅       | Sidebar OK — sits to the right of HA drawer (256px wide) + view padding (100) − layout margin (−84). |
| 900      | **272px**             | ✅       | HA drawer still expanded; same math holds. |
| 700      | **−84px**             | ❌       | **OFF-SCREEN.** narrow mode trips, padding goes to 0, layout margin remains −84. Sidebar lives entirely outside the viewport. |
| 526¹     | **−84px**             | ❌       | Same failure mode at the smallest reachable inner width. Real-phone behaviour expected to match. |

There are **8 nav cells** in the sidebar at every viewport (the count itself doesn't change — only the position): 7 panel icons (home, kitchen, climate, media, network, energy, automations) + 1 kiosk toggle.

---

## 3. Top-level structural counts (at 1280)

| Element class | Count | Note |
|---------------|-------|------|
| `hui-card` total under hui-view | 59 | Dashboard renders fully. |
| Sidebar nav cells (`button-card` width 72) | 8 | 7 nav + 1 kiosk toggle. |
| KPI tiles in hero strip | 5 | Spec calls for 6; "Power Now" is unimplemented (blocked on power-source decision — BACKLOG). |
| `layout-card` instances | 7 | Outer + per-panel containers. |

---

## 4. Active panel + input_select state

| Property | Value |
|----------|-------|
| `input_select.fusion_panel` | `home` (set explicitly during capture via `input_select.select_option`) |
| URL after dashboard load | `http://homeassistant.local:8123/dashboard-fusion/fusion` |
| `hui-root.hasAttribute('narrow')` | `false` at every tested viewport (HA's narrow detection appears to be media-query-driven, not reflected as an attribute on `hui-root`) |

---

## 5. Screenshot captures

Captured inline via Chrome MCP `computer screenshot`. **`save_to_disk: true` did not return a path on this MCP harness**, so the PNGs live as session-bound image references rather than on-disk files. The `screenshots/baseline/` directory holds a `README.md` with the regeneration procedure; future sessions running the harness re-capture and compare visually.

| Viewport | Screenshot ID | Visual notes |
|----------|---------------|--------------|
| 1280 | `ss_0733egg62` | Dashboard renders correctly. Sidebar visible left of content. KPI tiles span the row. Floor sections render. |
| 900  | `ss_1319qu8qi` | KPI tile labels truncate ("Rooms O…", "Living R…"). Sidebar still visible. Cramped but functional. |
| 700  | `ss_2231sdljc` | HA drawer collapsed (hamburger only). Dashboard content visible. **Sidebar nav column NOT visible** — confirms `left=−84` puts it off-screen. |
| 526  | `ss_3369ioal0` | Same as 700 — sidebar gone, content rendered. KPI tile labels truncate harder ("Onli…"). Card content readable. |

(IDs are session-local; reference them only within this WP1 capture session.)

---

## 6. Why "375" appears as 526 in this baseline

Chrome window resizing on this macOS host enforces a minimum window width of ~500px (chrome chrome ≈ 50–80px + viewport ≈ 526px). Requesting `375 × 812` resolves to inner width 526. The 375 viewport is therefore **inferred** from the 526 measurement: every metric that breaks at 526 will break at least as badly at 375. WP3 / WP4 must verify against real phone or DevTools device emulation before claiming closure on the phone breakage.

When WP3 / WP4 ship, re-run this capture step on a phone (real or emulated) and append the actual 375-px measurements here for completeness.

---

## 7. How to regenerate this baseline

1. Open Chrome with the claude-in-chrome extension connected and HA logged in.
2. Run the test harness in capture mode:
   ```
   ./scripts/run-fusion-tests.sh --capture-baseline
   ```
   (or equivalently, dispatch the DOM-assertion tests from a Claude session with Chrome MCP and overwrite this file with the new numbers.)
3. Diff this file against the previous version. Any movement in §1 / §2 numbers across phases is the regression signal Phase 7's WPs are working against.
