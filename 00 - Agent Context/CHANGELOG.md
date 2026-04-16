# Changelog — Edgar's Home Automation

*Maintained by the agent. Updated at the end of every working session.*

---

## 2026-04-16 — Git + SSH deploy workflow setup

Introduced git-tracked config management for the HA setup. No automations changed.

**What was set up:**
- `git init` on this project folder — initial commit of all existing context, agents, and archive files
- SSH key auth to HA Green (`~/.ssh/ha_green`, `ssh ha` alias) — passwordless access confirmed
- `/config/packages/` directory created on HA Green; `configuration.yaml` updated with `homeassistant: packages: !include_dir_named packages`
- Pre-commit hook: blocks commits with YAML syntax errors or automations missing `description:` (enforced on `config/packages/` files only)
- `deploy.sh`: single command to validate → scp → `ha core check` → reload; auto-rollbacks if config check fails
- Baseline snapshot of `automations.yaml`, `scripts.yaml`, `scenes.yaml` committed to `config/`
- `INSTRUCTIONS.md` updated: file conventions, Gate 3 pipeline (Step 4 = write+commit, Step 5 = deploy.sh, Steps 6–11 shifted), session end now includes git commit

**Decision recorded**: DECISIONS.md 2026-04-16 — git+SSH deploy over MCP writes; CI/CD pipeline ruled out.

**No HA restart needed** — `configuration.yaml` change (packages dir) takes effect on next restart; packages dir is empty so no impact until first package file is deployed.

---

## 2026-04-16 — Context compaction

- 6 entries summarised → Activity Log (BubbleDash v1, agent workflow, Zocci cleanup, Zocci deep clean, monitoring teardown, context compaction meta-entry dropped)
- 3 entries compressed (BubbleDash v2, Late Night Shutoff, Vacation mode system)
- PROFILE.md: automation count 23→24, Late Night Shutoff added to Other table, disk 10.1→11.1 GB
- BACKLOG.md: removed superseded "HA Control Dashboard" item (covered by BubbleDash v3 brainstorm)
- CHANGELOG active: 172 → ~65 lines · PROFILE active: unchanged structure, facts updated

**Backup**: `.backup/2026-04-16_082411/`

---

## 2026-04-14 — BubbleDash v2 enhanced redesign

Enhanced `dashboard-bubbledash` from v1 (basic tiles, no popups) to v2 (accent colors, live sensor sub-buttons, full room-story popups, temperature overview strip, Home tab).

**4 tabs:** 💡 Lighting (5 tile pairs, 9 room popups with motion+lux+dynamic lighting toggles, proportional All Off button), 🌡️ Heating (2+2 temp strip, Vacation Mode, 4 climate tiles → thermostat+48h history popup), 🎵 Media (unchanged), 🏠 Home (Edgar presence+battery, Zocci status, system glance, weather).

**Backup**: `Pre_BubbleDash_v2_Enhanced` (ID: `18a889b1`). Pure Lovelace change — no automations or helpers.

**System health**: Green. Disk 11.1 GB.

---

## 2026-04-14 — Late Night Light Shutoff automation

Created `automation.late_night_light_shutoff_no_motion_check`.

**Logic**: At 23:00 and 00:00, turns off Kitchen/Living Room/Office lights if ALL four motion sensors have been quiet (`last_changed` > 30 min). Any single sensor with recent motion blocks all lights.

**Sensors**: Kitchen `binary_sensor.eve_motion_20eby9901_occupancy_2`, Office `binary_sensor.office_motion_sensors`, Entrance `binary_sensor.entrance_motion_sensors` (LR proxy), Hall `binary_sensor.eve_motion_20eby9901_occupancy` (LR proxy).

**Backup**: `83a999dc`. Template validated. HA restarted; automation confirmed `on`.

**Open**: Verify first real trace at 23:00 via `ha_get_automation_traces` — confirm condition evaluates and action fires in <2s.

---

## 2026-04-13 — Vacation mode system

4 automations + 2 helpers built: `input_boolean.vacation_mode`, `input_datetime.vacation_mode_end`, activate/end/deactivate/zocci-warning automations.

🔴 **Known issue**: `scene.create` snapshots don't survive HA restart → heating restore will silently fail on reboot during vacation. Fix: replace with 3 `input_text` helpers. See BACKLOG #1.

---

## Activity log (summarised entries)

| Date | Summary | Files | Outcome |
|------|---------|-------|---------|
| 2026-04-14 | BubbleDash v1 — domain-type tabs (Lighting/Heating/Media/System). Basic tiles, no popups. Backup `31d33495`. | dashboard | Superseded by v2 same session |
| 2026-04-14 | Agent workflow redesign — `ha-code-reviewer.md` added to `.claude/agents/`. Gate 3 standardised pipeline in INSTRUCTIONS.md. Decision in DECISIONS.md. | agents/ | Live |
| 2026-04-13 | Vacation mode Zocci cleanup — removed 3 dead switch actions (HTTP 500). Notify-only pattern. Backup `MCP_2026-04-13_18:21:29`. Decision in DECISIONS.md. | automations | Clean |
| 2026-04-13 | Zocci deep clean — 3 automations + `input_boolean.zocci_deep_clean_needed`. ⚠️ No backup taken (Gate violation). | automations, helpers | Working |
| 2026-04-12 | Monitoring teardown — removed 2 automations + 23 counter helpers. Self-triggering cascade (20×), DB 453→785 MB. Lesson + decision in DECISIONS.md. | automations, helpers | Resolved |
| 2026-04-11 | Motion light blueprint fix — 3 automations updated with `dynamic_lighting_boolean` toggle + 3 new input_boolean helpers; ha-health-check skill created | automations, helpers | Blueprint `brightness` error resolved. Decision in DECISIONS.md |
| 2026-04-11 | Beamer → Uplight Front (`automation.beamer_uplight_front`) — triggers on `media_player.living_room_tv_2` from:off (Android TV quirk) | automation, helper | Tested and working |
| 2026-04-11 | Era 300 area cleanup — 2× Sonos Era 300 reassigned to Living Room; unnamed_room area deleted | area config | Resolved |
| 2026-04-10 | Initial context setup — HA queried directly via MCP (477 entities, 10 areas, 16 automations, HA Green / OS 17.2 / core-2026.4.1) | PROFILE, INSTRUCTIONS, CHANGELOG | Context established |

### Open warnings carried forward from 2026-04-11 baseline
- `automation.kitchen_remote_mapping` — `UndefinedError: 'dict object' has no attribute 'args'` from `dustins/zha-philips-hue-v2-smart-dimmer-switch-and-remote-rwl022.yaml`. Fix: use `trigger.event.data.get('args', {})`. RWL022 IEEE: `00:17:88:01:0c:2a:11:6f`.
- `automation.living_room_remote_mapping` — no traces since 2025-12-08. Confirm whether remote is still in use.
