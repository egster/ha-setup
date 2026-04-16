# Changelog — Edgar's Home Automation

*Maintained by the agent. Updated at the end of every working session.*

---


## 2026-04-16 — Zocci+Beamer Gate 3 deploy + Vacation Mode migration (scene persistence fix)

### What was done

**Zocci + Beamer (completing the In Progress backlog item)**
- Deleted 3 UI-managed automations: `zocci_mark_clean_done`, `zocci_deep_clean_reminder`, `beamer_uplight_front`.
- Deployed `config/packages/zocci.yaml` + `config/packages/beamer_uplight_front.yaml` via `deploy.sh`.
- Bootstrapped helpers: `input_number.zocci_coffees_at_last_clean → 61` (current coffee count); `input_boolean.zocci_deep_clean_needed → off` (cleared the stuck flag).
- Traces clean; all 3 automations `state: on`.

**Vacation Mode scene persistence fix (BACKLOG 🔴 High #1)**
- Migrated all 4 vacation mode automations (Activate, End, Deactivate, Zocci Warning) from UI-managed to `config/packages/vacation_mode.yaml`. IDs preserved.
- Replaced `scene.create` (ephemeral, lost on HA restart) with 3 `input_text` helpers: `vacation_restore_office`, `vacation_restore_living_room`, `vacation_restore_kitchen`. These persist across restarts.
- Activate uses `state_attr(..., 'temperature') | default(X) | round(1) | string` to safely snapshot setpoints.
- Deactivate uses `states(...) | float(X)` with per-room fallbacks (Office 20, LR 21, Kitchen 20) to restore.
- Pre-seeded helpers with current setpoints (19.0 / 21.0 / 20.0) so first real activation writes over real values.

### Lessons learned (captured in DECISIONS.md)
1. **Deploying packages with input helpers requires explicit reload service calls**: `ha core reload-all` (what `deploy.sh` runs) does **not** reload `input_number`, `input_text`, `input_boolean`, `input_datetime` domains. Call `input_text.reload` / `input_number.reload` / `automation.reload` via MCP after any package deploy that touches input helpers. For a **new** input domain that wasn't previously loaded, a fresh package deploy with `input_text.reload` works — provided the YAML is valid.
2. **YAML-defined `input_text` does NOT accept `unique_id`**: Only UI-created helpers (stored in `.storage/`) have unique_ids. Setting it in YAML rejects the whole block with "Invalid config". Code reviewer's suggestion was wrong in this case; caught in deploy via HA error logs.
3. **Pre-commit hook fixed**: Old regex-based check on `\s*- alias:` over-matched step-level aliases inside action blocks. Rewrote to use PyYAML → only top-level `automation:` entries are checked for `description:`. Hook lives at `.git/hooks/pre-commit` (local-only).

### Backups
- `76d0866b` (pre-Zocci+Beamer deploy, 17:55)
- `d145330e` (pre-Vacation Mode migration, 21:02)

### Entities affected
- **Deleted**: 3 UI automations (zocci_mark_clean_done, zocci_deep_clean_reminder, beamer_uplight_front) + 4 vacation mode UI automations.
- **Added (as package-managed)**: same 7 automations, identical IDs preserved → trace history retained.
- **New helpers**: `input_number.zocci_coffees_at_last_clean` (value: 61); `input_text.vacation_restore_office` (19.0), `_living_room` (21.0), `_kitchen` (20.0).
- **Health**: all clean. DB size unchanged at 785 MiB. Disk 12.2 GB / 28 GB.

---


## 2026-04-16 — Pomodoro Desk Timer: designed, Gate 2 APPROVED, parked in backlog

### What was done
- **Gate 1**: Clarified requirements (dashboard toggle, fixed 25 min, stay red until reset, leave lights as-is on start). Confirmed desk light entity: `light.desk_lights`.
- **Gate 2**: Wrote full solution (2 helpers: `timer.pomodoro_desk_timer`, `input_boolean.pomodoro_active`; 3 automations: Start / Break Time / Reset). Submitted to `ha-code-reviewer` → **APPROVED**, no blocking findings.
- **Parked**: Edgar requested backlog entry instead of deploy, with requirement to add a Bubble Card trigger button (Office popup) before deployment.

### What's pending
Full approved YAML embedded in BACKLOG.md (Pomodoro Desk Timer entry). Deploy when Bubble Card button is designed.

### Entities affected
None yet — no HA changes made this session.

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
