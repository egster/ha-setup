# WP2 — File Restructure + YAML-Mode Conversion

**Branch**: `phase7/wp2-restructure`
**Branches from**: `main` (after WP1 merged)
**Parallelizable with**: nothing (every other WP depends on this)
**Estimated effort**: full session

---

## Goal

Split the monolithic `config/dashboards/fusion.yaml` (1683 lines) into modular includes, and convert FUSION from storage-mode to YAML-mode dashboard registration. This is the enabler that makes parallel work on WP3/4/5 possible without merge conflicts.

**Critical constraint**: the dashboard must render **100% identically** before and after this WP. Visual regression tests from WP1 must show zero diff.

---

## Required reading (in order)

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md`
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md` — note the entry on FUSION as git source-of-truth
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/fusion-tests.md` — WP1's baseline
7. `00 - Agent Context/FUSION-DESIGN-SPEC.md`
8. `config/dashboards/fusion.yaml` — current monolith
9. `config/configuration.yaml` — current Lovelace registration
10. HA docs on YAML-mode dashboards (web search if unfamiliar)

---

## Inputs

- `config/dashboards/fusion.yaml` (1683 lines, current monolith).
- `config/configuration.yaml` (will be modified to register YAML-mode dashboard).
- WP1's baseline screenshots and test suite.

---

## Outputs (writable scope)

```
config/configuration.yaml                              # add lovelace.dashboards.fusion entry
config/dashboards/fusion.yaml                          # rewritten as entry-point with !include refs
config/dashboards/fusion/shell.yaml                    # NEW
config/dashboards/fusion/statusbar.yaml                # NEW
config/dashboards/fusion/templates.yaml                # NEW (button_card_templates)
config/dashboards/fusion/panels/home.yaml              # NEW
config/dashboards/fusion/panels/kitchen.yaml           # NEW
config/dashboards/fusion/panels/climate.yaml           # NEW
config/dashboards/fusion/panels/media.yaml             # NEW
config/dashboards/fusion/panels/network.yaml           # NEW
config/dashboards/fusion/panels/energy.yaml            # NEW
config/dashboards/fusion/panels/automations.yaml       # NEW
config/dashboards/fusion/popups/                       # NEW empty directory (placeholders for WP5)
00 - Agent Context/fusion-phase7/fusion-tests.md       # add tests for restructure
00 - Agent Context/fusion-phase7/STATUS.md             # update WP2 status
```

**Do not touch**: any storage-mode dashboard (`bubbledash`, etc.). Do not change content of any panel — only relocate it.

---

## Pre-work — confirm YAML-mode is the right path

Before any code: re-read `00 - Agent Context/fusion-phase7/COORDINATION.md` "Architecture decisions" section. Edgar has locked YAML-mode. **Do not relitigate.** If you discover a hard blocker (e.g. a HACS card requires storage-mode), stop and surface to Edgar.

Note: the existing storage-mode FUSION dashboard must be **removed** as part of this WP (otherwise both definitions will conflict). Procedure:

1. Use `ha_config_get_dashboard("fusion")` to fetch and back up the current storage-mode definition to `config/dashboards/fusion.storage-backup.json` (gitignored, local only — DO NOT commit).
2. After YAML-mode registration is verified working, use `ha_config_delete_dashboard("fusion")` to remove the storage-mode entry.

---

## TDD additions (write first)

Add these test cases to `fusion-tests.md`:

| ID | Type | Assertion |
|----|------|-----------|
| TEST-100 | YAML schema | `ha check_config` passes after YAML-mode registration |
| TEST-101 | DOM | At 1280px, dashboard renders identically to baseline screenshot (visual diff < 1%) |
| TEST-102 | DOM | At 900px, dashboard renders identically to baseline (visual diff < 1%) |
| TEST-103 | DOM | At 700px, dashboard renders identically to baseline (visual diff < 1%) |
| TEST-104 | Behavioural | Switching `input_select.fusion_panel` between all 7 values renders the right panel each time |
| TEST-105 | File system | All 12 new yaml files exist and are non-empty |
| TEST-106 | File system | `fusion.yaml` entry-point file is < 100 lines (just `!include` refs + top-level config) |
| TEST-107 | YAML schema | Every `!include` target file is valid YAML on its own |
| TEST-108 | Integration | Reloading the dashboard via `ha core reload-all` succeeds without errors |

Run the suite. New tests must fail (files don't exist yet). Existing baseline must pass.

---

## Implementation steps

### 1. Backup
- `ha_backup_create` — note backup ID.
- `git checkout -b phase7/wp2-restructure`.
- Copy current `fusion.yaml` to `fusion.yaml.bak` locally (gitignored).

### 2. Map sections of current fusion.yaml
Read `fusion.yaml` line by line. Note the boundaries:
- Header comments (lines 1-32)
- Top-level config (`title:`, line 33-...)
- `button_card_templates:` block (line ~34 onwards — find end)
- Helpers/anchors (between templates and views)
- `views:` (line 216) — single view containing the layout-card
- Within the view's cards: locate the 7 conditional cards (lines 596, 1151, 1195, 1278, 1332, 1517, 1647) — these are the 7 panels
- Within the view: locate the statusbar definition, sidebar definition, and main content layout

Document this mapping in `00 - Agent Context/fusion-phase7/wp2-section-map.md`.

### 3. Create the directory structure
```bash
mkdir -p "config/dashboards/fusion/panels"
mkdir -p "config/dashboards/fusion/popups"
```

### 4. Extract each module (one commit per extraction for easier review)

For each new file, the rule is: **content is moved verbatim, with no edits other than indentation adjustment for the new file scope.**

Order of extraction:
1. `templates.yaml` ← `button_card_templates` block
2. `statusbar.yaml` ← statusbar layout-card definition
3. `shell.yaml` ← outer layout-card + sidebar (will be reshaped by WP4 later, but at WP2 stage just relocate)
4. `panels/home.yaml` ← conditional card #1
5. `panels/kitchen.yaml` ← conditional card #2
6. `panels/climate.yaml` ← conditional card #3
7. `panels/media.yaml` ← conditional card #4
8. `panels/network.yaml` ← conditional card #5
9. `panels/energy.yaml` ← conditional card #6
10. `panels/automations.yaml` ← conditional card #7

Commit after each extraction with message `refactor(fusion): WP2 — extract <name> to includes`.

### 5. Rewrite fusion.yaml as entry point
The new `fusion.yaml` should be < 100 lines:

```yaml
# FUSION Dashboard — YAML-mode entry point
# Restructured by WP2 (Phase 7) — content split across config/dashboards/fusion/
# DO NOT EDIT VIA HA UI — git is source of truth
title: Fusion
button_card_templates: !include fusion/templates.yaml
kiosk_mode:
  # ... (keep existing kiosk_mode block here OR move to shell.yaml — pick one)
views:
  - title: Fusion
    path: fusion
    type: panel
    cards:
      - !include fusion/shell.yaml
```

Note: HA's `!include` directive has known quirks with deeply-nested merging. If `!include` of a card list (`!include_dir_list`) is needed instead of single-file `!include`, use that. Verify against HA's YAML mode docs.

### 6. Update configuration.yaml
Add (or modify the existing `lovelace:` block):

```yaml
lovelace:
  mode: storage  # other dashboards still storage
  dashboards:
    fusion:
      mode: yaml
      filename: dashboards/fusion.yaml
      title: Fusion
      icon: mdi:hexagon-multiple
      show_in_sidebar: true
      require_admin: false
```

### 7. Validate locally
```bash
./deploy.sh --check-only config/dashboards/fusion.yaml
```
(or whatever the existing pre-deploy check is — see `INSTRUCTIONS.md` Gate 3 step 5).

### 8. Deploy
- Backup is already done (step 1).
- `ha_check_config` — must pass.
- Edgar's approval gate (Step 9 in INSTRUCTIONS.md) — `configuration.yaml` changed, requires HA restart. STOP and ASK before restart.
- After Edgar approves: `ha_restart(confirm=True)`.
- Once HA is back up: `ha_config_delete_dashboard("fusion")` to remove the old storage-mode entry.
- Verify in HA UI that FUSION still appears in the sidebar and renders.

### 9. Run the test suite
- Execute `./scripts/run-fusion-tests.sh`.
- All baseline tests + the 9 new tests must pass.
- **The visual regression tests (TEST-101 to 103) are the critical gate.** A diff > 1% means the restructure broke the rendering.

### 10. Gate 2 review
Invoke `ha-code-reviewer` via `scripts/gate2-review.sh` against the rewritten `fusion.yaml` and one representative panel file. The reviewer should focus on:
- File structure clarity
- `!include` correctness
- No content drift (verbatim relocation)
- YAML-mode registration correctness

### 11. Update STATUS.md
Add: `- [x] WP2 — merged YYYY-MM-DD — commit <sha> — visual diff: 0%`.

### 12. Session-end (per INSTRUCTIONS.md)
- CHANGELOG entry.
- DECISIONS.md entry: "FUSION moved to YAML-mode dashboard registration; storage-mode entry removed; content split into modular includes."
- LAST_UPDATED.
- Final commit + push.

---

## Stop-and-ask triggers

- Visual diff > 1% after restructure → STOP. Something was reshaped, not relocated. Bisect.
- `!include` directive doesn't work as expected with HA's YAML-mode (e.g. nested merges fail) → STOP. Surface to Edgar; alternative is `!include_dir_list` or a build script.
- `ha_check_config` fails after YAML-mode registration → STOP. Roll back via `ha_backup_restore`.
- `configuration.yaml` already has a complex `lovelace:` block that conflicts → STOP. Don't improvise the merge.

---

## Acceptance criteria

- [ ] `fusion.yaml` reduced from 1683 lines to < 100 lines (entry point only).
- [ ] All 12 new include files exist and are valid YAML.
- [ ] `configuration.yaml` registers FUSION as YAML-mode dashboard.
- [ ] Old storage-mode `fusion` dashboard removed.
- [ ] Visual regression tests pass with diff < 1% at all 4 viewports.
- [ ] All baseline tests still pass.
- [ ] All 9 new WP2 tests pass.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] STATUS.md updated.
- [ ] CHANGELOG, DECISIONS, LAST_UPDATED updated.
- [ ] Branch merged to main.
