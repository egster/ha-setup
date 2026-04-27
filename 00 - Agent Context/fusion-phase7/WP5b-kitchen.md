# WP5b — Kitchen Popup

**Branch**: `phase7/wp5b-kitchen`
**Branches from**: `main` (after WP5a merged)
**Parallelizable with**: WP5c, WP5d (3 simultaneous sessions)
**Estimated effort**: half session

---

## Goal

Implement the Kitchen room popup following the pattern established by WP5a. Reuse the popup template; populate with Kitchen-specific entities.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md` — Kitchen entity inventory
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md`
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md` — confirm WP5a merged
7. `00 - Agent Context/fusion-phase7/wp5-popup-pattern.md` — recipe written by WP5a
8. `config/dashboards/fusion/popups/_template.yaml`
9. `config/dashboards/fusion/popups/living-room.yaml` — reference implementation
10. `config/dashboards/fusion/templates.yaml`

---

## Inputs

- WP5a's popup template + `popup_section_header` + `popup_row` templates.
- Living Room popup as reference.
- Kitchen entity manifest (build via `ha_search_entities` for area "Kitchen"):
  - Lights: Kitchen ZHA / Hue lights
  - Climate: Wiser Kitchen zone (verify)
  - Sensors: temperature, humidity, motion (kitchen has motion per FUSION 6m)
  - Media: any kitchen speaker
  - Scenes: per BACKLOG, Kitchen scenes (Morning Brew, Cooking Mode, Dinner Ambience, Cleaning Mode) are blocked on definition — handle empty-state gracefully
  - Automations: Kitchen motion light, etc.

---

## Outputs (writable scope)

- `config/dashboards/fusion/popups/kitchen.yaml` — Kitchen popup
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP5b tests (TEST-43X range)
- `00 - Agent Context/fusion-phase7/STATUS.md` — update

**Do not touch**: `_template.yaml`, `templates.yaml`, `living-room.yaml`, any other popup file, panels, shell. Strict scope: only `popups/kitchen.yaml`.

---

## TDD additions

Mirror the Living Room test set, IDs in TEST-43X range:

| ID | Type | Assertion |
|----|------|-----------|
| TEST-430 | YAML | `kitchen.yaml` is valid YAML |
| TEST-431 | Entity | Every entity referenced exists |
| TEST-432 | Behavioural | Navigating to `#popup-kitchen` opens the popup |
| TEST-433 | DOM | Popup contains header "Kitchen" |
| TEST-434 | DOM | Popup contains "Lights" section |
| TEST-435 | DOM | Popup contains "Climate" section (if Wiser Kitchen zone exists) |
| TEST-436 | DOM | Popup contains "Sensors" section with motion sensor state |
| TEST-437 | DOM | Popup contains "Scenes" section (empty-state if no scenes defined) |
| TEST-438 | DOM | Popup contains "Automations" section |
| TEST-439 | DOM | If Climate present, ApexCharts 24h chart rendered |

Run suite. New tests fail. All else (including WP5a's TEST-40X) must pass.

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp5b-kitchen`.
3. Confirm WP5a merged (STATUS.md).
4. Build Kitchen entity manifest. Document at top of `kitchen.yaml` as comment block.
5. Add WP5b tests to `fusion-tests.md`. Confirm fail.
6. Copy structure of `living-room.yaml`. Replace entity references with Kitchen entities.
7. Handle the empty Kitchen scenes: render the section with "No scenes defined yet — see BACKLOG" message.
8. Validate locally.
9. Deploy.
10. Manually navigate to `#popup-kitchen` and verify.
11. Run full test suite.
12. Gate 2 review.
13. STATUS.md, CHANGELOG, LAST_UPDATED.

---

## Stop-and-ask triggers

- Kitchen has no Wiser zone → confirm with Edgar before omitting climate section (likely Kitchen is not heated; if so, omit cleanly).
- WP5a's pattern doc is missing or incomplete → STOP, do not improvise; consult Edgar.
- The pattern doesn't fit Kitchen's specific entity shape (e.g. multiple media players) → STOP, propose extension before adding.

---

## Acceptance criteria

- [ ] `kitchen.yaml` written following pattern.
- [ ] Hash `#popup-kitchen` opens the popup.
- [ ] All sections present (with empty-state for scenes if applicable).
- [ ] All baseline + WP2 + WP5a + WP5b tests pass.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshot of popup saved.
- [ ] STATUS, CHANGELOG, LAST_UPDATED updated.
- [ ] Branch merged to main.
