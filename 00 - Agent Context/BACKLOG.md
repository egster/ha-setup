# Improvement Backlog

_Last reviewed: 2026-04-16_

---

## 🚨 In Progress

### Deploy Zocci + Beamer fixes (Gate 3)
**Added**: 2026-04-16
**Status**: Package files written + committed, code-reviewed (APPROVED). Gate 3 deploy pending.
**What's ready**:
- `config/packages/zocci.yaml` — two automations + new `input_number.zocci_coffees_at_last_clean` helper
- `config/packages/beamer_uplight_front.yaml` — one automation with 10s debounce fix
- Backup: `ff623c85` (pre-deploy, 2026-04-16)
**What still needs to happen** (in order):
1. Delete 3 UI-managed automations: `automation.zocci_mark_clean_done`, `automation.zocci_deep_clean_reminder`, `automation.beamer_uplight_front`
2. Run `./deploy.sh config/packages/zocci.yaml` then `./deploy.sh config/packages/beamer_uplight_front.yaml`
3. After reload, verify automations live via `ha_config_get_automation`
4. Bootstrap: `input_number.set_value` on `input_number.zocci_coffees_at_last_clean` → `61` (current coffee count); `input_boolean.turn_off` on `input_boolean.zocci_deep_clean_needed` (clear stuck state)
5. Verify + traces + health check per Gate 3 Steps 6–11
**Root causes** (for context):
- Zocci: `count % 50 == 0` was oblivious to when cleaning happened. Fix anchors to count-at-last-clean.
- Beamer: 20ms `playing→off→playing` flicker at 2026-04-15 18:44:34 caused `mode:single` to drop the re-trigger. Fix debounces both triggers 10s.
**Effort**: ~10 min in Claude Code (SSH works there).

---

## 🏠 Automations & Logic

### 🔴 High

#### Vacation Mode — Fix scene persistence (restart survival)
**Why**: `scene.vacation_mode_heating_restore` is created dynamically via `scene.create` and does not survive an HA restart. If HA reboots while Edgar is away, the Deactivate automation can't restore heating temperatures.
**Fix**: Replace the scene snapshot in `automation.vacation_mode_activate` with 3 `input_text` helpers (`input_text.vacation_restore_office`, `_living_room`, `_kitchen`). Activate writes the current temperature as a string; Deactivate reads it back with `| float`. These persist across restarts.
**Effort**: ~20 min. Must be done before vacation mode is used for real.

### 🟡 Medium

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

#### Test `ha-code-reviewer` agent in real Gate 2 flow
**Added**: 2026-04-14
**Why**: Agent drafted and smoke-tested via `general-purpose` proxy. Still needs a real Gate 2 run from Claude Code (`.claude/agents/*.md` subagents don't load in Cowork).
**Remaining work**:
1. Run one real code-review cycle on a new automation from Claude Code
2. Run one `MODE: setup-review` pass from Claude Code
3. Schedule quarterly setup-review runs; track findings in CHANGELOG
**Effort**: ~30 min.

---

## ✅ Completed

- **2026-04-16 — Git+SSH deploy workflow** — git init, SSH key auth to Green board (`ssh ha`), `/config/packages/` dir on HA, pre-commit hook (YAML syntax + description field), `deploy.sh` one-command deploy. All infra live.
- **2026-04-13 — Vacation Mode Zocci cleanup** — 3 dead switch actions removed, notifications updated to instruct manual handling via La Marzocco app.
- **2026-04-13 — Zocci deep clean reminder system** — 3 automations + 1 helper.
- **2026-04-12 — Monitoring system teardown** — self-triggering cascade removed, temperature poller kept.
- **2026-04-11 — Native HA Monitoring Dashboard** (`home-monitoring`) — temperature history + current values.
- **2026-04-11 — Beamer → Uplight Front** (`automation.beamer_uplight_front`) — tested by Edgar.
- **2026-04-11 — Era 300 area cleanup** — 2× Sonos Era 300 reassigned to Living Room, unnamed_room area deleted.
