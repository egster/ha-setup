# WP5a — Popup Template + Living Room Popup

**Branch**: `phase7/wp5a-template-livingroom`
**Branches from**: `main` (after WP2 merged)
**Parallelizable with**: WP3, WP4 (3 simultaneous sessions)
**Gates**: WP5b, WP5c, WP5d (they depend on the template this WP defines)
**Estimated effort**: full session

---

## Goal

Define the shared Bubble Card popup template and implement the first popup (Living Room) as the reference for WP5b/c/d. The template carries FUSION's dark visual identity into the popup overlay; the Living Room popup proves the pattern end-to-end.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md` — Living Room entity inventory
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md` — kiosk-mode pattern (relevant for hash navigation)
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md`
7. `00 - Agent Context/FUSION-DESIGN-SPEC.md` — visual tokens
8. `config/dashboards/fusion/templates.yaml` (post-WP2)
9. `config/dashboards/fusion/popups/` (empty directory post-WP2)
10. Bubble Card popup docs — https://github.com/Clooos/Bubble-Card (web search if needed)
11. Reference: BubbleDash YAML for prior Bubble Card popup patterns on this instance

---

## Inputs

- Bubble Card HACS dependency (verify installed; should be — used by BubbleDash).
- Living Room entity list from `PROFILE.md`. Likely entities (verify each via `ha_get_state`):
  - Lights: Hue lights in Living Room (multiple)
  - Climate: Wiser Living Room thermostat (verify entity ID)
  - Sensors: temperature, humidity (if present)
  - Motion sensor (if present)
  - Media player: Living Room speaker / TV
  - Scenes: any Living Room scenes already defined
  - Automations: Living Room motion light, etc.

---

## Outputs (writable scope)

- `config/dashboards/fusion/popups/_template.yaml` — shared popup template
- `config/dashboards/fusion/popups/living-room.yaml` — Living Room popup
- `config/dashboards/fusion/templates.yaml` — append `popup_section_header` and `popup_row` templates
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP5a tests
- `00 - Agent Context/fusion-phase7/STATUS.md` — update
- `00 - Agent Context/fusion-phase7/wp5-popup-pattern.md` — DOCUMENT the popup pattern for WP5b/c/d to follow

**Do not touch**: `shell.yaml`, `statusbar.yaml`, panel files (WP3/WP4 territory). The popup wiring (tap_action on rows) is WP6's job — do NOT modify panels to wire popups in this WP.

---

## TDD additions (write first)

| ID | Type | Assertion |
|----|------|-----------|
| TEST-400 | YAML | `_template.yaml` is valid YAML and exports a `popup_template` definition |
| TEST-401 | YAML | `living-room.yaml` is valid YAML |
| TEST-402 | Entity | Every entity referenced in living-room.yaml exists (`ha_get_state` returns valid value) |
| TEST-403 | Behavioural | Navigating to `/dashboard-fusion#popup-living-room` opens the popup |
| TEST-404 | DOM | Popup contains a header with text "Living Room" |
| TEST-405 | DOM | Popup contains a "Lights" section with at least 1 brightness slider |
| TEST-406 | DOM | Popup contains a "Climate" section with current temperature + setpoint controls |
| TEST-407 | DOM | Popup contains a "Sensors" section showing temperature and humidity |
| TEST-408 | DOM | Popup contains a "Scenes" section with at least 1 scene button |
| TEST-409 | DOM | Popup contains an "Automations" section listing Living Room automations |
| TEST-410 | DOM | Popup contains an ApexCharts chart for heating (24h temperature trend) |
| TEST-411 | Behavioural | Tapping the X / dismiss button closes the popup |
| TEST-412 | Behavioural | Tapping the backdrop closes the popup |
| TEST-413 | DOM | Popup background uses FUSION token `--s2: #161616` |
| TEST-414 | DOM | Popup borders use FUSION token `--bd: #2a2a2a` |
| TEST-415 | Visual | Popup at 375px viewport occupies full width and ≥80% height |
| TEST-416 | Visual | Popup at 1280px viewport is centered with max-width ~700px |

Run the suite. New tests must fail.

---

## Popup content spec — Living Room

Per Edgar's instruction, popup contains (in this order):

### 1. Header
- Room name "Living Room"
- Dismiss X button (top right)
- Swipe-down handle (Bubble Card built-in)

### 2. Lights section
- Section header: "Lights"
- For each light entity in the room: a row showing
  - Icon (mdi:lightbulb-outline / mdi:lightbulb based on state)
  - Light name
  - Master toggle (on/off)
  - Brightness slider (only if light is on AND supports brightness)
- Master "All Lights" toggle at top of section

### 3. Climate section (if Wiser zone exists for Living Room)
- Section header: "Climate"
- Current temperature (large)
- Setpoint with +/- controls
- Mode selector (heat / off)
- Mini chart: 24h temperature trend via `custom:apexcharts-card` (compact mode, height ~120px)

### 4. Sensors section
- Section header: "Sensors"
- Temperature sensor reading (if present)
- Humidity sensor reading (if present)
- Motion sensor state (if present)
- Any other Living Room sensors from PROFILE

### 5. Scenes section
- Section header: "Scenes"
- Buttons for each scene tagged to Living Room (e.g. "Movie Night", "LR Relax", "Lights Off")
- If scenes don't exist yet → render an empty-state message "No scenes defined for this room"

### 6. Automations section
- Section header: "Automations"
- For each automation involving Living Room entities:
  - Automation name
  - Enabled / disabled toggle
  - Last triggered timestamp (small, secondary)

---

## Popup template structure (`_template.yaml`)

```yaml
# Shared popup template — used by all room popups
# WP5a defines this; WP5b/c/d extend it.
# DO NOT modify the structure here without coordinating across all popup WPs.

popup_template:
  type: custom:bubble-card
  card_type: popup
  hash: '#popup-PLACEHOLDER'      # each popup overrides
  button_type: card
  styles: |
    .bubble-popup-container {
      background: #161616 !important;
      border-top: 1px solid #2a2a2a;
      border-radius: 12px 12px 0 0;
      padding: 16px;
      max-width: 700px;
      margin: 0 auto;
    }
    .bubble-header { color: #e8e8e8; font-size: 18px; font-weight: 600; }
    .bubble-section-header {
      color: #888;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin: 16px 0 8px 0;
    }
    .bubble-row {
      background: #1e1e1e;
      border: 1px solid #2a2a2a;
      border-radius: 6px;
      padding: 10px 12px;
      margin-bottom: 6px;
    }

popup_section_header:
  # Reusable button-card template for the section header rows
  show_icon: false
  show_state: false
  show_name: true
  styles:
    card:
      - background: transparent
      - border: none
      - padding: 16px 0 8px 0
      - height: auto
    name:
      - color: '#888'
      - font-size: 11px
      - font-weight: 600
      - text-transform: uppercase
      - letter-spacing: 1px

popup_row:
  # Reusable button-card template for content rows inside popups
  styles:
    card:
      - background: '#1e1e1e'
      - border: 1px solid '#2a2a2a'
      - border-radius: 6px
      - padding: 10px 12px
      - margin-bottom: 6px
      - height: auto
```

---

## Pattern doc to write (`wp5-popup-pattern.md`)

This doc is consumed by WP5b/c/d. Write it as a clear recipe:

1. File location: `config/dashboards/fusion/popups/<room-name>.yaml`
2. Hash: `#popup-<room-slug>` (kebab case)
3. Always include sections in this order: Header → Lights → Climate (if heating) → Sensors → Scenes → Automations
4. Use `popup_template` for the wrapper
5. Use `popup_section_header` for section dividers
6. Use `popup_row` for content rows
7. Heating chart: `custom:apexcharts-card` with `graph_span: 24h`, `height: 120`, FUSION dark theme overrides
8. Empty-state pattern: if no entities for a section, render a single "no items" row instead of omitting the section
9. Test format: each WP5b/c/d adds tests TEST-43X (Kitchen), TEST-44X (Office), TEST-45X (Outdoor) in the same shape as TEST-40X

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp5a-template-livingroom`.
3. Confirm WP2 merged.
4. Verify Bubble Card installed (`ha_hacs_search "Bubble Card"`); install if missing.
5. List Living Room entities via `ha_search_entities` and `ha_get_state` for each. Document the entity manifest in the popup file's header comment.
6. Add WP5a tests to `fusion-tests.md`. Confirm they fail.
7. Write `_template.yaml` first.
8. Write `popup_section_header` and `popup_row` template additions to `templates.yaml`.
9. Write `living-room.yaml` using the templates.
10. Write `wp5-popup-pattern.md` based on the working Living Room implementation.
11. Validate locally with `ha_check_config`.
12. Deploy.
13. Manually navigate to `#popup-living-room` in Chrome MCP and verify popup renders.
14. Run full test suite.
15. Gate 2 review.
16. STATUS.md, CHANGELOG, DECISIONS, LAST_UPDATED.

---

## Stop-and-ask triggers

- Bubble Card popup hash routing collides with HA's existing hash routing → STOP, surface to Edgar.
- Living Room has no Wiser climate zone → confirm with Edgar before omitting the climate section.
- ApexCharts dark theme needs custom config beyond what's available → STOP, ask if a simpler chart (mini-graph-card) is acceptable.
- Slider control for Hue light brightness doesn't render correctly inside Bubble Card popup → STOP. Bubble Card's slider behavior may need wrapping.
- Card-mod styles don't penetrate the popup's shadow DOM → use Bubble Card's built-in `styles:` block as in the template above; do not try to layer card-mod over Bubble Card.

---

## Acceptance criteria

- [ ] `_template.yaml` defined and valid.
- [ ] `living-room.yaml` defined and valid.
- [ ] All 6 sections present in popup (Header, Lights, Climate, Sensors, Scenes, Automations).
- [ ] Climate section includes 24h ApexCharts mini-chart.
- [ ] Hash navigation (`#popup-living-room`) opens the popup.
- [ ] Popup styled with FUSION dark tokens.
- [ ] All baseline + WP2 + WP5a tests pass.
- [ ] `wp5-popup-pattern.md` written for downstream WPs.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshots saved (popup at 375 + 1280).
- [ ] STATUS.md, CHANGELOG, DECISIONS, LAST_UPDATED updated.
- [ ] Branch merged to main.
