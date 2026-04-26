# WP1 — Test Harness + Visual Baseline

**Branch**: `phase7/wp1-test-harness`
**Branches from**: `main`
**Parallelizable with**: nothing (foundational)
**Estimated effort**: half a session

---

## Goal

Establish a Test-Driven Design harness for the FUSION dashboard so every subsequent WP can write tests first, run them, and verify nothing else broke. Capture the current dashboard state as the baseline.

---

## Required reading (in order)

1. `00 - Agent Context/INSTRUCTIONS.md` — gate workflow + environment modes
2. `00 - Agent Context/PROFILE.md` — entity inventory
3. `00 - Agent Context/CHANGELOG.md` — what was done last
4. `00 - Agent Context/DECISIONS.md` — load-bearing decisions
5. `00 - Agent Context/fusion-phase7/COORDINATION.md` — this phase's master brief
6. `00 - Agent Context/FUSION-DESIGN-SPEC.md` — the design spec
7. `00 - Agent Context/retro_2026-04-24_fusion_dashboard.md` — recent retro
8. `config/dashboards/fusion.yaml` — current implementation (1683 lines)

---

## Inputs

- Live FUSION dashboard at `http://192.168.50.11:8123/dashboard-fusion`.
- Chrome MCP access (you may need to ask Edgar to grant permission once).
- HA MCP access for `ha_check_config`, `ha_get_state`, `ha_eval_template`.

---

## Outputs (writable scope)

- `00 - Agent Context/fusion-phase7/fusion-tests.md` — the assertion library.
- `scripts/run-fusion-tests.sh` — the test runner.
- `00 - Agent Context/fusion-phase7/screenshots/baseline/` — baseline screenshots at 375 / 700 / 900 / 1280 px.
- `00 - Agent Context/fusion-phase7/baseline-measurements.md` — empirical measurements.

**Do not touch**: `config/dashboards/fusion.yaml` or anything under `config/`. WP1 is read-only against the dashboard.

---

## Tests to write (this WP defines the format every other WP follows)

The `fusion-tests.md` file is structured as YAML-front-matter test entries. Each test:

```markdown
## TEST-001: hui-view-container padding-left at desktop width
- viewport: 1280x800
- type: dom_assertion
- url: http://192.168.50.11:8123/dashboard-fusion
- assertion: |
    document.querySelector('hui-view-container').computedStyleMap().get('padding-left').value
- expected: 100
- tolerance: 0
- owner_wp: WP1
- status: baseline
```

Categories of test (define at least 2 of each in the baseline):

| ID range | Type | Tool |
|----------|------|------|
| TEST-001 to 020 | DOM assertion (computed styles, element presence) | Chrome MCP `javascript_tool` |
| TEST-021 to 030 | Visual regression (screenshot diff) | Chrome MCP `screenshot` |
| TEST-031 to 040 | Behavioural (click + assert state change) | Chrome MCP click + assert |
| TEST-041 to 050 | YAML schema | `ha_check_config` |
| TEST-051 to 060 | Entity existence | `ha_get_state` |
| TEST-061 to 070 | Template eval | `ha_eval_template` |

**Baseline assertions to capture (minimum 25)**:

1. `hui-view-container` `padding-left` at 1280, 900, 700, 375 px (4 tests — confirms phone breakage root cause).
2. Outer layout-card grid-template-columns at desktop renders `72px 1fr`.
3. Sidebar (column 1) `padding-top` is `130px`.
4. Status bar grid has 8 cells visible at desktop.
5. Each of 7 nav icons (home, kitchen, climate, media, network, energy, automations) is present and tap-targetable.
6. Active panel (`input_select.fusion_panel = home`) renders the home panel; switching the input_select swaps panels.
7. Floor headers render with text "MAIN FLOOR", "UPPER FLOOR", "DOWNSTAIRS", "OUTSIDE" on home panel.
8. Room cards on MAIN FLOOR render in a 3-column grid at desktop.
9. Each scene button in the hero strip is clickable.
10. KPI tile "Rooms Occupied" displays a numeric value.
11. KPI tile "Lights On" displays a numeric value.
12. Visual regression: full dashboard screenshot at 1280 (baseline).
13. Visual regression: full dashboard screenshot at 900 (baseline).
14. Visual regression: full dashboard screenshot at 700 (baseline — likely shows breakage onset).
15. Visual regression: full dashboard screenshot at 375 (baseline — confirms current broken state).
16. Behavioural: click `kitchen` nav icon → `input_select.fusion_panel` becomes `kitchen`.
17. Behavioural: click `home` nav icon → returns to home.
18. YAML schema: `ha_check_config` reports no errors with current dashboard.
19. Entity existence: every entity referenced by name in the dashboard yaml exists. (Run a grep over `entity:` keys, then `ha_get_state` each one.)
20. Template eval: any Jinja `{{ }}` in the dashboard evaluates without error.

Plus 5 more of your choosing — bias toward catching things the retro flagged (status-bar collapse, row right-edge overflow, sidebar alignment).

---

## Test runner

`scripts/run-fusion-tests.sh` should:

1. Parse `fusion-tests.md` — extract each test block.
2. For each test, dispatch to the right backend:
   - DOM assertion → call Chrome MCP via a small helper (could be a python wrapper that invokes claude-code with the right MCP, OR a shell script that uses curl against the Chrome extension's bridge if available).
   - YAML / entity / template → use `ha-cli` or an HA MCP wrapper.
3. Collect pass/fail. Report:
   ```
   FUSION test suite — 27 tests
   ✅ TEST-001 hui-view-container padding-left at 1280 (got 100, expected 100)
   ❌ TEST-004 hui-view-container padding-left at 375 (got 0, expected 100) — CONFIRMED BUG
   ...
   Result: 25 passed, 2 failed (2 known baseline failures)
   ```
4. Exit code 0 if all pass, 1 if any fail (with a `--allow-baseline-failures` flag for WP1's broken-state baseline).

**Important**: WP1's baseline includes 2 known-failing tests (the phone breakage). They're expected to fail. Mark them with `status: baseline_known_failure` so the runner doesn't treat them as regressions.

---

## Implementation steps

1. Read all required reading.
2. Create `00 - Agent Context/fusion-phase7/screenshots/baseline/` directory.
3. Take baseline screenshots via Chrome MCP at 375, 700, 900, 1280 px. Save as `baseline_<width>px.png`.
4. Measure `hui-view-container` `padding-left` at each viewport via Chrome MCP `javascript_tool`. Record in `baseline-measurements.md`.
5. Build `fusion-tests.md` with the 25+ baseline assertions.
6. Build `scripts/run-fusion-tests.sh` with the dispatch logic.
7. Run the suite. Confirm baseline failures match the documented breakage. Document any unexpected failures.
8. Gate 2: invoke `ha-code-reviewer` against `fusion-tests.md` and the runner script. (For non-YAML deliverables like this, the reviewer should focus on test rigour and reproducibility.)
9. Commit and merge to `main`. Post status entry to `STATUS.md`.

---

## Stop-and-ask triggers

- Chrome MCP access denied or extension unavailable → ask Edgar to fix the extension before proceeding.
- A baseline measurement contradicts the documented breakage (e.g. `padding-left` is 100 at 375px) → STOP. The diagnosis is wrong, the whole phase needs reconsideration.
- More than 5 baseline tests fail unexpectedly → STOP. Something else is broken in the current dashboard.

---

## Acceptance criteria

- [ ] `fusion-tests.md` contains ≥25 baseline assertions covering all 6 test categories.
- [ ] `run-fusion-tests.sh` executes the suite and reports pass/fail with exit code.
- [ ] Baseline screenshots captured at 4 viewports.
- [ ] `baseline-measurements.md` documents `hui-view-container` `padding-left` at all 4 viewports.
- [ ] Phone breakage (TEST-004) is the only "expected failure" in the baseline.
- [ ] Reviewer APPROVED.
- [ ] Branch merged to main, STATUS.md updated.
