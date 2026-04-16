# Changelog — Edgar's Home Automation

*Maintained by the agent. Updated at the end of every working session.*

---


## 2026-04-16 — Zocci + Beamer QC: root cause analysis, fix, code review (Gate 1+2 complete)

### What was done
- **Root cause analysis** (Gate 1): Zocci stuck boolean traced to blind `count%50` logic ignoring when cleaning happened; beamer uplight failure traced to 20ms state flicker (`playing→off→playing` at 2026-04-15 18:44:34) + `mode:single` dropping the re-trigger.
- **Solution written** (Gate 2): Zocci — new `input_number.zocci_coffees_at_last_clean` anchors reminder to actual cleaning event. Beamer — 10s debounce on both triggers, tightened `from:` list, state condition on on-branch.
- **Code review**: `ha-code-reviewer` initially BLOCKED (missing `has_value` guards on reminder template trigger). Fixed and re-reviewed → APPROVED.
- **Package files written**: `config/packages/zocci.yaml`, `config/packages/beamer_uplight_front.yaml`. YAML validated, committed.
- **Migration decision**: Edgar chose to migrate all 3 automations from UI-managed → git-tracked packages.

### What's pending (BACKLOG #1)
Gate 3 deploy deferred to Claude Code (sandbox has no SSH to HA Green). Full deploy steps documented in BACKLOG.md.

### Backup
`ff623c85` (pre-deploy, taken before validation).

---

## 2026-04-16 — Context compaction

### What was done
- 2 entries summarised into Activity Log (git+SSH workflow, prior compaction)
- 4 fixes applied to PROFILE.md (header date, Other count, Clarifications block dropped, Improvement Backlog pointer dropped)
- 2 redundant blocks dropped from INSTRUCTIONS.md ("What this folder is for", "Who is this for")
- 4 BACKLOG fixes: duplicate numbering corrected, sub-tasks 2+3 of #8 marked done, git+SSH added to Completed, Last reviewed updated

### Size after compaction
- CHANGELOG active: 41 lines ✅ (target: <50)
- PROFILE active: 175 lines ⚠️ (target: <150 — content-dense, no safe cuts remain)
- INSTRUCTIONS: 185 lines ⚠️ (target: <150 — gate workflow is load-bearing, not touched)
- BACKLOG: 138 lines (no hard target)

### Backup
Originals saved to `.backup/2026-04-16_115532/`

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
| 2026-04-16 | Git+SSH deploy workflow — git init, SSH key auth to Green (`ssh ha`), `/config/packages/` dir, pre-commit hook (YAML+description check), `deploy.sh`. Baseline snapshot committed. INSTRUCTIONS.md updated (Gate 3 + session end). Decision in DECISIONS.md. | infra | Live |
| 2026-04-16 | Context compaction — 6 entries summarised, 3 compressed. CHANGELOG 172→65 lines, PROFILE facts updated. Backup `2026-04-16_082411`. | context | Done |
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
