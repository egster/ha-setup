# WP6 — Wiring + Bottom-Nav-Hides + Cosmetic Gaps

**Branch**: `phase7/wp6-integration`
**Branches from**: `main` (after WP3, WP4, WP5b, WP5c, WP5d all merged)
**Parallelizable with**: nothing (final integration)
**Estimated effort**: full session

---

## Goal

Wire everything together:
1. Add `tap_action` on every relevant room row in panels to open its popup.
2. Hook Bubble Card's `bubble-popup-open` body class to hide the phone bottom-tab bar when a popup is active.
3. Add the two cosmetic gap-fixes from FUSION-DESIGN-SPEC: sidebar separator (Kitchen ↔ Climate), pulsing presence dot.
4. Run full integration test pass at all viewports + popup states.

This is the final WP. After it merges, FUSION Phase 7 is done.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md`
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md`
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md` — confirm WP3, WP4, WP5b/c/d all merged
7. `00 - Agent Context/fusion-phase7/wp5-popup-pattern.md`
8. `00 - Agent Context/FUSION-DESIGN-SPEC.md` — sidebar separator + pulsing dot specs
9. `00 - Agent Context/BACKLOG.md` — item #9 (pulsing dot)
10. `config/dashboards/fusion/` — entire restructured tree
11. Bubble Card docs on the body-level class set when popup active

---

## Inputs

- All preceding WPs merged.
- Popups exist for Living Room, Kitchen, Office, Outdoor.
- Bottom tab bar exists in phone shell.

---

## Outputs (writable scope)

- `config/dashboards/fusion/panels/home.yaml` — wire tap_action on Living Room, Kitchen, Office, Outdoor rows
- `config/dashboards/fusion/panels/kitchen.yaml` — wire tap_action where Kitchen rows reference popup-eligible rooms
- `config/dashboards/fusion/panels/climate.yaml` — wire tap_action on Office, Living Room rows
- `config/dashboards/fusion/shell.yaml` — add card-mod for bottom-nav-hide and sidebar separator
- `config/dashboards/fusion/templates.yaml` — add `pulsing_presence_dot` template
- `config/dashboards/fusion/popups/_template.yaml` — add card-mod hook to set body class on popup open (verify Bubble Card already does this)
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP6 integration tests (TEST-50X range)
- `00 - Agent Context/fusion-phase7/STATUS.md`
- `00 - Agent Context/CHANGELOG.md` — Phase 7 close-out entry
- `00 - Agent Context/BACKLOG.md` — close items #9, #10, popup item; add Phase 7 retro item

---

## TDD additions

| ID | Type | Assertion |
|----|------|-----------|
| TEST-500 | Behavioural | At 1280px, tap Living Room row in home panel → `#popup-living-room` opens |
| TEST-501 | Behavioural | At 1280px, tap Kitchen row → `#popup-kitchen` opens |
| TEST-502 | Behavioural | At 1280px, tap Office row → `#popup-office` opens |
| TEST-503 | Behavioural | At 1280px, tap Outdoor row → `#popup-outdoor` opens |
| TEST-504 | Behavioural | At 375px, tap Living Room row → popup opens (works on phone shell) |
| TEST-505 | DOM | At 375px when popup is open, bottom tab bar `display` is `none` |
| TEST-506 | DOM | At 375px when popup is closed, bottom tab bar visible again |
| TEST-507 | DOM | At 1280px, sidebar separator (1px line) visible between Kitchen and Climate nav icons |
| TEST-508 | DOM | At 1280px, pulsing presence dot visible on KPI tile when at least 1 person home |
| TEST-509 | DOM | Pulsing presence dot CSS animation duration ~2s |
| TEST-510 | Visual | Full integration screenshot at 1280px, Living Room popup open — looks polished |
| TEST-511 | Visual | Full integration screenshot at 700px, Living Room popup open — bottom tab hidden |
| TEST-512 | Visual | Full integration screenshot at 375px, Living Room popup open — bottom tab hidden, popup full-width |
| TEST-513 | Behavioural | Open popup → close popup → open different popup. Bottom tab visibility transitions correctly |
| TEST-514 | Regression | All baseline + WP1–WP5d tests still pass |

Run suite. New tests fail. Existing tests still pass.

---

## Implementation notes

### Tap-action wiring on panel rows

For each row in a panel that represents a room with a popup, add:

```yaml
tap_action:
  action: navigate
  navigation_path: '#popup-living-room'   # or kitchen, office, outdoor
```

Use existing room-row template if possible — add the tap_action via per-row override since each row maps to a different popup.

### Bottom-nav-hide hook

Bubble Card adds `body.bubble-popup-open` (verify exact class name in Bubble Card source) when a popup is active. Add to `shell.yaml` (phone branch) a card-mod rule:

```yaml
card_mod:
  style: |
    body.bubble-popup-open & {
      display: none;
    }
```

If the parent-selector approach doesn't work (card-mod is shadow-DOM scoped), use a global theme injection or a `MutationObserver` JS snippet. **Verify the Bubble Card class name is what you think it is — read Bubble Card source if unsure.**

### Sidebar separator (FUSION-DESIGN-SPEC)

Between Kitchen nav icon and Climate nav icon in the sidebar, render a 1px horizontal divider:

```yaml
- type: custom:button-card
  styles:
    card:
      - background: '#2a2a2a'
      - height: 1px
      - margin: 6px 14px
      - border: none
      - padding: 0
```

Insert at the right index in the sidebar's vertical card list.

### Pulsing presence dot

Add to `templates.yaml`:

```yaml
pulsing_presence_dot:
  show_icon: false
  show_name: false
  show_state: false
  styles:
    card:
      - background: '#4caf6e'
      - width: 8px
      - height: 8px
      - border-radius: 50%
      - position: absolute
      - top: 8px
      - right: 8px
      - animation: 'pulse 2s ease-in-out infinite'
  extra_styles: |
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(1.4); }
    }
```

Apply to the "Rooms Occupied" KPI tile when `count_people_home > 0`. Use a state-conditional render.

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp6-integration`.
3. Confirm all preceding WPs merged.
4. Add WP6 tests to `fusion-tests.md`. Confirm they fail.
5. Wire tap_action in home.yaml first (all 4 popup-eligible rows). Test.
6. Wire tap_action in climate.yaml + kitchen.yaml as needed.
7. Add card-mod bottom-nav-hide rule to shell.yaml phone branch. Test on phone viewport.
8. Add sidebar separator to shell.yaml desktop branch. Visual verify.
9. Add `pulsing_presence_dot` template + apply to home panel KPI tile. Verify CSS animation runs.
10. Run full integration test suite. ALL tests must pass.
11. Visual verification at 4 viewports × (popup closed / popup open) = 8 screenshots minimum. Save under `screenshots/wp6/`.
12. Gate 2 review.
13. Gate 3 deploy.
14. Update BACKLOG: close items #9 (pulsing dot), #10 (mobile responsiveness), popup item. Add new item: "Phase 7 retro — capture lessons from parallel-session workflow."
15. Update CHANGELOG with full Phase 7 close-out summary referencing all WPs.
16. Update DECISIONS if any new architectural decision crystallized during integration.
17. Update LAST_UPDATED.
18. Final commit + push.

---

## Stop-and-ask triggers

- Bubble Card body class name is different than expected → STOP and verify by inspection before writing the hide rule.
- Tap-action navigation conflicts with row's existing more-info action → STOP, decide if the more-info action is needed (probably not on a row that opens a richer popup).
- Pulsing dot animation triggers HA's accessibility "reduced motion" warning → STOP, add `@media (prefers-reduced-motion: reduce)` override.
- An integration test fails that none of WP1–WP5 caught → STOP. There's a regression upstream. Bisect and surface.
- Visual verification reveals breakage at any viewport → STOP, do not push partial work.

---

## Acceptance criteria

- [ ] All 4 popup-row tap_actions wired in panels.
- [ ] Bottom-nav-hide rule in place and verified on phone viewport.
- [ ] Sidebar separator visible at desktop.
- [ ] Pulsing presence dot animates on home panel when occupancy > 0.
- [ ] Full test suite passes — all WPs combined, no regressions.
- [ ] Visual screenshots at 4 viewports × 2 popup states (8 total).
- [ ] `ha-code-reviewer` APPROVED.
- [ ] BACKLOG items #9, #10, popup item closed.
- [ ] CHANGELOG Phase 7 close-out entry written.
- [ ] DECISIONS updated if architectural learnings.
- [ ] LAST_UPDATED.
- [ ] Branch merged to main.
- [ ] STATUS.md shows all WPs ✅.

---

## Phase 7 close-out checklist (for the session that runs WP6)

After WP6 merges:

1. Run `ha-health-check` skill (per INSTRUCTIONS.md, 3+ changes triggers this).
2. Take final celebratory screenshots of FUSION at 1280, 900, 700, 375 — save under `00 - Agent Context/fusion-phase7/screenshots/final/`.
3. Write a short Phase 7 retro at `00 - Agent Context/retro_<date>_fusion_phase7.md` capturing:
   - Did the parallel-session model work?
   - Where did the WP briefs break down?
   - Test harness ROI — did TDD catch things in WP3/4/5/6 that gate-2 review missed?
   - Anything that should change before Phase 8.
