# Instructions — Home Automation (Edgar)

## How to work here

### On every session start:
1. Read `INSTRUCTIONS.md` (this file) and `PROFILE.md` first
2. Check `CHANGELOG.md` to understand what was done last session
3. Read `DECISIONS.md` for load-bearing decisions that shape current choices
4. Use the Home Assistant MCP to get current state — don't rely on cached data from PROFILE.md for live entity states
5. Check `BACKLOG.md` for prioritised outstanding tasks

### File conventions:
- All planning/research docs: save to this folder as `.md` files
- Automation configs are managed live via the HA MCP (not stored as YAML files here)
- Use descriptive filenames: `2026-04-10_motion_light_improvements.md`

## What this folder is for
This is the working folder for managing, planning, and improving the Home Assistant setup. The primary outputs are:
- Automation configs (created/edited directly via HA MCP)
- Documentation of decisions, structure, and open issues
- Planning notes for new automations, dashboards, and integrations

## Who is this for and what kind of HA setup do we have?
Read PROFILE.md.

---

## Agent Workflow (Every Request)

This workflow applies to **every request without exception**. Do not skip gates. Do not combine gates into a single message. Each gate requires Edgar's explicit confirmation before proceeding to the next.

---

### Gate 1 — Analyse, Clarify & Align

Before writing any code:
- Identify what is being asked and what assumptions are embedded in the request
- Fetch live HA state via MCP where relevant — never rely on cached PROFILE.md data
- Use `AskUserQuestion` to surface ambiguities. Do not proceed on assumptions.
- Challenge weak reasoning or architecturally questionable approaches upfront
- If a simpler approach exists, say so. Push back when warranted.

**For non-trivial requests** (new automations, helpers, structural changes): end Gate 1 with a one-paragraph approach alignment covering the key architectural choice. Do not write code yet. Wait for Edgar's implicit go-ahead before proceeding to Gate 2.

**For simple/clear requests** (single value edits, well-defined one-liners): skip approach alignment and proceed directly to Gate 2.

---

### Gate 2 — Write & Review

Write the complete, ready-to-deploy solution. Then submit it for code review before showing anything to Edgar.

**Writing the solution:**
- Write full YAML/config, not prose descriptions of it
- Include a `description:` field on every automation explaining intent — not just what it does, but why
- Prefer blueprints for repeatable patterns (motion lights, remote mappings); custom YAML for one-offs with complex logic
- No features beyond what was asked
- Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify

**Code review:**

Invoke the `ha-code-reviewer` subagent. Pass it:
1. The original request verbatim
2. The complete proposed solution (full YAML/config)
3. The full contents of INSTRUCTIONS.md and PROFILE.md

If the reviewer returns **BLOCKED**: do not show the solution to Edgar. Fix every 🚫 finding in the code, then resubmit to the reviewer. Repeat until APPROVED.

If the reviewer returns **APPROVED**: present the solution to Edgar along with the reviewer's findings summary (including any ⚠️ concerns). Wait for Edgar's confirmation before Gate 3.

---

### Gate 3 — Deploy (Standard Pipeline)

Only after Edgar confirms Gate 2. Execute the pipeline below in fixed order. Do not skip steps, reorder them, or invent a new plan — this is the standard procedure.

#### Trivial changes
*(Single value edits, description typos, one-line YAML tweaks — no structural change)*

1. Apply the change via the appropriate MCP tool
2. Re-read the config to confirm the change was saved correctly
3. State why backup and restart are not needed (e.g. "covered by recent backup X, single value edit")
4. Ask Edgar to confirm before applying if there is any doubt

#### Non-trivial changes
*(All HA configuration changes not covered above — new automations, helpers, dashboards, areas)*

**Step 1 — Backup**
`ha_backup_create`. Confirm backup ID is returned before proceeding. If status is ambiguous, wait or retry.

**Step 2 — Validate entity IDs**
`ha_get_state` for every entity ID referenced in the solution.
- All must return state `on`, `off`, or a valid value
- Halt if any returns `unknown`, `unavailable`, or errors — fix entity ID before continuing

**Step 3 — Validate templates**
`ha_eval_template` for any condition or trigger templates in the solution.
- Must return `true` or `false` without error
- A `false` result is not a failure — it confirms syntax is valid and condition is evaluating correctly
- Halt on any error — fix the template before continuing

**Step 4 — Apply**
`ha_config_set_automation` / `ha_config_set_helper` / appropriate MCP tool.

**Step 5 — Verify**
Re-read the config with `ha_config_get_automation` (or equivalent).
Confirm alias, triggers, conditions, and actions exactly match what was written.

**Step 6 — Test action**
Call the service the automation/script would call, targeting the exact same entities.
Confirm they respond correctly. Confirm no unintended entities changed state.

**Step 7 — Check traces and logbook**
`ha_get_automation_traces` — confirm no errors on the new automation.
`ha_get_logbook` — confirm only intended entities changed state during the Step 6 test.

**Step 8 — ⛔ HUMAN APPROVAL GATE**
HA config was modified. `ha_restart` is required.
**Stop. Wait for Edgar's explicit confirmation before restarting. Do not proceed.**

**Step 9 — Restart**
After Edgar confirms: `ha_check_config` to validate, then `ha_restart(confirm=True)`.

**Step 10 — Post-restart verification**
Search for the changed entity to confirm it is present and enabled.
`ha_get_system_health` spot-check — no critical errors.

**Rollback at any point:**
If any step fails after Step 4 (apply): `ha_config_remove_automation` (or equivalent) to undo.
If uncertain about system state after Step 9: restore from Step 1 backup via `ha_backup_restore`.

---

### Post-implementation

After Gate 3 completes, update the session end files (see "Session end" section below).

For 3+ automations or helpers changed in a single session: run the `ha-health-check` skill as a final step.
For 1–2 changes: `ha_get_system_health` spot-check is sufficient.

---

## Architectural constraints

These exist because past mistakes taught us the hard way. Don't bypass them.

### Recorder awareness
- The HA Green board runs SQLite on a 28 GB eMMC. Every entity state change is written to the recorder DB. Before creating helpers (counters, input_numbers, input_booleans), ask: **does this need to be in the recorder?** If it's only for dashboards, consider whether InfluxDB already captures it.
- **Never create more than 5 new helpers in a single session** without explicitly discussing recorder impact with Edgar.
- If a helper exists only for display/monitoring (not used in automations or conditions), it probably shouldn't exist — InfluxDB + Grafana is the right tool for historical data on this system.

### Self-triggering prevention
- **Any automation that listens to `event_type: automation_triggered` or `event_type: state_changed` on its own outputs will self-trigger.** Always check: "If this automation fires, will its own state change or event re-trigger it?" If yes, redesign.
- Avoid `mode: parallel` with high `max:` values unless you've confirmed the automation can't cascade. Default to `mode: single` or `mode: restart`.

### InfluxDB is already there
- The InfluxDB add-on captures all HA state changes. Before building any monitoring/tracking system inside HA, check whether the data already exists in InfluxDB. If it does, build the dashboard in Grafana instead of duplicating data into HA helpers.

---

## Key conventions in this HA setup
- **Motion lights** use the `Blackshome/sensor-light.yaml` blueprint — always use this for new motion light automations. Lights that can be switched off at the wall require the blueprint's `dynamic_lighting_boolean` toggle helper (see DECISIONS 2026-04-11).
- **IKEA remote mappings** (Living Room, Bedroom, Jona) use the `niro1987/zha_ikea_tradfri_5button_remote_custom.yaml` blueprint. **Kitchen Remote** is a Philips Hue RWL022 and uses `dustins/zha-philips-hue-v2-smart-dimmer-switch-and-remote-rwl022.yaml`
- **Area naming** is clean and consistent — follow the same convention when adding new areas
- No floors are defined yet — this is an open improvement item

---

## Out of scope

_To be defined. Ask Edgar if unclear. Candidate items that may belong here: HA Cloud remote access setup, non-HA smart home systems, anything requiring physical device install._

---

## Session end

At the end of every session where files are created, modified, or deleted — or HA configurations are changed:

1. **Update `CHANGELOG.md`** — log: date, what was done, which entities/automations were affected, and any open questions.
2. **Update `DECISIONS.md`** — if a decision was made that changes how future work will be done (tool choice, architectural pattern, workaround rationale), add a row.
3. **Update `LAST_UPDATED`** — overwrite with today's date (`YYYY-MM-DD`).

This is the agent's responsibility, not Edgar's.
