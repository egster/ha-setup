# WP5c — Office Popup

**Branch**: `phase7/wp5c-office`
**Branches from**: `main` (after WP5a merged)
**Parallelizable with**: WP5b, WP5d (3 simultaneous sessions)
**Estimated effort**: half session

---

## Goal

Implement the Office room popup. Office has a Wiser heating zone, so the climate section + 24h ApexCharts chart applies fully. Use it to validate the heating chart implementation that WP5a established.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md` — Office entity inventory, Wiser zones
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md`
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md` — confirm WP5a merged
7. `00 - Agent Context/fusion-phase7/wp5-popup-pattern.md` — recipe from WP5a
8. `config/dashboards/fusion/popups/_template.yaml`
9. `config/dashboards/fusion/popups/living-room.yaml` — reference
10. `config/dashboards/fusion/templates.yaml`

---

## Inputs

- WP5a's popup template + supporting templates.
- Living Room popup as reference (in particular the heating chart).
- Office entity manifest (build via `ha_search_entities` for area "Office"):
  - Lights: Office lights (per PROFILE — likely Hue or ZHA)
  - Climate: **Wiser Office zone** (heating chart applies)
  - Sensors: temperature, humidity, motion (Office has motion per FUSION 6m)
  - Media: any office speaker (probably none)
  - Scenes: any Office-tagged scenes
  - Automations: Office motion light, etc.

---

## Outputs (writable scope)

- `config/dashboards/fusion/popups/office.yaml`
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP5c tests (TEST-44X range)
- `00 - Agent Context/fusion-phase7/STATUS.md`

**Do not touch**: `_template.yaml`, `templates.yaml`, `living-room.yaml`, other popup files, panels, shell.

---

## TDD additions

| ID | Type | Assertion |
|----|------|-----------|
| TEST-440 | YAML | `office.yaml` valid |
| TEST-441 | Entity | All referenced entities exist |
| TEST-442 | Behavioural | `#popup-office` opens popup |
| TEST-443 | DOM | Header "Office" |
| TEST-444 | DOM | Lights section with brightness sliders for office lights |
| TEST-445 | DOM | Climate section present with current temp + setpoint |
| TEST-446 | DOM | ApexCharts 24h chart visible in climate section |
| TEST-447 | DOM | Sensors section with motion state |
| TEST-448 | DOM | Scenes section (empty-state if none) |
| TEST-449 | DOM | Automations section |

Run suite. New tests fail. All else passes.

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp5c-office`.
3. Confirm WP5a merged.
4. Build Office entity manifest. Document at top of `office.yaml`.
5. Add WP5c tests. Confirm fail.
6. Copy living-room.yaml structure. Replace entities with Office's.
7. Verify the heating chart entity reference is `climate.wiser_office` (or whatever the actual Wiser entity is — confirm via `ha_get_state`).
8. Validate locally.
9. Deploy.
10. Visual verify `#popup-office`.
11. Run suite.
12. Gate 2.
13. STATUS, CHANGELOG, LAST_UPDATED.

---

## Stop-and-ask triggers

- Wiser Office zone entity ID doesn't match expected naming → STOP, surface to Edgar.
- ApexCharts 24h history shows no data (recorder retention or missing entity) → STOP. Don't ship a popup with a broken chart.
- Office has no scenes AND user wants to add some now → STOP. Adding scenes is out of scope for WP5c.

---

## Acceptance criteria

- [ ] `office.yaml` written and valid.
- [ ] `#popup-office` opens popup with all 6 sections.
- [ ] Heating chart renders 24h trend.
- [ ] All baseline + WP2 + WP5a + WP5c tests pass.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshot saved.
- [ ] STATUS, CHANGELOG, LAST_UPDATED updated.
- [ ] Branch merged to main.
