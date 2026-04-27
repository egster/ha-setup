# FUSION Phase 7 — Popup Pattern Recipe

**Authored by:** WP5a
**Consumed by:** WP5b (Kitchen), WP5c (Office), WP5d (Outdoor)
**Reference implementation:** [config/dashboards/fusion/popups/living-room.yaml](../../config/dashboards/fusion/popups/living-room.yaml)

This recipe is the contract for the three remaining room popups. Follow it exactly so the four popups feel uniform; deviate only with a documented reason.

---

## File contract

| Field | Value |
|-------|-------|
| Path | `config/dashboards/fusion/popups/<room-slug>.yaml` |
| Slug | kebab-case, matches the room name (e.g. `kitchen`, `office`, `outdoor`) |
| URL hash | `#popup-<room-slug>` |
| Wrapper | `_template.yaml` structure replicated verbatim, with `hash:` overridden |
| Inclusion | `- !include popups/<room-slug>.yaml` inside `shell.yaml`'s content `vertical-stack` |

The template wrapper IS duplicated across popup files. HA's `!include` substitutes whole mappings, not sub-keys, so there is no clean cross-file way to share the `styles:` block. With four popups the cost is acceptable. If a fifth lands or the styles drift, lift `styles:` into a shared `_styles.yaml` and `!include` it.

---

## Required sections, in order

Every popup renders these six sections, in this fixed order. A section never disappears — if it has nothing to show, render an empty-state row. The brief calls this "always include the section."

1. **Header** — built into the Bubble Card wrapper (`name:` + `icon:`), no card needed.
2. **Lights** — every controllable light fixture in the room, plus the master group at the top.
3. **Climate** — the Wiser thermostat (or AC) for the room. Skip ONLY if the room genuinely has no climate device. If skipped, document why in the file's header comment.
4. **Sensors** — temperature, humidity, motion. Use rooms' real sensors; if a class is missing, render a single greyed-out row ("No humidity sensor", "Motion — no sensor", etc.).
5. **Scenes** — scenes/scripts tagged to the room. Empty-state row "No scenes defined for this room" if none.
6. **Automations** — every automation that touches the room's entities. Empty-state row "No automations" if none.

---

## Card primitives

Use these primitives consistently. Don't pick a different card type for the same job in different popups.

| Job | Card type |
|-----|-----------|
| Section divider | `custom:button-card` with `template: popup_section_header` |
| Light tile (with brightness slider) | `type: tile` + `features: [{type: light-brightness}]` + `card_mod` for FUSION dark theme |
| Climate tile (with HVAC modes) | `type: thermostat` + `features: [{type: climate-hvac-modes, hvac_modes: [heat, off]}]` + `card_mod` |
| Sensor row | `custom:button-card` with `template: popup_row` |
| Empty-state row | `custom:button-card` with `template: popup_row` and `tap_action: {action: none}` + `opacity: 0.6` |
| Scene/script trigger row | `custom:button-card` with `template: popup_row` and `tap_action: scene.turn_on` / `script.turn_on` |
| Automation toggle | `type: tile` + `features: [{type: toggle}]` |
| 24h temperature chart | `custom:apexcharts-card` with `graph_span: 24h`, `header.show: false`, FUSION dark theme overrides |

**Why `tile` for lights/climate:** native HA tile features (light-brightness, climate-hvac-modes) render correct sliders and mode pickers in popups. Bubble Card wraps them cleanly. Don't reach for `custom:slider-button-card` or other HACS sliders — the native primitive is what's there.

**Why `popup_row` for scenes:** scenes tap once and fire-and-forget; they don't need a state indicator. The `popup_row` template gives them a uniform look without per-fixture state colouring.

---

## Sensors-section pattern (empty-state rows)

The Sensors section is the most likely to be sparse. Living Room has only the climate entity's `current_temperature` attribute — no humidity, no dedicated motion. The pattern:

```yaml
- type: custom:button-card
  template: popup_section_header
  name: Sensors
- type: custom:button-card
  template: popup_row
  entity: climate.<room>_area
  icon: mdi:thermometer
  name: |
    [[[
      if (!entity || !entity.attributes) return 'Temperature offline';
      const t = entity.attributes.current_temperature;
      return (t !== undefined && t !== null) ? t.toFixed(1) + ' °C' : '—';
    ]]]
- type: custom:button-card
  template: popup_row
  icon: mdi:water-percent
  name: 'Humidity — no sensor'
  tap_action:
    action: none
  styles:
    card:
      - opacity: 0.6
      # ... rest of popup_row card styles, with cursor: default
```

The empty-state row inherits the `popup_row` look but is dimmed and non-interactive. Use the `mdi:` icon for the absent class (water-percent for humidity, motion-sensor for motion) so the user reads the section as "yes, this category exists, no sensor today."

---

## Heating chart contract

Every popup with a climate section gets a 24h ApexCharts mini-chart below the thermostat. Don't switch to `mini-graph-card` — ApexCharts is the project standard for FUSION.

```yaml
- type: custom:apexcharts-card
  graph_span: 24h
  header:
    show: false
  apex_config:
    chart:
      height: 120
      background: '#1e1e1e'
      toolbar: {show: false}
    grid: {borderColor: '#2a2a2a', strokeDashArray: 2}
    xaxis: {labels: {style: {colors: '#888'}}}
    yaxis: {labels: {style: {colors: '#888'}}}
    legend: {labels: {colors: '#888'}}
    stroke: {width: 2, curve: smooth}
    tooltip: {theme: dark}
  series:
    - entity: climate.<room>_area
      name: Current
      attribute: current_temperature
      color: '#4f8ef7'
    - entity: climate.<room>_area
      name: Setpoint
      attribute: temperature
      color: '#d4a843'
      stroke_width: 1
      opacity: 0.6
```

The two series (current + setpoint) on one chart make heat-tracking legibility easy. The dark theme overrides are not optional — they make the chart legible against `#1e1e1e` row backgrounds.

---

## Automations section pattern

For each automation that touches the room's entities:

```yaml
- type: tile
  entity: automation.<name>
  name: <Friendly Automation Name>
  icon: mdi:<relevant icon>
  features_position: bottom
  features:
    - type: toggle
  card_mod:
    style: |
      ha-card {
        background: #1e1e1e !important;
        border: 1px solid #2a2a2a !important;
        border-radius: 6px !important;
        margin-bottom: 6px !important;
        --tile-color: #4caf6e;
      }
```

The toggle feature gives the on/off switch. The tile's secondary text shows last-triggered timestamp by default — no extra config needed. If a room has zero automations, render one empty-state `popup_row` with `name: 'No automations for this room'`.

---

## Tests to add (per popup)

Each downstream WP adds its tests in the same shape as TEST-400…TEST-416. Use the ID range:

| Popup | Range |
|-------|-------|
| WP5b — Kitchen | TEST-430 … TEST-439 (or extend further if needed) |
| WP5c — Office | TEST-440 … TEST-449 |
| WP5d — Outdoor | TEST-450 … TEST-459 |

For each popup, mirror these assertions (substituting the room name / hash / entities):

- YAML validity for the new file
- Entity manifest resolution (every referenced entity exists)
- Hash-based open
- Header text contains the room name
- Each of the five content sections (Lights, Climate, Sensors, Scenes, Automations) is present
- ApexCharts chart present (if the room has a climate entity)
- Dismiss + backdrop close
- FUSION token colours (#161616 background, #2a2a2a border)

The `_template.yaml` test (TEST-400) does NOT need a copy per popup — that file is shared and already covered.

---

## What NOT to do

- **Don't modify `_template.yaml`.** It is shared. If you find a bug in the wrapper, fix it once in `_template.yaml` AND in every popup file (LR + your new one) — they must stay in sync.
- **Don't modify `popup_section_header` / `popup_row` in `templates.yaml`.** They are shared. Same lock-step rule as the wrapper.
- **Don't add tap_action wiring from panels to popups.** That is WP6's job. You're populating the popup, not connecting the trigger.
- **Don't use `card-mod` to layer styles over Bubble Card.** Bubble Card's `styles:` block is the right place for popup-container CSS. card-mod is fine on inner cards (tiles, button-cards), not on the popup container.
- **Don't add new HACS dependencies.** Bubble Card and ApexCharts are confirmed installed (see DECISIONS 2026-04-22 — adapting in-place, not bringing in new HACS packages).

---

## Verification checklist before Gate 2

- [ ] File exists at `config/dashboards/fusion/popups/<slug>.yaml` and parses (yamllint clean).
- [ ] All entity references resolve via `ha_get_state` (TEST-43X / TEST-44X / TEST-45X).
- [ ] `- !include popups/<slug>.yaml` added to `shell.yaml`'s content `vertical-stack`.
- [ ] Hash navigates to the popup (`#popup-<slug>` opens it).
- [ ] All six sections render at 1280 and 375.
- [ ] FUSION dark tokens (#161616, #2a2a2a, #4f8ef7) used consistently.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshots saved under `00 - Agent Context/fusion-phase7/screenshots/wpNX/`.
