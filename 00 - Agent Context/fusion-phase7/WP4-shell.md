# WP4 — Shell Swap (state-switch + Phone Bottom Tab + Desktop Refinement)

**Branch**: `phase7/wp4-shell`
**Branches from**: `main` (after WP2 merged)
**Parallelizable with**: WP3, WP5a (3 simultaneous sessions)
**Estimated effort**: full session — highest-risk WP

---

## Goal

Replace the current single-shell FUSION layout with a viewport-conditional hybrid:
- **Desktop / iPad (≥871px)**: keep the current 72px sidebar layout, but drop the `-84px` outer margin that breaks phone.
- **Phone (<871px)**: a new bottom-tab nav (5 buttons), no sidebar column, compressed statusbar.

Implemented via `state-switch` keyed to `entity: mediaquery` value `"(min-width: 871px)"`.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md`
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md` — note layout-card width quirks (R2), kiosk-mode pattern, sidebar alignment via static padding-top
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md` — confirm WP2 merged
7. `00 - Agent Context/fusion-phase7/baseline-measurements.md` — `hui-view-container` measurements
8. `00 - Agent Context/FUSION-DESIGN-SPEC.md`
9. `config/dashboards/fusion/shell.yaml` (post-WP2)
10. `config/dashboards/fusion/statusbar.yaml` (post-WP2)
11. `config/dashboards/fusion/templates.yaml` (post-WP2)
12. HACS docs for `state-switch` card (web search)
13. Reference: BubbleDash YAML for prior art on similar mobile patterns

---

## Inputs

- `shell.yaml`, `statusbar.yaml`, `templates.yaml` from WP2.
- `state-switch` HACS card (verify installed via `ha_hacs_search`).
- Baseline measurements confirming `hui-view-container` `padding-left` collapses to 0 below ~870px.

---

## Outputs (writable scope)

- `config/dashboards/fusion/shell.yaml` — rewritten with state-switch wrapper
- `config/dashboards/fusion/statusbar.yaml` — add phone variant
- `config/dashboards/fusion/templates.yaml` — add `fusion_bottom_tab_icon` template
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP4 tests
- `00 - Agent Context/fusion-phase7/STATUS.md` — update

**Do not touch**: anything under `panels/` (WP3 territory), anything under `popups/` (WP5 territory), `fusion.yaml` entry-point.

---

## TDD additions (write first)

| ID | Type | Assertion |
|----|------|-----------|
| TEST-300 | DOM | At 1280px, sidebar (column 1) is visible with width 72px |
| TEST-301 | DOM | At 1280px, bottom tab bar is NOT in DOM |
| TEST-302 | DOM | At 1280px, statusbar grid has 8 cells |
| TEST-303 | DOM | At 1280px, no horizontal overflow on document |
| TEST-304 | DOM | At 900px, sidebar still visible (we're above 871px breakpoint) |
| TEST-305 | DOM | At 700px, sidebar NOT in DOM, bottom tab bar IS in DOM |
| TEST-306 | DOM | At 700px, bottom tab bar has 5 visible buttons |
| TEST-307 | DOM | At 700px, statusbar has 4 cells (compressed) |
| TEST-308 | DOM | At 375px, no horizontal overflow on document |
| TEST-309 | DOM | At 375px, bottom tab bar `position` computed style is `fixed` |
| TEST-310 | DOM | At 375px, bottom tab bar `bottom` computed style is `0px` |
| TEST-311 | DOM | At 375px, content area has no `-84px` left margin |
| TEST-312 | Behavioural | On phone, tap "Climate" tab → `input_select.fusion_panel` becomes `climate` |
| TEST-313 | Behavioural | On phone, tap "More" tab → overlay opens with Kitchen/Energy/Automations buttons |
| TEST-314 | Behavioural | Resizing from 1280 → 700 swaps shell from sidebar to bottom-tab without page reload |
| TEST-315 | Visual | Visual diff at 1280px vs WP2 baseline < 2% (only the dropped `-84px` margin should differ) |

Run the suite. New tests must fail.

---

## Implementation notes

### Architectural shape

```yaml
# shell.yaml
type: custom:state-switch
entity: mediaquery
default: desktop
states:
  '(min-width: 871px)':
    type: custom:layout-card
    layout_type: custom:grid-layout
    layout:
      grid-template-columns: 72px 1fr
      grid-template-rows: 42px 1fr
      grid-template-areas: '"statusbar statusbar" "sidebar content"'
      # NOTE: -84px margin REMOVED — root cause of phone breakage
      margin: 0 16px 0 16px
    cards:
      - !include statusbar.yaml          # desktop variant section
      - <sidebar definition>
      - <content area — !include of panels stays unchanged>
  '(max-width: 870px)':
    type: custom:layout-card
    layout_type: custom:grid-layout
    layout:
      grid-template-columns: 1fr
      grid-template-rows: 36px 1fr 56px   # statusbar / content / bottom-tab
      grid-template-areas: '"statusbar" "content" "bottomtab"'
      margin: 0
      padding: 0
    cards:
      - <statusbar phone variant>
      - <content area — !include of panels>
      - <bottom tab bar definition>
```

### Bottom tab bar definition

Five buttons, fixed-positioned at viewport bottom:

```yaml
type: custom:mod-card
card_mod:
  style: |
    ha-card {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      height: 56px;
      padding-bottom: env(safe-area-inset-bottom);
      background: #161616;
      border-top: 1px solid #2a2a2a;
      z-index: 100;
    }
card:
  type: horizontal-stack
  cards:
    - type: custom:button-card
      template: fusion_bottom_tab_icon
      icon: mdi:home-variant
      tap_action:
        action: perform-action
        target:
          entity_id: input_select.fusion_panel
        perform_action: input_select.select_option
        data:
          option: home
      # ... (active state via state operator on input_select)
    # 4 more: Climate, Media, Network, More
```

The "More" tab opens an overlay (could itself be a Bubble Card popup with the 3 secondary panel buttons — Kitchen, Energy, Automations).

### `fusion_bottom_tab_icon` template

Mirror `fusion_nav_icon` but with horizontal layout, larger touch target (min 44px × 44px per WCAG), no border on idle state.

```yaml
fusion_bottom_tab_icon:
  show_name: true       # show label below icon
  show_state: false
  styles:
    card:
      - background: transparent
      - border: none
      - height: 56px
      - padding: 6px 0
    icon:
      - width: 22px
      - height: 22px
      - color: '#888'
    name:
      - font-size: 10px
      - color: '#888'
      - margin-top: 2px
  state:
    - operator: template
      value: |
        [[[ return states['input_select.fusion_panel'].state === entity.attributes.tab_panel; ]]]
      styles:
        icon:
          - color: '#4f8ef7'
        name:
          - color: '#4f8ef7'
```

### Statusbar phone variant

Compress from 8 cells to 4: time, internet status, alarm/lock, battery low.
Drop padding from `0 16px 0 86px` → `0 12px`.

### The dropped `-84px` margin

The current desktop shell uses `margin: 0 16px 0 -84px`. The `-84px` was compensating for HA's `hui-view-container` 100px padding-left. **Drop the `-84px` entirely** and use `margin: 0 16px 0 16px` (or `margin: 0 16px`). Visual verification at 1280px will confirm whether the panel-edge symmetry is preserved (Phase 6l's goal).

If visual diff at 1280px > 2%: the desktop layout shifted. Inspect what other padding/margin needs to compensate. Likely need to set `padding: 0` on `hui-view-container` via card-mod at the panel level. **Don't re-add the negative margin** — that's the bug we're fixing.

### `state-switch` + `mediaquery` entity

The `mediaquery` entity is a virtual entity provided by `state-switch`. It evaluates the CSS media query in real time. Verify the syntax against current `state-switch` docs; the entity-name convention may have changed.

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp4-shell`.
3. Confirm WP2 merged.
4. Add WP4 tests to `fusion-tests.md`. Confirm they fail.
5. Verify `state-switch` is installed: `ha_hacs_search` then check or install via `ha_hacs_download`.
6. Rewrite `shell.yaml` with the state-switch wrapper. Both branches keep `!include`s for content.
7. Add the phone-variant statusbar definition (either inline in shell.yaml or extracted to `statusbar-phone.yaml`).
8. Add `fusion_bottom_tab_icon` template to `templates.yaml`.
9. Validate locally with `ha_check_config`.
10. Deploy via `deploy.sh`.
11. Visual verification at all 4 viewports — screenshot each. Verify at 700px the bottom tab is visible and the sidebar is gone; at 1280 the sidebar is back.
12. Run full test suite — all must pass.
13. Gate 2 review.
14. STATUS.md, CHANGELOG, DECISIONS, LAST_UPDATED.

---

## Stop-and-ask triggers

- `state-switch` not installed AND HACS unreachable → STOP, ask Edgar to install manually.
- Visual diff at 1280px is > 2% after dropping `-84px` → STOP. The desktop layout is shifting more than expected; needs investigation before pushing.
- The mediaquery entity doesn't refresh on resize without page reload → STOP. There may be a known limitation; alternative is `browser_mod` viewport detection.
- Bottom tab bar overlaps with last row of content (no `padding-bottom` on content area) → fix in this WP, but document the fix.
- More than 2 of the new tests fail after implementation → STOP. Bisect.

---

## Acceptance criteria

- [ ] `state-switch` wrapper at outer shell with `(min-width: 871px)` breakpoint.
- [ ] Desktop branch: sidebar visible, no `-84px` margin, statusbar 8-cell.
- [ ] Phone branch: bottom tab bar (5 buttons), no sidebar column, statusbar 4-cell.
- [ ] No horizontal overflow at any of 4 viewports.
- [ ] Resize from 1280 → 700 swaps shell live (no reload).
- [ ] All baseline + WP2 + WP3 (if merged) + WP4 tests pass.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshots at all 4 viewports saved.
- [ ] STATUS.md, CHANGELOG, DECISIONS, LAST_UPDATED updated.
- [ ] Branch merged to main.
