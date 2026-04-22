# Improvement Backlog

_Last reviewed: 2026-04-19_

---

## 🏠 Automations & Logic

### 🔴 High

#### Goodnight Kill Switch
**Added**: 2026-04-17
**Status**: Backlog — not started
**What it does**: A single script/button that kills all lights, turns off TV/media, and sets ACs to night setpoints. Excludes hall upstairs lights (so you can still see walking to bed). Triggerable from dashboard, voice (Alexa/Google), or a remote button.
**Scope**: Script + optional automation for voice trigger. No new helpers expected.
**Effort**: ~30 min.

#### Low Battery Alerts
**Added**: 2026-04-17
**Status**: Backlog — not started
**What it does**: Single automation that monitors all `sensor.*_battery` entities. Fires a notification when any device drops below 15%. Set-and-forget — covers all Zigbee motion sensors, remotes, and any future battery devices automatically.
**Scope**: One automation, no helpers. Uses a numeric_state trigger with a template or a group.
**Effort**: ~20 min.

### 🟡 Medium

#### Pomodoro Desk Timer — live on 2026-04-20
**Status**: Deployed and verified (see CHANGELOG 2026-04-20). Helpers, automations, and BubbleDash Focus-row controls all live. Scene-snapshot caveats still apply (see below) and live manual smoke test (toggle on → timer starts → break-time red → toggle off → lights restore) is still Edgar's responsibility on his own time — no blocker.

**Known caveats:**
- Scene snapshot doesn't survive HA restart. If HA reboots mid-session, lights stay red until manually corrected. Low risk given 25-min window.
- Snapshot is taken at session start. Mid-session manual light adjustments won't survive reset.

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

### 🔴 High

#### FUSION Dashboard — Full Implementation
**Added**: 2026-04-22
**Status**: Backlog — design selected, not started
**Design reference**: `/Users/edgar/Documents/Claude/Artifacts/ha-dashboard-design/index.html` → FUSION tab
**Intent**: Replace BubbleDash v4 with a new dashboard built around a fixed icon sidebar + switchable content panels. Carbon dark aesthetic (`#090909` base). Layout: 36px top status bar + 58px left icon sidebar + scrollable main content area.

---

**Architecture decision (from research):**
- Panel mode dashboard with `custom:layout-card` (CSS grid: `header | sidebar | content`)
- Panel switching: `input_select.fusion_panel` (7 options) + `custom:config-template-card` conditionally rendering each panel
- Do NOT adapt `navbar-card` — build the icon sidebar fresh with `custom:button-card` + card-mod CSS

---

**Phase 0 — Prerequisites (~30 min)**
Install 3 missing HACS cards (all others already present):
1. `custom:layout-card` v2.4.7 — grid/masonry layout control (essential)
2. `custom:apexcharts-card` v2.2.3 — all charts (temperature, power, throughput)
3. `custom:config-template-card` v1.3.6 — conditional panel switching from `input_select`

Create helper:
- `input_select.fusion_panel` with options: `home`, `kitchen`, `climate`, `media`, `network`, `energy`, `automations`

---

**Phase 1 — Shell: header + sidebar + panel switcher (~2–3 hrs)**
1. Create new storage-mode dashboard `fusion` (leave BubbleDash v4 intact — run in parallel)
2. Build outer grid with `custom:layout-card`:
   - Row 1: 36px status bar — `button-card` row: presence dot · Edgar/iPad/Edphone badges · outdoor temp · WAN status · ↓↑ speeds. Entities: `person.edgar`, `device_tracker.*`, `sensor.outdoor_temp` (or met.no), `binary_sensor.wan_status`, `sensor.bq16_download`, `sensor.bq16_upload`
   - Col 1: 58px icon sidebar — 7 `button-card` icons, each fires `input_select.select_option` for `fusion_panel`. Active state: `card-mod` checks `states['input_select.fusion_panel'].state` to highlight selected icon
   - Col 2: main content — `custom:config-template-card` rendering different panel YAML based on `states['input_select.fusion_panel'].state`
3. Gate: all 7 nav icons switch cleanly, active icon highlights, no layout overflow

---

**Phase 2 — Home panel (~4–5 hrs)**
Build the most complex panel first so the architecture is proven before the simpler ones.

*Hero strip (6 tiles):* `custom:layout-card` grid 6-col. Tiles:
- Rooms occupied: count of `binary_sensor.*_occupancy` = `on`
- Lights on: count of `light.*` = `on`
- Avg temp: template average of room climate sensors
- Power now: `sensor.current_power` (or energy dashboard sensor)
- Network: `binary_sensor.wan_status`
- Media playing: count of `media_player.*` = `playing`

*Floor-grouped room grid:* One `custom:layout-card` (3-col grid) per floor section (Main / Upper / Downstairs / Outside), each preceded by a floor header row. Room cards: `custom:button-card` or `custom:mushroom-entity-card` with card-mod for the green occupancy left border. On tap: open Bubble Card popup (see Phase 4).

*Scenes row:* `horizontal-stack` of `custom:button-card` buttons wired to existing scenes (`scene.good_morning`, `scene.evening`, `script.movie_mode`, etc.)

---

**Phase 3 — Lightweight panels (~1 hr each)**

*Automations:* `custom:auto-entities` filtered to `domain: automation`, rendered as `entities` card with on/off toggles + last-triggered secondary info.

*Climate:* `custom:auto-entities` filtering all climate entities → `custom:mushroom-climate-card` per room in a grid. Below: `custom:apexcharts-card` temperature history for LR/KI/OF using `statistics` domain (long-term data).

*Media:* `custom:auto-entities` filtering `media_player.*` → `mini-media-player` or `custom:mushroom-media-player-card` per room.

*Energy:* Two `custom:mushroom-statistics-card` tiles (now / today) + `custom:apexcharts-card` power bar chart.

*Network:* Three stat tiles (WAN, uptime `sensor.bq16_uptime`, speeds) + `custom:apexcharts-card` throughput line chart (DL + UL).

---

**Phase 4 — Room popups (~2 hrs)**
Adapt existing Bubble Card popups to the Fusion style. Each room card tap → `custom:bubble-card` popup containing:
- Light section: `custom:mushroom-light-card` per light circuit (brightness slider + on/off)
- Heat section: `custom:mushroom-climate-card` (temp setpoint +/− controls) — floor heat rooms vs AC (Bedroom only)
- Media section (where applicable): `mini-media-player`

Existing Bubble Card popups from BubbleDash can be reused/adapted — don't rebuild from scratch.

---

**Phase 5 — Kitchen panel (~2–3 hrs)**
Most experimental panel — depends on HA integrations:
- **Timers**: `entities` card listing `timer.*` entities with start/pause/cancel buttons. Create `timer.kitchen_1`, `timer.kitchen_2` helpers if not present.
- **Shopping List**: Native `todo` card against `todo.shopping_list` (HA's built-in shopping list). Requires `todo` integration enabled.
- **Recipes**: Punt on dynamic recipes — use a static `markdown` card with a curated list linking to external URLs, or leave as "future" if recipe integration isn't set up.
- **Kitchen Scenes**: 4 `custom:button-card` buttons wired to kitchen-specific scenes.

---

**Phase 6 — Polish & cutover (~1–2 hrs)**
- card-mod global styling: scrollbar width, font (Inter or system-ui), accent colour `#4f8ef7`
- Test on iPad (primary device) — check layout at actual viewport, popup z-index, touch targets
- Add `fusion` to sidebar nav (HA UI Settings → Dashboard)
- Keep `lovelace` (BubbleDash) as fallback for 1–2 weeks, then archive

---

**Cards to install (Phase 0):**
| Card | HACS slug | Notes |
|---|---|---|
| layout-card | `layout-card` | New install |
| apexcharts-card | `apexcharts-card` | New install |
| config-template-card | `config-template-card` | New install |

**Cards already installed (no action):**
`button-card`, `bubble-card`, `navbar-card`, `card-mod`, `mushroom`, `auto-entities`, `decluttering-card`

**Helpers to create:**
- `input_select.fusion_panel` (Panel state — drives all switching)
- `timer.kitchen_1`, `timer.kitchen_2` (Kitchen panel)

**Known risks:**
- Config-template-card approach can feel sluggish on panel switch if the content tree is large — mitigate with `decluttering-card` templates to keep each panel's YAML shallow
- Bubble Card popups can have z-index conflicts against the fixed sidebar — test early in Phase 1
- BQ16 network sensors (`bq16_download`, `bq16_upload`, `bq16_uptime`) may need confirming entity IDs before the status bar can be wired

**Total effort**: ~15–20 hrs across 6 phases. Recommend one phase per session.
**Suggested first session**: Phase 0 + Phase 1 shell — gets the architecture proven with no visual debt.

---

### 🟡 Medium

#### Home Monitoring — Weather-Aware Heating view
**Added**: 2026-04-22
**Status**: Backlog — v1 notification ships with `weather_aware_heating.yaml` at deploy time; this tracks the dashboard follow-up.
**What**: Add a new view (or section on the existing Temperature view) to the Home Monitoring dashboard (`home-monitoring`) that shows, at a glance, what the Weather-Aware Heating automation is doing.

**Proposed cards:**
1. **Current offset gauge** — `input_number.heating_offset` (−2.0 to +2.0, coloured red/green/blue for cold boost / neutral / warm setback)
2. **3-day trailing average tile** — `input_number.outdoor_3day_avg`
3. **Rolling-window history** — history-graph of `outdoor_mean_day1/2/3` over 7 days so Edgar can see the window shifting
4. **Base vs applied setpoints** — 3 tiles per room showing `{room}_base_temp` and the current `climate.{room}_area` target, so drift is visible at a glance
5. **Season & vacation state** — read-only badges for `input_boolean.heating_season` and `input_boolean.vacation_mode`
6. **Last offset applied** — entities card showing `heating_offset` with `last_changed` timestamp (confirms automation fired)

**Why**: The v1 notification solves "did it run and what did it do" but is ephemeral. The dashboard gives persistent, glanceable state without opening the notification center.

**Effort**: ~30 min. Uses existing storage-mode dashboard (`home-monitoring`), no new resources required.

**Dependencies**: Weather-Aware Heating package must be deployed first (helpers must exist).

#### Weather-Aware Heating — Retire the daily notification
**Added**: 2026-04-22
**Status**: Backlog — revisit after ~2 weeks of successful daily notifications.
**What**: Remove the daily notify action from `weather_aware_heating.yaml` once Edgar trusts the automation. Options: (a) delete the action entirely, (b) gate behind `input_boolean.weather_heating_notify` toggle, (c) keep but only fire when offset ≠ 0.
**Why**: Daily 22:00 notifications become noise once the system is trusted. The dashboard (above entry) is the persistent visibility mechanism.
**Effort**: 5 min edit.

#### Weather-Aware Heating — Notify on met.no forecast failure
**Added**: 2026-04-22
**Status**: Backlog — low prio, nice-to-have.
**What**: If `weather.forecast_home` is unavailable at 22:00, the automation aborts cleanly (no partial writes) but Edgar isn't notified. Add an alternative path — either a second automation that fires at 22:05 and checks whether `input_number.heating_offset.last_updated` is today, or a try/catch equivalent using `continue_on_error` scoped only to the forecast fetch plus a fallback notification action.
**Why**: PROFILE.md flags met.no as intermittently unavailable. Silent skip is safe behaviour but opaque.
**Effort**: ~20 min.

#### BD-5 — Color temperature sliders in popups
**What**: Add a `color_temp` slider row to Kitchen, Office, and Living Room popups. Bubble Card supports this natively via `button_type: slider` with `attribute: color_temp`.
**Why**: Currently on/off + brightness only — color temp is a daily control that requires going to the full entity page.
**Effort**: ~30 min.
**Note**: Was in the v3 rebuild plan but not included in the final transforms. Ready to add as an incremental update.

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

#### Clean Up jlnbln Reference Files
**Added**: 2026-04-20
**Status**: Backlog — low priority
**What**: Remove leftover jlnbln dashboard reference files from `reference/`: `jlnbln-dashboard.yaml`, `jlnbln-dashboard-mapped.yaml`, `jlnbln-README.md`, and 9 `map_entities*.py` / `home_view_transform.py` scripts. Dashboard experiment abandoned — files serve no further purpose.
**Effort**: 5 min.

#### Zigbee Mesh Health
With several unavailable entities, worth checking for Zigbee range issues — especially for the IKEA Tradfi 1 and bedroom bulbs. HA's ZHA integration has a network map worth reviewing.

---

## 🔧 Infrastructure & Tooling

### 🔴 High

#### Reviewer rule: `continue_on_error` — transient-absence vs silent-failure (A2)
**Added**: 2026-04-19 (meta session retro)
**Status**: High prio, **needs refinement before writing the rule**.
**Why**: In the 2026-04-19 Pomodoro re-review, the `ha-code-reviewer` correctly distinguished between a legitimate use of `continue_on_error: true` (transient absence — e.g. `scene.pomodoro_desk_snapshot` hasn't been created yet on first run) and the DECISIONS 2026-04-13 anti-pattern (using it to mask a permanently-failing API like La Marzocco). That distinction is encoded in the reviewer's reasoning but NOT in its written anti-pattern table. Next time a different reviewer run might not apply it consistently.
**What the rule needs to cover (refinement required before adding)**:
- A positive definition: when is `continue_on_error: true` OK? (Runtime-created entities, best-effort cleanup, optional-dependency services.)
- A negative definition: when is it an anti-pattern? (Masking a service that fails every time, swallowing errors from a required step, replacing proper `condition:` checks.)
- A decision heuristic the reviewer can apply in one pass without deep context.
- Cross-references to DECISIONS 2026-04-13 and the pomodoro.yaml Reset step as exemplars.
**Open question**: is this one rule or two (one under "Legitimate patterns", one under "Anti-patterns" in the reviewer's table)? Probably two mirrored entries that point at each other.
**Effort**: ~30 min drafting + one validation pass on an existing package that uses `continue_on_error:` to see whether the rule correctly approves/blocks.

### 🟡 Medium

#### Health check — Recorder include/exclude audit (needs research)
**Added**: 2026-04-22
**Status**: Parked — needs research before scoping the check.
**What**: Extend `ha-health-check` skill to cross-reference high-write entities
(`monitoring_helper_ids`, counters, input_numbers, any entity flagged by E4 with
>50 state changes/hour) against the live recorder configuration. Warn if a
high-write entity is being recorded when it shouldn't be — directly targets the
class of failure that caused the 453→785 MB DB bloat incident.
**Why parked**: Needs research into how to read recorder config from the MCP
server. `ha_get_integration("recorder")` may or may not expose the `include`/
`exclude` glob patterns; if not, we'd need a config file read path or a
template-based inspection. Also needs a design for the "should-be-excluded"
heuristic (what's the rule — any helper ending in `_monitoring`? any counter?
baseline-flagged?). Scope creep risk.
**Pre-work required**:
1. Confirm whether recorder `include`/`exclude` is readable via MCP tools.
2. Decide on the warning threshold: too strict = noise, too loose = misses bloat.
3. Decide whether this belongs in the weekly check or a separate on-demand audit
   skill (since recorder config rarely changes).
**Effort once researched**: ~45 min to implement; research pass is ~30 min.
**Provenance**: Identified during 2026-04-22 ha-health-check improvement session
as sweep fix #3.

#### Update `deploy.sh` to auto-reload input helper domains
**Added**: 2026-04-16
**Why**: Today's Zocci+Beamer and Vacation Mode deploys both hit the same snag — `ha core reload-all` (what `deploy.sh` calls) does **not** reload `input_number`, `input_text`, `input_boolean`, `input_datetime` domains. Had to call `input_number.reload` / `input_text.reload` / `automation.reload` manually via MCP after each deploy.
**Fix**: Have `deploy.sh` parse the deployed YAML file and, if it contains `input_number:`, `input_text:`, `input_boolean:`, `input_datetime:`, `input_select:`, or `script:` top-level keys, issue the corresponding `reload` service call over the HA API. Also unconditionally call `automation.reload`.
**Caveat**: For a **first-time** load of an input domain (no existing entities), `<domain>.reload` works only after the YAML itself is valid — so validation in Step 3 is essential.
**Effort**: ~20 min.

#### ~~Track pre-commit hook in the repo~~ ✅ done 2026-04-19
**Added**: 2026-04-16 — **Completed**: 2026-04-19
**Outcome**: Hook moved to `scripts/pre-commit` (PyYAML-based; checks `description:` on every automation AND a new `# Gate 2 reviewed: YYYY-MM-DD` header line per Rule H2). Install locally with `ln -sf ../../scripts/pre-commit .git/hooks/pre-commit`. Documented in INSTRUCTIONS.md Gate 3 Step 4.

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

- **2026-04-22 — Weather-Aware Heating deployed** — `config/packages/weather_aware_heating.yaml`. Daily at 22:00, adjusts 3 Wiser thermostats (Kitchen/LR/Office) based on forecast vs 3-day trailing avg. Tier-based offset: 3 °C noise floor, ±0.5 / ±1.5 °C. 9 helpers, ~5 writes/day. Vacation + heating-season guards. Validation notification for first ~2 weeks (see backlog). 30-day ERA5 backtest validates the logic (9/29 triggers, every real event caught). See CHANGELOG 2026-04-22.
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
