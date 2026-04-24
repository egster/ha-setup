# Session Retro — Weather-Aware Heating deploy
# 2026-04-22

Scope of retro: the agent performance and harness behaviour during the Weather-Aware Heating session (Gate 1 research × 2, Gate 2 review × 2, backtest, Gate 3 deploy). Goal: surface rules, bugs, and priority bumps.

---

## What worked well

- **Gate discipline held under auto mode.** The harness / system prompt said "execute autonomously," but the explicit Edgar-confirmation step before Gate 3 was respected. Correct behaviour — auto mode is not a licence to bypass documented gates.
- **Rule W1 (material rewrite → re-review) fired correctly.** Adding a `notify.*` action after the first APPROVED verdict triggered a second `ha-code-reviewer` pass. Second pass was tightly scoped ("only validate the notify addition"), came back APPROVED quickly. Exactly how the rule was designed to work.
- **Research-advisor round 2 delivered concrete numbers.** The brief produced the 3 °C noise floor and tier curve (0 / ±0.5 / ±1.5) with sourced rationale (Tado/Nest weather-compensation, Swiss thermal-mass ratio, Wiser 0.5 °C step). Honestly tagged ⚠️ on unvetted sources. These were the specific inputs Edgar asked for.
- **ha-code-reviewer** found the `{{ 0.0 }}` symmetry nit and correctly carried forward the Gate 2 approach-critic's ⚠️ findings without blocking. Cheap, useful.
- **Pre-commit hook blocked the commit** because the Gate 2 header was on line 74 (scanner limit: 40). Caught a real defect before push. Hook is earning its place.
- **Test-triggering the automation pre-clock** — calling `automation.trigger` manually at deploy time (rather than waiting until 22:00) validated the full action chain end-to-end, including the notification. Saves hours of "was it the forecast or was it the code?" debugging if tomorrow's 22:00 fires wrong.

---

## What didn't work — rules proposed

### R1 🆕 — Research-advisor is read-only. Use `general-purpose` for computational tasks that produce artifacts.

**Observation**: the backtest was dispatched to `research-advisor`, but that agent only has `Read` + `WebFetch`. It did the computation correctly but then had to return the full 30-day table as raw markdown text for the main agent to save. Fragile (risk of context overflow), wastes tokens, forces context to carry output that should have been a file handoff.

**Proposed rule**: Research-advisor's job is advising from Read + WebFetch (docs, community threads, GitHub issues). For any task that produces a deliverable file (backtest, audit report, data synthesis), use `general-purpose` which has Write.

**Where to encode**: INSTRUCTIONS.md §"Agent Workflow" — add a one-liner under Gate 1's research-advisor paragraph: "For computational artifacts (backtests, simulations, audits that produce saved reports), dispatch `general-purpose` instead — research-advisor is Read/WebFetch only."

---

### R2 🆕 — Re-confirm scope before dispatching research-advisor on a backlog item.

**Observation**: Round 1 of research-advisor built on the stale BACKLOG entry ("motion sensors + 4 Panasonic ACs") that Edgar had already implicitly revised. We spent one full research cycle before Edgar corrected scope. This was a natural human communication flow, but there's a cheap tool that could have surfaced it earlier.

**Proposed rule**: When a BACKLOG entry is older than ~7 days, the main agent should paraphrase the current scope back to Edgar in one sentence before dispatching Gate 1 research. Not a new gate — a single question inline with "here's how I read it, is this still the scope?"

**Where to encode**: INSTRUCTIONS.md §Gate 1 — add sentence: "If the BACKLOG entry is older than ~7 days or uses verbs that could be reinterpreted ('room heating' could be occupancy-aware, forecast-aware, or both), paraphrase the scope in one sentence and confirm before dispatching research-advisor."

---

### R3 🆕 — Package header template: Gate 2 line in the first 10 lines.

**Observation**: Pre-commit hook scans the first 40 lines for the `# Gate 2 reviewed: YYYY-MM-DD` line. Package headers are long (the Weather-Aware package has a 74-line header block) and the Gate 2 line fell outside the scan. Had to move it up. Minor friction, easily preventable.

**Proposed convention**: The Gate 2 line belongs on the line immediately under the package title's divider — i.e. within the first ~10 lines, always. Update the (implicit) header style guide.

**Where to encode**: INSTRUCTIONS.md §Gate 2 final paragraph, extend existing reference to the hook:

> "Add a `# Gate 2 reviewed: YYYY-MM-DD` line to the package file's header comment block — **place it in the first 10 lines**, under the title divider. The pre-commit hook scans the first 40 lines."

Alternatively: lift the hook's `HEADER_SCAN_LINES` constant from 40 to 80. Cheaper than teaching a style rule. Low risk — the hook's purpose is catching "reviewer forgot to add the line at all," not enforcing placement.

**Recommendation**: bump the hook constant to 80. Style rules are friction; a config constant is a one-line fix.

---

### R4 🆕 — `ha_backup_create` MCP timeouts often mask success. Verify via SSH before retrying.

**Observation**: First `ha_backup_create` call timed out. I (main agent) retried. The second call also timed out. Both calls actually succeeded — now there are two identical 280 MB backups on the HA Green board, each wasting eMMC space.

**Proposed rule**: When `ha_backup_create` returns a timeout, before retrying, check `ssh ha "ls -lt /root/backup/ | head -3"` to see whether the backup landed. If it did, proceed. Don't blindly retry.

**Where to encode**: INSTRUCTIONS.md §Gate 3 Step 1 — add the verify-before-retry line. Keep it short.

**Bonus cleanup**: delete the duplicate backup on HA Green from today's session (both are identical; one is enough).

---

### R5 🆕 — `gate2-approach-critic` should commit to its verdict.

**Observation**: The Gate 2 approach-critic's written output began with "Verdict: BLOCKED", then self-revised in-text to "APPROVED (with warnings)" after working through the InfluxDB-duplication finding. The final output is correct but the audit trail is messy — a reviewer that publicly changes its mind mid-output is harder to trust on its next verdict.

**Proposed rule**: The critic agents (`gate2-approach-critic`, `gate3-plan-critic`) should reason internally and then return exactly one verdict. If a finding turns out to be a ⚠️ not a 🚫 on deeper analysis, that's a ⚠️ — don't publish the 🚫 first. Update the agent definition's system prompt to require a single committed verdict.

**Where to encode**: `~/.claude/agents/gate2-approach-critic.md` (and `gate3-plan-critic.md`) — add instruction: "Reason through findings internally. Your output must have a single committed verdict. Do not publish an initial verdict and then revise it — if you revise on reflection, publish only the revised verdict."

---

## Priority bumps to BACKLOG

- **`deploy.sh` input-helper-reload fix** — 🟡 → 🔴. Hit the same friction a 3rd time (2026-04-16, 2026-04-16 Vacation Mode, 2026-04-22 Weather-Aware Heating). Each time costs ~60 seconds of manual reload calls and interrupts Gate 3 flow. Fix is ~20 minutes.

---

## Context doc drift / gaps caught

- **PROFILE.md Climate section was wrong** — claimed 4 Panasonic entities; actually 3 Wiser + 1 Panasonic. Corrected in this session. Root cause: likely written before Wiser HACS integration was installed, never updated. Suggests a quarterly `MODE: setup-review` pass (already on BACKLOG) should include a PROFILE-vs-reality cross-check.

---

## What Edgar should decide before closing this retro

1. **R1 (research-advisor = read-only)** — accept as a rule? Small addition to INSTRUCTIONS.md §Gate 1.
2. **R2 (re-confirm stale scope)** — accept as a rule? One sentence, same location.
3. **R3 (Gate 2 header placement)** — prefer the style rule or the hook constant bump? Recommend the constant bump (lower friction).
4. **R4 (backup timeout verify-before-retry)** — accept?
5. **R5 (critic commits to verdict)** — accept? Requires editing two agent definition files.
6. **Priority bump for `deploy.sh` reload fix** — promote to 🔴 High? Effort is small; friction is recurring.
7. **Delete duplicate backup on HA Green** — safe cleanup?

If Edgar accepts R1–R5, the main agent applies them in a follow-up commit (INSTRUCTIONS.md + one-line hook constant + two agent definitions) — no HA system changes, pure docs + config.
