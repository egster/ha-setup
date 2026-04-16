# Improvement Backlog

*Priority order within each tier is a starting point — Edgar to confirm.*

_Last reviewed: 2026-04-16_

---

## 🔴 High Priority

### 1. Vacation Mode — Fix scene persistence (restart survival)
**Why**: `scene.vacation_mode_heating_restore` is created dynamically via `scene.create` and does not survive an HA restart. If HA reboots while Edgar is away, the Deactivate automation can't restore heating temperatures.
**Fix**: Replace the scene snapshot in `automation.vacation_mode_activate` with 3 `input_text` helpers (`input_text.vacation_restore_office`, `_living_room`, `_kitchen`). Activate writes the current temperature as a string; Deactivate reads it back with `| float`. These persist across restarts.
**Effort**: ~20 min. Must be done before vacation mode is used for real.

---

## 🟡 Medium Priority

### 2. BubbleDash v3 — Decide Direction
**Context**: v1 (basic tiles) and v2 (accent colors, sub-buttons, popups, temp strip, Home tab) have shipped. Edgar is still not satisfied but hasn't named a specific problem. Before building v3, nail down *what's wrong* — aesthetic, information density, interaction pattern, or something else entirely.

**Brainstormed directions** (pick a lane before building anything):

**A. Visual polish / theming**
- Apply a consistent theme: frosted glass overlays, custom background image, dark/warm palette. Bubble Card supports CSS variables — a `card_mod` or `theme` pass could transform the look without touching the structure.
- Try a pre-built HA theme (e.g. iOS/Material Dark) as a baseline to see if the visual style is the issue.

**B. Richer lighting control**
- Add colour temperature / RGB sliders directly on the main tile (not inside popup) for the rooms Edgar uses most (Kitchen, Living Room, Office).
- Scene buttons inside light popups: Bright, Work, Evening, Movie — call `scene.turn_on` with preset values.
- Occupancy-aware state: tile changes colour when room is occupied (use `state_background` in Bubble Card based on motion sensor state).

**C. Heating UX — more useful temperature strip**
- The current strip shows `current_temperature` via attribute. Confirm it actually renders correctly in Bubble Card v3.1.6 (may show the climate mode string "heat" instead of the number). If broken, replace with `sensor.*` entities from the Panasonic integration that expose temperature directly.
- Add a setpoint adjustment shortcut on the tile itself (not just inside popup) — Bubble Card `climate` card_type natively supports +/- adjustment on tap-hold.

**D. Home tab — make it genuinely useful**
- Add last-automation-triggered info (logbook style card or last_triggered attribute from automation entities).
- Add a "Lights currently on" summary — template sensor counting active lights, displayed prominently.
- Replace the static system glance with a Bubble Card separator + state buttons so WAN/HA-update status uses accent color for at-a-glance health.
- Add Jona's presence (if/when a device tracker is added for him).

**E. Structural rethink — fewer taps to control**
- Challenge: most actions currently need 2 taps (tile → popup → control). For the highest-frequency actions (Kitchen main light, Living Room dimmer, Office desk), consider promoting a brightness slider *directly* on the tile face via a long-press or second sub-button instead of requiring the popup.
- Alternatively: consider a "Favourites" view as the default tab (replaces Lighting as the landing tab) with 6–8 hand-picked controls that cover 80% of daily use.

**F. Appliances dedicated section**
- Move Zocci out of Home tab into a dedicated row in a "Kitchen" section, or create a compact Appliances tab (Zocci, Miele oven, warming drawer, AC).
- Add `sensor.zocci_coffee_target_temperature` and `number.zocci_steam_level` for quick in-popup tweaks.

**Before starting v3**: Spend 2 days using v2 as-is and note the specific friction points. Vague "not happy" is expensive to fix well.

---

### 3. Floor Structure — Add Floors
**Goal**: Organise areas into floors for better navigation and future floor-based automations.
**Proposed structure**:
- Ground Floor: Kitchen, Living Room, Office, Entrance, Garage, Pantry (sub of Kitchen)
- First Floor: Bedroom, Upstairs, Hall (corridor), Jona's Room (Jonathan), Stairs
- Outdoor: Outdoor, Garden

**Blocker**: Hall is not yet a formal area. Lennard's room doesn't exist yet.

---

### 4. Rename "Entrance Motion Lights" Automation
**Entity ID**: `automation.new_automation` — clearly a placeholder from when it was created.
**Fix**: Rename to `Entrance Motion Light` and assign to the Motion Lights category.
**Effort**: 5 minutes.

---

### 5. "Hall" — Create as Formal Area
**Current state**: Hall Motion Light automation works, but "Hall" isn't a defined HA area. The lights (`light.upstairs_hall_lights`) sit in the Upstairs area.
**Fix**: Create a "Hall" area (upstairs bedroom corridor), reassign `light.philips_1746430p7`, `light.philips_1746430p7_2`, and the Eve motion sensor to it.

---

### 6. Kitchen Remote Mapping — Blueprint fix
**Problem**: `UndefinedError: 'dict object' has no attribute 'args'` in the `dustins/zha-philips-hue-v2-smart-dimmer-switch-and-remote-rwl022.yaml` blueprint. RWL022 device IEEE: `00:17:88:01:0c:2a:11:6f`.
**Fix**: Read blueprint YAML via File Editor, update `trigger.event.data.args` to use `trigger.event.data.get('args', {})`.

---

### 7. Living Room Remote — Investigate
**Problem**: `automation.living_room_remote_mapping` has no traces since 2025-12-08.
**Fix**: Confirm whether the remote is still in use or if the device itself has dropped off Zigbee.

---

### 8. Test `ha-code-reviewer` agent in real Gate 2 flow
**Added**: 2026-04-14
**Why**: The improved `ha-code-reviewer.md` agent (code-review + setup-review modes, HA-specific template rules, WebFetch allowlist, three hard rules for setup-review) was drafted and smoke-tested via `general-purpose` proxy. Still needs:
1. **Real Gate 2 test via Claude Code** — `.claude/agents/*.md` subagent type isn't loaded in Cowork; the agent only invokes natively from Claude Code. Run at least one real code-review cycle on a new automation and one setup-review pass from Claude Code to confirm fidelity.
2. ✅ **Reconcile instruction files** — INSTRUCTIONS.md now has the new Gate 1–3 flow with `ha-code-reviewer`. Single source of truth.
3. ✅ **Retire legacy critic files** — `gate2-approach-critic.md` and `gate3-plan-critic.md` moved to `Archive/`.
4. **Regression-review dormant automations** — once the agent is live, run `MODE: setup-review` quarterly. Track findings in CHANGELOG.
**Effort**: S (30 min remaining — items 1 and 4 only).

---

## 🟢 Low Priority / Nice to Have

### 9. Bedroom Automation
- No motion light in the master bedroom currently (lights are on the wall switch → Hue bulbs switched off = unavailable)
- Bedroom remote mapping exists. Is there anything else wanted here?

### 10. "Tradfi 1" — Identify & Clean Up
- Single orphaned IKEA E14 bulb, unavailable, no clear purpose or location. Find it or remove the entity.

### 11. Entity ID Typo Fix
- `light.kitchen_rigth` → rename to correct spelling. Minor but causes confusion.

---

## 💡 Agent Suggestions (Not Yet Discussed)

### A. Bedtime / Morning Routines
Given the presence of Panasonic AC in every room + full lighting control, a bedtime scene (lower temps, dim lights) and morning scene (warm up rooms, sunrise-style lighting) could be high value. Would use the existing remote infrastructure or a dashboard button.

### B. Zigbee Mesh Health
With several unavailable entities, it's worth checking if there are Zigbee range issues — especially for the IKEA Tradfi 1 and bedroom bulbs. HA's ZHA integration has a network map worth reviewing.

### C. Beamer Automation — Extend to More Lights
Currently only Uplight Front. Consider extending to Uplight Back Left/Right, possibly dim Triple Light. Could also add: sunset condition (skip daytime), brightness/colour temp target.

---

## ✅ Completed

- **2026-04-16 — Git+SSH deploy workflow** — git init, SSH key auth to Green board (`ssh ha`), `/config/packages/` dir on HA, pre-commit hook (YAML syntax + description field), `deploy.sh` one-command deploy. All infra live.
- **2026-04-13 — Vacation Mode Zocci cleanup** — 3 dead switch actions removed, notifications updated to instruct manual handling via La Marzocco app.
- **2026-04-13 — Zocci deep clean reminder system** — 3 automations + 1 helper.
- **2026-04-12 — Monitoring system teardown** — self-triggering cascade removed, temperature poller kept.
- **2026-04-11 — Native HA Monitoring Dashboard** (`home-monitoring`) — temperature history + current values.
- **2026-04-11 — Beamer → Uplight Front** (`automation.beamer_uplight_front`) — tested by Edgar.
- **2026-04-11 — Era 300 area cleanup** — 2× Sonos Era 300 reassigned to Living Room, unnamed_room area deleted.
