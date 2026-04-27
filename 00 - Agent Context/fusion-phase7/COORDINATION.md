# FUSION Phase 7 — Coordination Brief

**Read this first. Every parallel session reads this before reading its work-package brief.**

---

## What we're building

A holistic responsive overhaul of the FUSION dashboard:

1. Bottom-tab nav on phone, sidebar on desktop/iPad (state-switch hybrid).
2. Bubble Card popups for Living Room, Kitchen, Office, Outdoor.
3. Responsive grid system across all panels (`auto-fit, minmax`).
4. Bottom nav auto-hides when popup is open.
5. Cosmetic gap fixes (sidebar separator, pulsing presence dot).

The current FUSION dashboard works on browser and iPad but breaks on phone (~375px). Root cause: the outer layout-card uses `margin: 0 16px 0 -84px` to compensate for HA's `hui-view-container` 100px `padding-left`, but that padding collapses to 0 below HA's `narrow` breakpoint (~870px), pushing the dashboard's left edge 84px off-screen on phone.

---

## Architecture decisions (locked, do not re-litigate)

- **Hybrid shell**: sidebar on desktop/iPad (≥871px), bottom tab bar on phone (<871px), via `state-switch` keyed to `entity: mediaquery`.
- **YAML-mode dashboard registration**: FUSION leaves storage-mode permanently as part of WP2. Registered via `configuration.yaml` referencing `config/dashboards/fusion.yaml` as entry point with `!include` directives.
- **Bubble Card popups** triggered by URL hash (`#popup-living-room` etc.). Slide-up bottom-sheet pattern works uniformly across viewports.
- **Bottom nav hides on popup** via `card-mod` rule hooking Bubble Card's body-level `bubble-popup-open` class.
- **Test-Driven Design**: every WP writes its tests first (failing) → writes YAML → tests pass → Gate 2 review.
- **One PR per WP**, each on its own branch. Branches merge sequentially per the dependency order.

---

## File restructure (delivered by WP2 — every other WP depends on this)

```
config/dashboards/
├── fusion.yaml                          # entry point, !include refs only
└── fusion/
    ├── shell.yaml                       # state-switch wrapper, sidebar, bottom-tab
    ├── statusbar.yaml                   # statusbar definition (desktop + phone variants)
    ├── templates.yaml                   # button_card_templates (fusion_nav_icon, fusion_floor_header, room_row, etc.)
    ├── panels/
    │   ├── home.yaml
    │   ├── kitchen.yaml
    │   ├── climate.yaml
    │   ├── media.yaml
    │   ├── network.yaml
    │   ├── energy.yaml
    │   └── automations.yaml
    └── popups/
        ├── _template.yaml               # shared popup_template definition
        ├── living-room.yaml
        ├── kitchen.yaml
        ├── office.yaml
        └── outdoor.yaml
```

YAML-mode registration in `configuration.yaml`:
```yaml
lovelace:
  mode: storage  # other dashboards stay storage
  dashboards:
    fusion:
      mode: yaml
      filename: dashboards/fusion.yaml
      title: Fusion
      icon: mdi:hexagon-multiple
      show_in_sidebar: true
      require_admin: false
```

---

## Branch + commit conventions

- **Branch naming**: `phase7/wpN-<slug>` (e.g. `phase7/wp1-test-harness`, `phase7/wp5a-template-livingroom`).
- **Branch from**: `main` for WP1 and WP2; the parent WP's merged commit for downstream WPs.
- **Merge strategy**: PR + squash-merge to `main`. Each WP becomes one commit on `main`.
- **Commit style during work**: small, frequent commits on the WP branch are fine (they get squashed). End-of-WP commit message format:
  ```
  feat(fusion): WPN — <one-line summary>

  - bullet of what changed
  - test results
  - Gate 2 reviewed: YYYY-MM-DD
  ```
- **Pre-commit hook** (already installed): blocks commits on `config/packages/*.yaml` lacking `# Gate 2 reviewed: YYYY-MM-DD`. Dashboard files are exempt but WP brief specifies which files need the marker.

---

## Dependency graph & merge order

```
       WP1 (Test Harness + Baseline)
              │
              ▼
       WP2 (File restructure + YAML mode)
              │
   ┌──────────┼──────────┐
   ▼          ▼          ▼
  WP3        WP4       WP5a
 (Grids)   (Shell)  (Template+LR)
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
            WP5b       WP5c       WP5d
          (Kitchen)  (Office)   (Outdoor)
              │          │          │
              └──────────┼──────────┘
                         ▼
                       WP6 (Wiring + nav-hide + cosmetics)
```

**Calendar slots:**
| Slot | Sessions running in parallel |
|------|------------------------------|
| 1 | WP1 + WP2 (sequential, same session OR back-to-back) |
| 2 | WP3, WP4, WP5a (3 parallel sessions) |
| 3 | WP5b, WP5c, WP5d (3 parallel sessions) |
| 4 | WP6 (single session) |

A downstream WP must `git pull origin main` before starting and rebase if its parent has merged in the meantime.

---

## "Do not touch" boundaries

Each WP brief lists its writable file scope. Anything outside that scope is read-only for that session. **Violating this guarantees merge conflicts.** If a WP discovers it needs to modify out-of-scope files, stop and post the discovery to the BACKLOG for a follow-up WP — do not silently widen scope.

---

## Test harness contract

WP1 produces:
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — assertion list per viewport.
- `scripts/run-fusion-tests.sh` — executes assertions via Chrome MCP + HA MCP.

Subsequent WPs:
- **First step of every WP**: write that WP's tests (additions to `fusion-tests.md`). Run the suite — new tests must fail. Existing tests must still pass.
- **Last step of every WP** (before Gate 2): run the full suite. All tests must pass before Gate 2 review.
- **Test cost discipline**: prefer fewer robust assertions over many fragile ones. Flaky tests are worse than no tests.

Test categories (see WP1 for full taxonomy):
1. YAML schema validation (`ha_check_config`)
2. Entity existence (`ha_get_state`)
3. Template eval (`ha_eval_template`)
4. DOM assertion (Chrome MCP `javascript_tool`)
5. Visual regression (Chrome MCP `screenshot`)
6. Behavioural (Chrome MCP click + assert)

---

## Workflow per WP (mandatory — applies inside every WP brief)

Every WP follows the standard project workflow from `INSTRUCTIONS.md`:

1. **Session start** — read INSTRUCTIONS.md, PROFILE.md, CHANGELOG.md, DECISIONS.md, BACKLOG.md, this COORDINATION.md, and the WP brief.
2. **Gate 1** — read the WP brief, confirm scope alignment with Edgar in chat. Use `AskUserQuestion` to resolve any ambiguity. **Do not skip this even though the brief is detailed** — the brief is a starting point, Edgar may want adjustments.
3. **TDD step** — write tests first (additions to `fusion-tests.md`). Confirm new tests fail before writing implementation.
4. **Gate 2** — write the YAML, run tests, then invoke `ha-code-reviewer` via `scripts/gate2-review.sh`. Iterate until APPROVED. Add `# Gate 2 reviewed: YYYY-MM-DD` line to modified files where the pre-commit hook requires it.
5. **Gate 3** — backup, validate entities, validate templates, write+commit, deploy.sh (only the entry-point file changed needs deploy on subsequent WPs since includes ride along), verify, test action, check traces.
6. **Visual verification** — Chrome MCP screenshots at all viewports the WP touches. Save them under `00 - Agent Context/fusion-phase7/screenshots/wpN/`.
7. **Session end** — update CHANGELOG.md, DECISIONS.md (if any new decision), LAST_UPDATED, commit and push.

---

## Coordination signals

Each WP, when complete and merged, posts a one-line entry to `00 - Agent Context/fusion-phase7/STATUS.md`:

```
- [x] WP1 — merged 2026-04-26 — commit abc123 — tests: 27 passing
- [ ] WP2 — in progress (Edgar) — branch phase7/wp2-restructure
```

Downstream WPs check STATUS.md before starting to confirm prerequisites are merged.

---

## Stop-and-ask criteria (every WP)

A session must stop and consult Edgar if any of:

- A test is impossible to write (suggests scope ambiguity).
- A required entity is `unavailable` or `unknown` and there's no obvious fallback.
- The WP brief's "do not touch" scope feels wrong for the actual work.
- `ha-code-reviewer` returns BLOCKED twice in a row on the same finding (suggests deeper issue).
- The merge conflict on rebase is non-trivial (one WP made changes another didn't expect).
- Visual verification reveals breakage outside the WP's scope.

Do not improvise. Stop, surface, get direction.

---

## Out of scope for Phase 7 (do not work on, even if tempted)

- Missing scene buttons in the spec's 8-scene hero row (blocked on scene definitions — content task).
- Power Now hero tile (blocked on power source).
- BubbleDash v4 archival (separate BACKLOG item).
- Any non-FUSION dashboard.
- Adding new HA entities, helpers, or automations not directly required by this overhaul.

---

## After Phase 7

WP6 closes Phase 7. Update `BACKLOG.md` to:
- Mark item #10 (Mobile responsiveness) as ✅ closed.
- Mark item #9 (Pulsing presence dot) as ✅ closed.
- Mark Bubble Card popups item as ✅ closed.
- Open a new BACKLOG item: "Phase 7 retro — capture lessons from parallel-session workflow."
