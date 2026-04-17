# Improvement Backlog

_Last reviewed: 2026-04-17_

---

## 🏠 Automations & Logic

### 🔴 High

#### Goodnight Kill Switch
**Added**: 2026-04-17
**Status**: Backlog — not started
**What it does**: A single script/button that kills all lights, turns off TV/media, and sets ACs to night setpoints. Excludes hall upstairs lights (so you can still see walking to bed). Triggerable from dashboard, voice (Alexa/Google), or a remote button.
**Scope**: Script + optional automation for voice trigger. No new helpers expected.
**Effort**: ~30 min.

#### Weather-Aware Room Heating
**Added**: 2026-04-17
**Status**: Backlog — not started
**What it does**: Uses motion sensors (present in almost every room) to detect unoccupied rooms and lower AC setpoints after ~30 min of no motion. Motion resumes → restore previous setpoint. Weather-aware: on nice/warm forecast days, target temps are set lower; on cold/overcast/rainy days, temps are set a bit higher. Uses `weather.forecast_home` (met.no) or Panasonic outdoor temp sensor for forecast data.
**Scope**: Likely needs `input_number` helpers per room for target temps, plus a weather-condition template. Touches all 4 Panasonic AC units. Recorder impact needs discussion (4 rooms × helpers).
**Complexity**: Medium-high — weather logic, per-room state tracking, setpoint restore. Worth a research-advisor pass at Gate 1.
**Effort**: ~2–3 hrs.

#### Low Battery Alerts
**Added**: 2026-04-17
**Status**: Backlog — not started
**What it does**: Single automation that monitors all `sensor.*_battery` entities. Fires a notification when any device drops below 15%. Set-and-forget — covers all Zigbee motion sensors, remotes, and any future battery devices automatically.
**Scope**: One automation, no helpers. Uses a numeric_state trigger with a template or a group.
**Effort**: ~20 min.

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

#### Movie Mode Enhancement
**Added**: 2026-04-17
**Status**: Backlog — parked. Check after BubbleDash scene buttons are fully wired.
**What it does**: Extend existing `script.movie_mode` to also: dim all non-LR lights, set LR AC to comfort temp, pause kitchen motion lights (so getting a snack doesn't blast you with light on return).
**Effort**: ~30 min (incremental on existing script).

#### Bedroom Automation
No motion light in the master bedroom currently (lights are on the wall switch → Hue bulbs switched off = unavailable). Bedroom remote mapping exists. Is there anything else wanted here?

---

## 🖥️ Dashboard (BubbleDash)

*Current state: v4 visual overhaul deployed 2026-04-17. 5 views (Home / Lights / Heating / Media / Settings). Rounded-Bubble dark theme, Poppins font, navbar-card sidebar, card-mod. Home view: 2-column layout with greeting+map+weather left, room cards right.*

### 🟡 Medium

#### BD-5 — Color temperature sliders in popups
**What**: Add a `color_temp` slider row to Kitchen, Office, and Living Room popups. Bubble Card supports this natively via `button_type: slider` with `attribute: color_temp`.
**Why**: Currently on/off + brightness only — color temp is a daily control that requires going to the full entity page.
**Effort**: ~30 min.
**Note**: Was in the v3 rebuild plan but not included in the final transforms. Ready to add as an incremental update.

#### BD-9 — Pomodoro controls in Office popup
**What**: Add toggle + timer display for `input_boolean.pomodoro_active` in `#room-office` popup.
**Why**: Pomodoro automation is approved but parked — needs a dashboard trigger before deploy.
**Blocked by**: Pomodoro helpers not yet deployed (see Automations section).
**Effort**: ~15 min (after helpers exist).

### 🟢 Low / Nice to Have

#### BD-10 — Navbar styling refinements
**What**: Add labels, notification badges (lights count, security), and accent colors to the navbar-card routes. Match the jlnbln example's sidebar look more closely.
**Why**: Current navbar has icons only, no labels or badges. The example has colored icons with notification counts.
**Effort**: ~30 min.

---

## 🏗️ Structure & Housekeeping

### 🟡 Medium

#### Floor Structure — Add Floors
**Goal**: Organise areas into floors for better navigation and future floor-based automations.
**Proposed structure**:
- Ground Floor: Kitchen, Living Room, Office, Entrance, Garage, Pantry (sub of Kitchen)
- First Floor: Bedroom, Upstairs, Hall (corridor), Jona's Room, Stairs
- Outdoor: Outdoor, Garden
**Blocker**: Hall is not yet a formal area. Second child's room doesn't exist yet.

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
**Fix**: Have `deploy.sh` parse the deployed YAML file and, if it contains `input_number:`, `input_text:`, `input_boolean:`, `input_datetime:`, `input_select:`, or `script:` top-level keys, issue the corresponding `reload` service call over the HA API. Also unconditionally call `automation.reload`.
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
4. ~~Add to the reviewer's rule set: YAML-defined input_* helpers do NOT accept `unique_id` (only UI-created ones do).~~ ✅ done 2026-04-16 — rule added to anti-pattern table in `ha-code-reviewer.md` § 2 as 🚫.
**Effort**: ~20 min remaining.

---

## ✅ Completed

- **2026-04-17 — BubbleDash v4 visual overhaul** — Rounded-Bubble dark theme + Poppins font + card-mod + navbar-card sidebar. Home view restructured: 2-column layout with greeting/weather/map/person left, room cards right. Supersedes BD-1 (theme), BD-2 (kiosk), BD-3 (lights chip), BD-4 (scene buttons), BD-6 (favourites landing), BD-7 (navbar), BD-8 (room-first rethink). Scripts: `script.movie_mode`, `script.lr_relax`.
- **2026-04-16 — Vacation Mode scene persistence fix** — Migrated 4 automations from UI to `config/packages/vacation_mode.yaml`. Replaced `scene.create` with 3 `input_text` helpers (`vacation_restore_{office,living_room,kitchen}`) that survive HA restarts. Pre-seeded with current setpoints.
- **2026-04-16 — Zocci + Beamer fixes deployed** — 3 automations migrated from UI to 2 packages. Deep-clean reminder anchored to `input_number.zocci_coffees_at_last_clean` (bootstrap: 61). Beamer uplight 10s debounce on both triggers. Stuck `zocci_deep_clean_needed` cleared.
- **2026-04-16 — Git+SSH deploy workflow** — git init, SSH key auth to Green board (`ssh ha`), `/config/packages/` dir on HA, pre-commit hook (YAML syntax + description field), `deploy.sh` one-command deploy. All infra live.
- **2026-04-13 — Vacation Mode Zocci cleanup** — 3 dead switch actions removed, notifications updated to instruct manual handling via La Marzocco app.
- **2026-04-13 — Zocci deep clean reminder system** — 3 automations + 1 helper.
- **2026-04-12 — Monitoring system teardown** — self-triggering cascade removed, temperature poller kept.
- **2026-04-11 — Native HA Monitoring Dashboard** (`home-monitoring`) — temperature history + current values.
- **2026-04-11 — Beamer → Uplight Front** (`automation.beamer_uplight_front`) — tested by Edgar.
- **2026-04-11 — Era 300 area cleanup** — 2× Sonos Era 300 reassigned to Living Room, unnamed_room area deleted.
