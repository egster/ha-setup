# WP5d — Outdoor Popup

**Branch**: `phase7/wp5d-outdoor`
**Branches from**: `main` (after WP5a merged)
**Parallelizable with**: WP5b, WP5c (3 simultaneous sessions)
**Estimated effort**: half session

---

## Goal

Implement the Outdoor "room" popup. Outdoor differs from the indoor popups: no heating section (replaced with weather/outdoor-specific tiles), and the sensor section is more substantial.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md` — Outdoor area entity inventory
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md`
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md` — confirm WP5a merged
7. `00 - Agent Context/fusion-phase7/wp5-popup-pattern.md`
8. `config/dashboards/fusion/popups/_template.yaml`
9. `config/dashboards/fusion/popups/living-room.yaml` — reference
10. `config/dashboards/fusion/templates.yaml`

---

## Inputs

- WP5a's popup template + supporting templates.
- Outdoor entity manifest (build via `ha_search_entities` for area "Outside" / floor "Outside"):
  - **Sensors (primary content)**: outdoor temperature (`input_number.monitoring_outdoor_temperature` or weather integration), humidity, UV index, wind, rain, sunrise/sunset
  - **Lights**: any outdoor lights (porch, garden, garage)
  - **Scenes**: any outdoor-tagged scenes
  - **Automations**: garden lighting, sunset triggers
  - **NO climate** — outdoor doesn't heat

---

## Outputs (writable scope)

- `config/dashboards/fusion/popups/outdoor.yaml`
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP5d tests (TEST-45X range)
- `00 - Agent Context/fusion-phase7/STATUS.md`

**Do not touch**: `_template.yaml`, `templates.yaml`, `living-room.yaml`, other popup files, panels, shell.

---

## Section adaptation

Per the WP5a pattern, the climate section is replaced with a Weather section for outdoor:

### Outdoor section order
1. Header — "Outdoor"
2. Lights — outdoor lights with brightness sliders (if dimmable)
3. **Weather** (replaces Climate)
   - Current outdoor temperature (large)
   - Humidity, UV, wind speed (smaller tiles)
   - Sunrise / sunset times (next event highlighted)
   - 24h ApexCharts temperature trend (mirrors the indoor heating chart layout)
4. Sensors — any other outdoor sensors not covered in Weather (motion, leak, soil moisture if any)
5. Scenes — outdoor scenes (empty-state if none)
6. Automations — outdoor automations

---

## TDD additions

| ID | Type | Assertion |
|----|------|-----------|
| TEST-450 | YAML | `outdoor.yaml` valid |
| TEST-451 | Entity | All entities exist |
| TEST-452 | Behavioural | `#popup-outdoor` opens popup |
| TEST-453 | DOM | Header "Outdoor" |
| TEST-454 | DOM | Lights section (if outdoor lights present; otherwise omitted with note) |
| TEST-455 | DOM | Weather section present (NOT Climate) |
| TEST-456 | DOM | Outdoor temperature displayed |
| TEST-457 | DOM | Sunrise + sunset times shown |
| TEST-458 | DOM | ApexCharts 24h outdoor temp trend rendered |
| TEST-459 | DOM | Sensors section (or empty-state) |
| TEST-460 | DOM | Scenes + Automations sections present |

Run suite. New tests fail. All else passes.

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp5d-outdoor`.
3. Confirm WP5a merged.
4. Build Outdoor entity manifest. Document at top of `outdoor.yaml`.
5. Confirm whether outdoor temperature lives at `input_number.monitoring_outdoor_temperature` or via a weather integration entity. Use the most reliable source.
6. Add WP5d tests. Confirm fail.
7. Adapt living-room.yaml structure: swap Climate for Weather section. Update entity references throughout.
8. Validate locally.
9. Deploy.
10. Visual verify `#popup-outdoor`.
11. Run suite.
12. Gate 2.
13. STATUS, CHANGELOG, LAST_UPDATED.

---

## Stop-and-ask triggers

- Outdoor temperature source unclear (multiple weather integrations, helper, or sensor) → STOP, ask Edgar which one is canonical.
- No outdoor lights at all → confirm with Edgar before omitting that section entirely.
- Sunrise/sunset entities aren't standard `sun.sun` → STOP, surface.

---

## Acceptance criteria

- [ ] `outdoor.yaml` written and valid.
- [ ] `#popup-outdoor` opens popup.
- [ ] Weather section (not Climate) rendered.
- [ ] 24h outdoor temp chart rendered.
- [ ] All baseline + WP2 + WP5a + WP5d tests pass.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshot saved.
- [ ] STATUS, CHANGELOG, LAST_UPDATED updated.
- [ ] Branch merged to main.
