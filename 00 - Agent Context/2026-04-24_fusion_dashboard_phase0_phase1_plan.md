# FUSION Dashboard — Phase 0 + Phase 1 Implementation Plan
_Created: 2026-04-24 | For: `gate3-plan-critic` review → Edgar confirmation → execute_

## Source documents (authority)
- **Approach**: `00 - Agent Context/BACKLOG.md` → "FUSION Dashboard — Full Implementation"
- **Design spec**: `00 - Agent Context/FUSION-DESIGN-SPEC.md`
- **Session scope (this plan)**: Phase 0 (prereqs) + Phase 1 (dashboard shell). Phases 2–6 out of scope.

---

## 1. Pre-flight state (verified 2026-04-24 via MCP)

### HACS packages — available, none installed yet
| Card | HACS ID | Target version | Status |
|---|---|---|---|
| layout-card | `156434866` | v2.4.7 | install |
| apexcharts-card | `331701152` | v2.2.3 | install |
| config-template-card | `172177543` | 1.3.6 | install |

### Entity IDs — all Design Spec §13 unknowns for Phase 1 resolved
| Purpose | Entity ID | Current state |
|---|---|---|
| Presence | `person.edgar` | (known) |
| Device tracker — iPad | `device_tracker.ipad` | `home` |
| Device tracker — Edphone | `device_tracker.edphone` | `home` |
| WAN status | `binary_sensor.zenwifi_bq16_ca38_wan_status` | `on` |
| Download speed | `sensor.zenwifi_bq16_ca38_download_speed` | ~23.9 KiB/s |
| Upload speed | `sensor.zenwifi_bq16_ca38_upload_speed` | ~24.4 KiB/s |
| Uptime (seconds) | `sensor.zenwifi_bq16_ca38_uptime` | 1 224 468 |
| Outdoor temp fallback | `input_number.monitoring_outdoor_temperature` | 16.4 °C |

Primary outdoor sensor `sensor.air_conditioning_bedroom_outside_temperature` is `unavailable` (Panasonic setup_error) per PROFILE.md — use the poller-maintained `input_number` as the Phase 1 source.

### Helper + dashboard state
- No existing `input_select` helpers → clean create for `input_select.fusion_panel`
- 2 existing storage-mode dashboards (`dashboard-bubbledash`, `home-monitoring`) — both left untouched
- FUSION is a 3rd storage-mode dashboard at `url_path: fusion`

---

## 2. Execution sequence

### 2.1 Phase 0A — Backup & baseline
1. `ha_backup_create(name="pre_fusion_dashboard_2026-04-24")`
   - **Gate**: backup ID returned; no error. If timeout, poll `ha_get_operation_status` until done (per 2026-04-22 pattern).
2. Baseline capture (two calls in parallel):
   - `ha_config_list_dashboard_resources()` — capture current resource list for post-install diff.
   - `ha_get_system_health()` — capture critical-error count for S9 comparison.

### 2.2 Phase 0B — HACS installs (sequential, not parallel)
Installing in series so a failure on one doesn't mask the others.

3. `ha_hacs_download("156434866", version="v2.4.7")` — layout-card
4. `ha_hacs_download("331701152", version="v2.2.3")` — apexcharts-card
5. `ha_hacs_download("172177543", version="1.3.6")` — config-template-card
   - **Gate per install**: `success: true`; confirm via `ha_hacs_search(installed_only=True, category="lovelace")` that each now shows `installed: true` and `installed_version` matches target.
6. `ha_config_list_dashboard_resources()` — 3 new `/hacsfiles/...` entries present, type `module`.
   - If any missing: `ha_config_set_dashboard_resource(url="/hacsfiles/<card>/<file>.js", resource_type="module")` to register manually.

### 2.3 Phase 0C — Helper creation
7. `ha_config_set_helper(helper_type="input_select", name="Fusion Panel", helper_id="fusion_panel", options=["home","kitchen","climate","media","network","energy","automations"], initial="home", icon="mdi:view-dashboard-variant")`
   - **Gate**: `ha_eval_template("{{ states('input_select.fusion_panel') }}")` returns `home`.

### 2.4 Phase 0D — ⛔ Human checkpoint before Phase 1
8. Ask Edgar to hard-refresh browser (Cmd+Shift+R) and confirm under **Settings → Dashboards → Resources** that the 3 new entries load without 404. Browser cache is an out-of-band state I cannot verify remotely.
9. **Wait for Edgar's "proceed" before Phase 1B**.

### 2.5 Phase 1A — Gate 2 write & review (YAML draft)
10. Draft the shell YAML covering:
    - Outer view in `panel: true` mode (full-width; HA sidebar remains visible for now — Kiosk Mode toggle deferred to Phase 6 per design spec)
    - Top-level `custom:layout-card` with `layout_type: custom:grid-layout`, `grid-template-rows: 36px 1fr`, `grid-template-columns: 58px 1fr`
    - **Status bar** (`custom:button-card` horizontal stack, row 1 spanning both columns)
    - **Sidebar** (vertical stack of 7 `custom:button-card` nav icons + 1 spacer, col 1 row 2). Each icon uses `button-card` native `state:` with `operator: template` checking `states['input_select.fusion_panel'].state === '<panel>'` for active highlight — no card-mod needed for this.
    - **Content** (`custom:config-template-card` with 7 conditional `markdown` card stubs — "Panel: home", "Panel: kitchen", etc. Stubs only; real content is Phase 2+.)
11. Write the draft to **`config/dashboards/fusion.yaml`** (new directory, git-tracked for history; preferred over `reference/` because that dir contains the jlnbln experiment files flagged for cleanup — mixing FUSION source with deprecated experiments is sticky).
    - ❗ **Open question for Edgar** (decide at Gate 2 presentation, not default): confirm `config/dashboards/` as the FUSION home. Alternatives: `reference/` (mixed-purpose), `00 - Agent Context/` (wrong — that's for planning docs).
12. Invoke `ha-code-reviewer` with the YAML + this plan + the design spec.
    - **Flag explicitly in the reviewer prompt**: Phase 1 deviates from FUSION-DESIGN-SPEC §4 by using `button-card`'s native `state: [{operator: template, value: ...}]` block for the active-icon highlight, instead of `card-mod` as written in the spec. This is a deliberate simplification for Phase 1 — record it at session end as a decision.
    - Resolve every 🚫 finding before moving on.
13. Add `# Gate 2 reviewed: 2026-04-24` header line to the YAML (discipline; pre-commit hook only enforces it on `config/packages/*.yaml` but we mirror the convention).
13a. **⛔ Edgar confirmation gate before Phase 1B** — per INSTRUCTIONS.md Gate 2: present the YAML + reviewer summary to Edgar. Wait for his explicit go-ahead before step 14 writes to live HA. This is the first moment Edgar sees the actual dashboard content; the Phase 0D checkpoint (step 9) approved only the prerequisites.

### 2.6 Phase 1B — Dashboard create via MCP
14. `ha_config_set_dashboard(url_path="fusion", title="Fusion", icon="mdi:hexagon-multiple", show_in_sidebar=true, require_admin=false, config=<YAML from step 11>)`
    - **Gate**: `success: true`.
15. `ha_config_get_dashboard(url_path="fusion")` — round-trip check the config is stored intact (compare key paths like `views[0].cards[0].type == 'custom:layout-card'`).

### 2.7 Phase 1C — Visual + interactivity test
16. Edgar (or agent via Chrome MCP if reachable) opens the FUSION dashboard in a browser (local HA URL). Visual smoke test:
    - Status bar renders, shows live values (WAN `on`, DL/UL numbers, outdoor temp, both device trackers `home`)
    - Sidebar shows 7 icons with separator between Kitchen (2) and Climate (3)
    - Content area shows **"Panel: home"** markdown stub (default)
17. Click each of the 7 sidebar icons in sequence — verify via `ha_get_state('input_select.fusion_panel')` between clicks:
    - Click Kitchen icon → state = `kitchen`, content stub changes to "Panel: kitchen", active highlight moves to Kitchen
    - Repeat for all 7
18. Click one icon twice in a row → idempotent, no error, active highlight remains.
19. Reload page → last-selected panel persists (input_select retains state after UI reload).
20. Check browser devtools Console and Network tab — no 404s, no `ButtonCardJSTemplateError`, no `hui-sections-view` errors (the specific failure modes from the jlnbln retro, 2026-04-22).
    - ⚠️ S8 requires Edgar's physical presence OR Chrome MCP — there is no pure-MCP fallback for browser console inspection. If Chrome MCP is not connected, Edgar must close this gate himself.
20a. **Unintended state-change check** — `ha_get_logs(limit=100)` scoped to the click-test window (last ~5 minutes). Confirm only `input_select.fusion_panel` state changes are logged; no other entity flipped during the click test. (Standard Gate 3 Step 8 equivalent for this change shape.)

### 2.8 Phase 1D — Commit & close
21. `git add config/dashboards/fusion.yaml "00 - Agent Context/2026-04-24_fusion_dashboard_phase0_phase1_plan.md"`
22. `git commit -m "feat(dashboard): FUSION Phase 0 + Phase 1 shell — HACS cards, input_select helper, dashboard shell with status bar + sidebar + panel switcher"`
23. `git push`
24. Update `CHANGELOG.md`, `BACKLOG.md` (mark Phase 0 + Phase 1 as done, flag Phase 2 as next session), `LAST_UPDATED`.

---

## 3. Success criteria (binary — no ambiguity)

| # | Criterion | How verified |
|---|---|---|
| S1 | Backup created successfully | `ha_backup_create` returns a backup id; backup appears in backup list |
| S2 | All 3 HACS cards `installed: true` at target versions | `ha_hacs_search(installed_only=True, category="lovelace")` |
| S3 | All 3 HACS resources registered in Lovelace | `ha_config_list_dashboard_resources()` shows 3 new `/hacsfiles/` entries |
| S4 | `input_select.fusion_panel` exists, state `home`, has 7 options | `ha_eval_template` + `ha_get_state` |
| S5 | FUSION dashboard exists and is reachable | `ha_config_get_dashboard(list_only=true)` includes it; `/fusion` URL loads |
| S6 | All 7 sidebar icons switch the panel state | `ha_get_state` after each click returns expected option |
| S7 | Active icon highlights correctly in all 7 states | Visual confirmation (Edgar or Chrome MCP) |
| S8 | No browser console errors on `/fusion` | Edgar devtools check OR Chrome MCP `read_console_messages` |
| S9 | `ha_get_system_health` reports no new critical errors | Diff against the baseline captured in step 2 (not just "errors absent") |

Phase is NOT complete until all 9 criteria pass. Any ❌ → fix before closing.

---

## 4. Recorder impact assessment
- **New write sources**: `input_select.fusion_panel` only. One state change per user click on a sidebar icon.
- **Worst-case estimate**: active user, 50 clicks/day → ~50 recorder writes/day. Well under the DECISIONS 2026-04-22 writes/day threshold (which cleared a 5-writes/day automation with 9 helpers).
- **No new automations, counters, or self-triggering listeners.** No state-change subscriptions. No `event_type: state_changed` listeners on the helper.
- **Baseline DB**: 785 MB pre-change (per health check 2026-04-22). Post-change: no measurable delta expected.
- **Conclusion**: trivial recorder impact; consistent with the post-cascade decisions.

---

## 5. Risks & mitigations

| # | Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|---|
| R1 | HACS-installed cards don't auto-register as dashboard resources (rare but documented) | Low | Medium | Post-install check in step 6; manual `ha_config_set_dashboard_resource` register if missing |
| R2 | Browser cache serves old resource registry → dashboard shows "Custom element doesn't exist: custom:layout-card" | Medium | Low | Mandatory Edgar hard-refresh checkpoint at step 8 before Phase 1 |
| R3 | `custom:config-template-card` has known init timing issues where `states[...]` is `undefined` on first render | Low in Phase 1 (stubs) | Low | Not visible with minimal stubs. Re-assess in Phase 2 when content grows. If it bites: fall back to 7 parallel `conditional` cards, one per panel. |
| R4 | Panel mode conflicts with HA sidebar nav on mobile | Low | Low | Kiosk Mode already installed (v13.0.0) but **not enabled** in Phase 1. Phase 6 will handle. Keeps easy escape during shake-down. |
| R5 | Active-state template on button-card uses wrong Jinja dialect (not `{{ }}` — button-card uses `[[[ ]]]` JS templates) | Medium | Medium | Use button-card's JS template syntax; DECISIONS 2026-04-14 is about Jinja in automations, not button-card. Document in YAML comment. **The real proof point is Phase 1C step 17 (icon click test)** — the review at step 12 can't catch a wrong-syntax template because `ha-code-reviewer` isn't a JS interpreter. If Phase 1C is skipped or abbreviated, R5 silently persists into Phase 2 where debugging is far more expensive. **Don't skip Phase 1C.** |
| R6 | Git source diverges from live `.storage/lovelace.fusion` if Edgar edits via HA UI "Edit Dashboard" button | Medium (ongoing) | Low now, compounds over 6 phases | Gate-2 rule: YAML source is the git file; all edits go git → MCP `ha_config_set_dashboard(config=...)`. **Add a DECISIONS.md row at Phase 1 session-end**: "FUSION dashboard is git-source-of-truth; HA UI edits are prohibited for the duration of the 6-phase build." Convention alone — with nothing enforcing it — is insufficient over a multi-session lifecycle (cf. jlnbln retro 2026-04-22 on diverged-source cost). |
| R7 | `panel: true` interacts badly with card-mod at top level | Low | Low | Minimal card-mod usage in Phase 1 (only global scrollbar). Phase 6 handles heavy theming. |
| R8 | Chrome MCP (`mcp__Claude_in_Chrome__*`) not connected on Edgar's machine → agent can't do the visual check | Unknown | Low | Human verification is the designed fallback. Chrome MCP is a nice-to-have. |

---

## 6. Rollback plan

| Phase | Rollback action | Blast radius |
|---|---|---|
| 0A | No rollback needed (backup is additive) | None |
| 0B (HACS) — total failure | Uninstall via HACS UI, or `ha_call_service("hacs", "repository_remove", {...})`. Clear browser cache. | Only affects new FUSION work; other dashboards don't depend on these cards (BubbleDash uses none of the 3) |
| 0B (HACS) — **partial failure** (e.g. 2 of 3 installed) | **Leave the successful installs in place** (BubbleDash is unaffected). Log which card failed + its error. Surface to Edgar before proceeding or aborting. Do NOT uninstall the 2 successful ones unless Edgar says to. | None — extra cards resting idle have zero runtime cost; easier to resume on the next session than to re-install |
| 0C (helper) | `ha_config_remove_helper("input_select.fusion_panel")` | Only the helper; dashboard (if created) will show `unavailable` in the template |
| 1B (dashboard) | `ha_config_delete_dashboard(url_path="fusion")` | Only removes FUSION; BubbleDash and home-monitoring unaffected |
| Everything | Restore Phase 0A backup via `ha_backup_restore` | Full HA restart + state loss since backup; last-resort only |

Each rollback step is independent — failure at Phase 1B doesn't force uninstalling HACS cards.

---

## 7. Out of scope for this plan
- Phases 2–6 (hero strip, floor-grouped room grid, scenes row, room popups, Kitchen panel, polish & cutover) — per BACKLOG "one phase per session"
- Removing or archiving BubbleDash v4 (stays live in parallel for 1–2 weeks per BACKLOG Phase 6 cutover step)
- Kiosk Mode activation (Phase 6 polish)
- card-mod global theming beyond a minimal scrollbar/font reset (Phase 6)
- `timer.kitchen_1` / `timer.kitchen_2` helpers (Phase 5)
- Confirming entity IDs for Phases 2+ (energy sensors, scene entities, per-room motion sensors) — resolved one-phase-at-a-time

---

## 8. Deviations from standard INSTRUCTIONS.md Gate 3 pipeline

The standard pipeline assumes `config/packages/*.yaml` + `deploy.sh`. FUSION is a Lovelace dashboard, so:

| Standard step | FUSION substitution |
|---|---|
| Step 4: `git commit` of package file | `git commit` of `config/dashboards/fusion.yaml` (source of truth for history; new directory introduced in this plan) |
| Step 5: `./deploy.sh config/packages/<file>.yaml` | `ha_config_set_dashboard(url_path="fusion", config=...)` via MCP |
| Step 6: `ha_config_get_automation` | `ha_config_get_dashboard(url_path="fusion")` round-trip |
| Step 7: call the service the automation calls | Click each of 7 sidebar icons; verify `input_select.fusion_panel` advances |
| Step 8: `ha_get_automation_traces` | Browser devtools Console (no `ButtonCardJSTemplateError`) |
| Step 10: `ha_restart` | Not needed — no `configuration.yaml` change, no integration reload |

Pre-commit hook's `Gate 2 reviewed:` header check applies only to `config/packages/*.yaml` per the script; we still add the header to `config/dashboards/fusion.yaml` as discipline but the commit isn't blocked by its absence.

---

## 9. Open questions for Edgar at presentation time
1. **File location** for the YAML source: `config/dashboards/fusion.yaml` (plan's preference — clean new dir mirroring `config/packages/`) vs `reference/fusion-dashboard.yaml` (existing but mixed with jlnbln deprecated files). → plan defaults to `config/dashboards/`.
2. **Icon set for sidebar**: spec shows emoji (🏠, 🍳, 🌡, 🎵, 📡, ⚡, ⚙️). Button-card can render either emoji OR MDI icons. Emoji = closer to the mockup; MDI = more consistent with the rest of HA. → default MDI (`mdi:home-variant`, `mdi:silverware-fork-knife`, `mdi:thermometer`, `mdi:music`, `mdi:wifi`, `mdi:lightning-bolt`, `mdi:cog-outline`) unless Edgar prefers emoji for visual match to mockup.
3. **Kiosk Mode in Phase 1**: off (default). Confirm this is fine until Phase 6 cutover.
4. **DECISIONS.md row at session end** confirming "FUSION dashboard is git-source-of-truth; HA UI edits are prohibited for the duration of the 6-phase build" (per R6). Confirm Edgar's agreement so the rule has durable force.

---

## 10. Next session preview (Phase 2) — not this plan
Home panel: hero strip (6 tiles), floor-grouped room grid, scenes row. Blocked on Phase 1 success + an entity-ID resolution pass for the Home panel (motion sensors per room, energy sensors, scene entities). See FUSION-DESIGN-SPEC.md §5 and §13.
