# Improvement Backlog

_Last reviewed: 2026-04-16_

---

## 🏠 Automations & Logic

### 🟡 Medium

#### Pomodoro Desk Timer
**Added**: 2026-04-16
**Status**: Gate 2 APPROVED — ready to deploy. Parked at Edgar's request to add Bubble dashboard trigger first.
**What it does**: Dashboard toggle starts a 25-min countdown. When time is up, desk lights (`light.desk_lights`) go full red. Lights stay red until toggle is flipped off, which restores the pre-session light state via scene snapshot.

**Still needed before deploy:**
- Add a Bubble Card button/chip in the Office popup (or a dedicated Pomodoro section) to control `input_boolean.pomodoro_active` — so it can be started/stopped from the dashboard without going to the entity page. Consider showing the remaining timer time on the button (Bubble Card `entity` with a template for countdown display, or a simple toggle chip).

**Approved YAML (Gate 2 sign-off: 2026-04-16):**

*Helpers:*
```yaml
# timer.pomodoro_desk_timer
helper_type: timer
name: Pomodoro Desk Timer
icon: mdi:timer
duration: "00:25:00"

# input_boolean.pomodoro_active
helper_type: input_boolean
name: Pomodoro Active
icon: mdi:timer-outline
```

*Automations:*
```yaml
alias: Pomodoro Desk — Start
description: >
  When the Pomodoro toggle is activated, captures a snapshot of the current
  desk light state (so it can be restored later) and starts the 25-minute
  countdown. Lights are not changed at this point — only on expiry.
trigger:
  - platform: state
    entity_id: input_boolean.pomodoro_active
    to: "on"
condition: []
action:
  - service: scene.create
    data:
      scene_id: pomodoro_desk_snapshot
      snapshot_entities:
        - light.desk_lights
  - service: timer.start
    target:
      entity_id: timer.pomodoro_desk_timer
mode: single
---
alias: Pomodoro Desk — Break Time
description: >
  Fires when the 25-minute Pomodoro timer expires. Sets desk lights to full
  red as a visual break alert. Lights stay red until the user resets the
  toggle — there is no auto-restore.
trigger:
  - platform: event
    event_type: timer.finished
    event_data:
      entity_id: timer.pomodoro_desk_timer
condition: []
action:
  - service: light.turn_on
    target:
      entity_id: light.desk_lights
    data:
      rgb_color: [255, 0, 0]
      brightness: 255
mode: single
---
alias: Pomodoro Desk — Reset
description: >
  Fires when the Pomodoro toggle is turned off (either after a break or to
  cancel a running session). Cancels the timer if still active, then
  restores the desk lights to the state captured at session start.
trigger:
  - platform: state
    entity_id: input_boolean.pomodoro_active
    to: "off"
condition: []
action:
  - service: timer.cancel
    target:
      entity_id: timer.pomodoro_desk_timer
  - service: scene.turn_on
    target:
      entity_id: scene.pomodoro_desk_snapshot
mode: single
```

**Known caveats:**
- Scene snapshot doesn't survive HA restart. If HA reboots mid-session, lights stay red until manually corrected. Low risk given 25-min window.
- Snapshot is taken at session start. Mid-session manual light adjustments won't survive reset.

**Effort**: ~20 min (deploy + Bubble card).

#### Kitchen Remote Mapping — Blueprint fix
**Problem**: `UndefinedError: 'dict object' has no attribute 'args'` in the `dustins/zha-philips-hue-v2-smart-dimmer-switch-and-remote-rwl022.yaml` blueprint. RWL022 device IEEE: `00:17:88:01:0c:2a:11:6f`.
**Fix**: Read blueprint YAML via File Editor, update `trigger.event.data.args` to use `trigger.event.data.get('args', {})`.

#### Living Room Remote — Investigate
**Problem**: `automation.living_room_remote_mapping` has no traces since 2025-12-08.
**Fix**: Confirm whether the remote is still in use or if the device itself has dropped off Zigbee.

### 🟢 Low / Nice to Have

#### Bedtime / Morning Routines
Given the presence of Panasonic AC in every room + full lighting control, a bedtime scene (lower temps, dim lights) and morning scene (warm up rooms, sunrise-style lighting) could be high value. Would use the existing remote infrastructure or a dashboard button.

#### Beamer Automation — Extend to More Lights
Currently only Uplight Front. Consider extending to Uplight Back Left/Right, possibly dim Triple Light. Could also add: sunset condition (skip daytime), brightness/colour temp target.

#### Bedroom Automation
No motion light in the master bedroom currently (lights are on the wall switch → Hue bulbs switched off = unavailable). Bedroom remote mapping exists. Is there anything else wanted here?

---

## 🖥️ Dashboard (BubbleDash)

*Inspiration: [jlnbln/My-HA-Dashboard](https://github.com/jlnbln/My-HA-Dashboard) — Rounded-Bubble theme, navbar-card, room-first layout, chip summary row.*

### 🔴 High

#### BD-1 — Apply Rounded-Bubble theme
**What**: Install [rounded-bubble.yaml](https://github.com/jlnbln/My-HA-Dashboard/blob/main/rounded-bubble.yaml) as a HA theme. Sets Poppins font, full contrast scale, correct Bubble Card CSS variables (`bubble-border-radius`, `bubble-main-background-color`, etc.).
**Why**: Highest visual ROI — transforms the look with zero structural changes to the dashboard.
**Effort**: ~30 min (HACS theme install + set theme on dashboard).

#### BD-2 — Kiosk mode
**What**: Install `kiosk-mode` from HACS + `input_boolean.kiosk_mode` helper. Hides HA header/sidebar chrome. Toggle off in edit mode.
**Why**: Makes BubbleDash feel like a native app rather than a browser page.
**Effort**: ~15 min.

### 🟡 Medium

#### BD-3 — Lights-on summary chip
**What**: Template sensor counting `states.light | selectattr('state', 'eq', 'on') | count`. Display as a Bubble Card `chip` at the top of the Lighting view.
**Why**: At-a-glance status without opening a tab.
**Effort**: ~20 min (template sensor + chip card).
**Note**: Template sensor adds to recorder — check if InfluxDB already has it first.

#### BD-4 — Scene buttons in Living Room popup
**What**: Add 4 preset buttons inside `#lights-livingroom` popup: **Bright / Relax / Movie / Off**. Movie dims mains, turns on uplights. Calls `light.turn_on` with preset brightness/color_temp values — no scene entity needed.
**Why**: Single-tap mood switching without leaving the dashboard.
**Effort**: ~30 min.

#### BD-5 — Color temperature sliders in popups
**What**: Add a `color_temp` slider row to Kitchen, Office, and Living Room popups. Bubble Card supports this natively via `button_type: slider` with `attribute: color_temp`.
**Why**: Currently on/off + brightness only — color temp is a daily control that requires going to the full entity page.
**Effort**: ~45 min.

#### BD-6 — Favourites landing tab
**What**: New tab as the default view with 6–8 hand-picked controls: Kitchen main, Living Room table lamp, Office desk, all-off button, current heating overview, movie scene button. Replaces Lighting as the landing tab.
**Why**: 80% of daily use in one screen, zero extra taps.
**Effort**: ~45 min.

### 🟢 Low / Nice to Have

#### BD-7 — `navbar-card` for mobile
**What**: Install `navbar-card` from HACS. Replaces top tab bar with a bottom navigation bar — thumbs reach it naturally on phone.
**Why**: Material/iOS-style nav UX. Worth it if BubbleDash is used primarily on phone.
**Effort**: ~1 hr (HACS install + nav config). Decide based on primary device.

#### BD-8 — Room-first structural rethink
**What**: Replace 4 entity-type tabs (Lighting / Heating / Media / Home) with room-based cards on a single view. Each room = one Bubble Card opening a popup with lights + AC + media together.
**Why**: The inspiration's key structural difference — fewer mental context switches.
**Effort**: ~2 hrs. Major restructure; do BD-1 through BD-6 first and live with them before committing.

---

## 🏗️ Structure & Housekeeping

### 🟡 Medium

#### Floor Structure — Add Floors
**Goal**: Organise areas into floors for better navigation and future floor-based automations.
**Proposed structure**:
- Ground Floor: Kitchen, Living Room, Office, Entrance, Garage, Pantry (sub of Kitchen)
- First Floor: Bedroom, Upstairs, Hall (corridor), Jona's Room (Jonathan), Stairs
- Outdoor: Outdoor, Garden
**Blocker**: Hall is not yet a formal area. Lennard's room doesn't exist yet.

#### "Hall" — Create as Formal Area
**Current state**: Hall Motion Light automation works, but "Hall" isn't a defined HA area. The lights (`light.upstairs_hall_lights`) sit in the Upstairs area.
**Fix**: Create a "Hall" area (upstairs bedroom corridor), reassign `light.philips_1746430p7`, `light.philips_1746430p7_2`, and the Eve motion sensor to it.

#### Rename "Entrance Motion Lights" Automation
**Entity ID**: `automation.new_automation` — placeholder name from creation.
**Fix**: Rename to `Entrance Motion Light` and assign to the Motion Lights category.
**Effort**: 5 minutes.

### 🟢 Low / Nice to Have

#### "Tradfi 1" — Identify & Clean Up
Single orphaned IKEA E14 bulb, unavailable, no clear purpose or location. Find it physically or remove the entity.

#### Entity ID Typo Fix
`light.kitchen_rigth` → rename to correct spelling. Minor but causes confusion in dashboard YAML.

#### Zigbee Mesh Health
With several unavailable entities, worth checking for Zigbee range issues — especially for the IKEA Tradfi 1 and bedroom bulbs. HA's ZHA integration has a network map worth reviewing.

---

## 🔧 Infrastructure & Tooling

### 🟡 Medium

#### Update `deploy.sh` to auto-reload input helper domains
**Added**: 2026-04-16
**Why**: Today's Zocci+Beamer and Vacation Mode deploys both hit the same snag — `ha core reload-all` (what `deploy.sh` calls) does **not** reload `input_number`, `input_text`, `input_boolean`, `input_datetime` domains. Had to call `input_number.reload` / `input_text.reload` / `automation.reload` manually via MCP after each deploy.
**Fix**: Have `deploy.sh` parse the deployed YAML file and, if it contains `input_number:`, `input_text:`, `input_boolean:`, `input_datetime:`, or `input_select:` top-level keys, issue the corresponding `reload` service call over the HA API. Also unconditionally call `automation.reload`.
**Caveat**: For a **first-time** load of an input domain (no existing entities), `<domain>.reload` works only after the YAML itself is valid — so validation in Step 3 is essential.
**Effort**: ~20 min.

#### Track pre-commit hook in the repo
**Added**: 2026-04-16
**Why**: `.git/hooks/pre-commit` is local-only (not in git). Today's YAML-parser fix (replacing the regex that over-matched step-level `alias:` with a proper PyYAML automation-list check) would be lost if the repo is re-cloned. Recommend: move the hook to `scripts/pre-commit`, track it, and add a one-liner to the README: `ln -sf ../../scripts/pre-commit .git/hooks/pre-commit`.
**Effort**: ~10 min.

#### Test `ha-code-reviewer` agent in real Gate 2 flow
**Added**: 2026-04-14
**Progress**: ✅ Real Gate 2 cycle run on 2026-04-16 (Vacation Mode). Reviewer correctly caught 2 blocking findings (input_text min/max semantics, float-default inconsistency) + ⚠️ hardening suggestions. Also incorrectly recommended `unique_id:` on YAML-defined `input_text` — caught at deploy time via HA config errors. Net: high value, with one known fail-class to add to the reviewer's rule set.
**Remaining work**:
1. ~~Run one real code-review cycle on a new automation from Claude Code~~ ✅ done 2026-04-16
2. Run one `MODE: setup-review` pass from Claude Code
3. Schedule quarterly setup-review runs; track findings in CHANGELOG
4. Add to the reviewer's rule set: YAML-defined input_* helpers do NOT accept `unique_id` (only UI-created ones do).
**Effort**: ~30 min remaining.

---

## ✅ Completed

- **2026-04-16 — Vacation Mode scene persistence fix** — Migrated 4 automations from UI to `config/packages/vacation_mode.yaml`. Replaced `scene.create` with 3 `input_text` helpers (`vacation_restore_{office,living_room,kitchen}`) that survive HA restarts. Pre-seeded with current setpoints.
- **2026-04-16 — Zocci + Beamer fixes deployed** — 3 automations migrated from UI to 2 packages. Deep-clean reminder anchored to `input_number.zocci_coffees_at_last_clean` (bootstrap: 61). Beamer uplight 10s debounce on both triggers. Stuck `zocci_deep_clean_needed` cleared.
- **2026-04-16 — Git+SSH deploy workflow** — git init, SSH key auth to Green board (`ssh ha`), `/config/packages/` dir on HA, pre-commit hook (YAML syntax + description field), `deploy.sh` one-command deploy. All infra live.
- **2026-04-13 — Vacation Mode Zocci cleanup** — 3 dead switch actions removed, notifications updated to instruct manual handling via La Marzocco app.
- **2026-04-13 — Zocci deep clean reminder system** — 3 automations + 1 helper.
- **2026-04-12 — Monitoring system teardown** — self-triggering cascade removed, temperature poller kept.
- **2026-04-11 — Native HA Monitoring Dashboard** (`home-monitoring`) — temperature history + current values.
- **2026-04-11 — Beamer → Uplight Front** (`automation.beamer_uplight_front`) — tested by Edgar.
- **2026-04-11 — Era 300 area cleanup** — 2× Sonos Era 300 reassigned to Living Room, unnamed_room area deleted.
