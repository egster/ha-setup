# Instructions — Home Automation (Edgar)

## How to work here

### On every session start:
1. Read `INSTRUCTIONS.md` (this file) and `PROFILE.md` first
2. Check `CHANGELOG.md` to understand what was done last session
3. Read `DECISIONS.md` for load-bearing decisions that shape current choices
4. Use the Home Assistant MCP to get current state — don't rely on cached data from PROFILE.md for live entity states
5. Check `BACKLOG.md` for prioritised outstanding tasks
6. Identify your **environment mode** (see next section) — it determines which Gate 3 steps you can run.

### Environment modes

This repo is operated from two distinct agent environments. Know which you're in before you start, because Gate 3 scope differs.

- **Live session** — Claude Code running on Edgar's laptop with the HA MCP server connected and `ssh ha` reachable. This is the default mode and the only one that can execute the full Gate 3 pipeline (backup, entity validation, template evaluation, `deploy.sh`, trace inspection).

- **GitHub agent** — Claude invoked from a GitHub workflow (branches like `claude/*`). No HA MCP, no SSH to Green. Scope is limited to: writing/editing files, running the tracked pre-commit hook, committing, and pushing. Gate 3 Steps 1–8 **cannot be executed here** — they remain for Edgar to run live after merging the branch. In this mode, CHANGELOG/BACKLOG entries must say "package committed" or "PR open", never "deployed", until the live session catches up.

If you are unsure which mode you're in, check for HA MCP tools (`ha_get_state`, `ha_backup_create`, etc.) in your tool list. If they are absent, you are in GitHub-agent mode.

### File conventions:
- All planning/research docs: save to this folder as `.md` files
- **New automations, helpers, and scripts** are written as YAML files in `config/packages/` and deployed via `deploy.sh`. They are git-tracked.
- `config/automations.yaml` / `scripts.yaml` / `scenes.yaml` are legacy HA UI exports — kept as reference snapshots, not edited directly.
- Use descriptive filenames: `2026-04-10_motion_light_improvements.md`

---

## Agent Workflow (Every Request)

This workflow applies to **every request without exception**. Do not skip gates. Do not combine gates into a single message. Each gate requires Edgar's explicit confirmation before proceeding to the next.

---

### Gate 1 — Analyse, Clarify & Align

Before writing any code:
- Identify what is being asked and what assumptions are embedded in the request
- Fetch live HA state via MCP where relevant — never rely on cached PROFILE.md data
- Use `AskUserQuestion` to surface ambiguities. Do not proceed on assumptions.
- **Ambiguous verbs** — "finish", "wire up", "sort out", "clean up" — always trigger one round of `AskUserQuestion` before any work starts. Do not infer scope from environment constraints or prior context; ask. (Rule W2, 2026-04-19 meta session.)
- Challenge weak reasoning or architecturally questionable approaches upfront
- If a simpler approach exists, say so. Push back when warranted.

**For non-trivial requests** (new automations, helpers, structural changes): end Gate 1 with a one-paragraph approach alignment covering the key architectural choice. Do not write code yet. Wait for Edgar's implicit go-ahead before proceeding to Gate 2.

**Before drafting the alignment**, invoke the `research-advisor` subagent when the request touches an unfamiliar pattern, a new integration or HACS component, or a design with no precedent in `DECISIONS.md`. Pass it the original request and the contents of `PROFILE.md`, `DECISIONS.md`, and `INSTRUCTIONS.md`. The agent returns a brief with 2–3 alternatives, known anti-patterns, and a recommendation cross-referenced against Edgar's constraints — fold its findings into the alignment rather than pasting the brief verbatim. Skip for familiar patterns (motion lights, remote mappings, vacation-mode edits) where `DECISIONS.md` already settles the approach.

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

Invoke the `ha-code-reviewer` subagent. Use `scripts/gate2-review.sh <package-file> "<original request>"` to assemble the prompt — this bundles the original request, full file contents, and pointers to INSTRUCTIONS/DECISIONS/PROFILE automatically. Don't skip the reviewer because prompt assembly feels tedious.

Pass the reviewer:
1. The original request verbatim
2. The complete proposed solution (full YAML/config)
3. The full contents of INSTRUCTIONS.md and PROFILE.md

**A prior APPROVED verdict does NOT transfer across material rewrites.** If you have translated, reformatted, restructured, added IDs, converted keywords (e.g. `service:` → `action:`), or reshaped helper blocks since the previous review, run the reviewer again. Cosmetic/whitespace changes do not require re-review; anything that changes the code the deploy.sh pipeline will validate does. (Rule W1, 2026-04-19 meta session.)

If the reviewer returns **BLOCKED**: do not show the solution to Edgar. Fix every 🚫 finding in the code, then resubmit to the reviewer. Repeat until APPROVED.

If the reviewer returns **APPROVED**: present the solution to Edgar along with the reviewer's findings summary (including any ⚠️ concerns). Wait for Edgar's confirmation before Gate 3. Add a `# Gate 2 reviewed: YYYY-MM-DD` line to the package file's header comment block — the tracked pre-commit hook blocks commits on `config/packages/*.yaml` that lack this line.

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

**Step 4 — Write & commit**
Write the final YAML to `config/packages/<logical_group>.yaml` (e.g. `vacation_mode.yaml`, `motion_lights.yaml`).
Commit to git: `git commit -m "feat: <description>"`.
The pre-commit hook (tracked at `scripts/pre-commit`; install once with `ln -sf ../../scripts/pre-commit .git/hooks/pre-commit`) validates YAML syntax, enforces the `description:` field on every automation, and blocks any `config/packages/*.yaml` commit that lacks a `# Gate 2 reviewed: YYYY-MM-DD` header line — fix any failures before proceeding.

**Step 5 — Deploy**
Run `./deploy.sh config/packages/<file>.yaml`.
The script: validates locally → SCPs to `/config/packages/` on the board → runs `ha core check` → triggers reload.
If `ha core check` fails, the script rolls back (removes the file from the board) automatically.

**Step 6 — Verify**
`ha_config_get_automation` (or equivalent MCP read) to confirm the entity is live.
Alias, triggers, conditions, and actions must match what was written.

**Step 7 — Test action**
Call the service the automation/script would call, targeting the exact same entities.
Confirm they respond correctly. Confirm no unintended entities changed state.

**Step 8 — Check traces and logbook**
`ha_get_automation_traces` — confirm no errors on the new automation.
`ha_get_logs` — confirm only intended entities changed state during the Step 7 test.

**Step 9 — ⛔ HUMAN APPROVAL GATE**
If a full HA restart is required (e.g. `configuration.yaml` changed, or a new integration added):
**Stop. Wait for Edgar's explicit confirmation before restarting. Do not proceed.**

**Step 10 — Restart (if needed)**
After Edgar confirms: `ha_check_config` to validate, then `ha_restart(confirm=True)`.
Most package file changes only require `ha core reload-all` (already handled by `deploy.sh`) — restart is not needed.

**Step 11 — Post-deploy verification**
Search for the changed entity to confirm it is present and enabled.
`ha_get_system_health` spot-check — no critical errors.

**Rollback at any point:**
- If Step 5 deploy fails: the script auto-rolls back. No further action needed.
- If Step 6–8 reveals a problem: `ssh ha "rm /config/packages/<file>.yaml"` + `ha core reload-all`, then `git revert`.
- If uncertain about system state after Step 10: restore from Step 1 backup via `ha_backup_restore`.

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
- **Floors** (4) are live as of 2026-04-21: Downstairs (0), Main (1), Upper (2), Outside (−1). All 11 areas are assigned. See PROFILE.md Structure section for the mapping.

---

## Out of scope

_To be defined. Ask Edgar if unclear. Candidate items that may belong here: HA Cloud remote access setup, non-HA smart home systems, anything requiring physical device install._

---

## Session end

At the end of every session where files are created, modified, or deleted — or HA configurations are changed:

1. **Update `CHANGELOG.md`** — log: date, what was done, which entities/automations were affected, and any open questions.
2. **Update `DECISIONS.md`** — if a decision was made that changes how future work will be done (tool choice, architectural pattern, workaround rationale), add a row.
3. **Update `LAST_UPDATED`** — overwrite with today's date (`YYYY-MM-DD`).

**Context files reflect completed state only.** CHANGELOG entries say "package committed, deploy pending" if Gate 3 hasn't run; they say "deployed" only after Gate 3 Steps 6–8 pass. BACKLOG statuses follow the same discipline. Do not write a session-end entry that implies work is further along than it actually is. (Rule W3, 2026-04-19 meta session.)

**Commit cadence on feature branches.** When work is iterative cosmetic tuning on a feature branch that will be squash-merged (e.g. the FUSION 6j–6n polish passes), prefer one end-of-session commit over per-tweak commits. Reserve per-phase commits for milestones that could genuinely be reverted in isolation. (Rule R3, 2026-04-24 FUSION retro.)

---

## Privacy & Public Repo Safety

This repo is **public on GitHub**. Every tracked file is world-readable.

### What must NEVER be committed (enforced by .gitignore)
- `PROFILE.md` — contains address, household names, network details, device inventory
- `.backup/` — contains historical copies of PROFILE.md and other context files
- `healthcheck*.json` / `healthcheck*.md` — contains entity inventory and system internals
- `secrets.yaml` / `.env` / `*.token` — credentials and API keys

### PII rules for tracked files
- **No home address, GPS coordinates, or postal codes** in any tracked file
- **No children's full names** — use nicknames (e.g. "Jona") or roles ("second child") only
- **No WiFi SSIDs, internal IPs, MAC addresses, or router models**
- **No credentials** — use `!secret` references in YAML; store values in `secrets.yaml`
- First names of the primary user (Edgar) are acceptable since the GitHub account is public

### Session-start privacy check
On every session start, after reading context files, do a quick scan:
1. Run `git diff --cached --name-only` and `git status` to see what's staged or modified
2. If any staged/modified file contains patterns matching: street addresses, full children's names (Jonathan, Lennard), SSIDs, internal IPs, passwords, or API keys — **warn Edgar before committing**
3. If a new file is being added to tracking, verify it doesn't belong in `.gitignore`

### Pre-commit responsibility
Before every `git commit`, scan the diff for the PII patterns above. If found, **block the commit and alert Edgar** with the specific file and line.
4. **Git commit** — commit all modified `00 - Agent Context/` files with message `docs: session end YYYY-MM-DD — <one-line summary>`.
5. **Git push** — `git push` to sync the commit to GitHub (`origin/main`).

This is the agent's responsibility, not Edgar's.
