# FUSION Phase 7 — Retro

**Date**: 2026-04-29 (post-WP6 close-out)
**Span**: 2026-04-26 (WP1 start) → 2026-04-29 (WP6 deploy) — ~3.5 calendar days, 4 calendar slots
**Scope**: Six work packages — test harness + baseline (WP1), file restructure + YAML-mode dashboard registration (WP2), responsive grid migration (WP3), state-switch hybrid shell with bottom-tab nav (WP4), popup template + four room popups (WP5a-d), final wiring + nav-hide + cosmetic gaps (WP6)
**Outcome**: Dashboard is responsive — sidebar at ≥871px, bottom-tab nav at <871px. Four room popups (LR/Kitchen/Office/Outdoor). 9 grids migrated to `auto-fit minmax`. Sidebar separator + pulsing presence dot polish. 118 tests in `fusion-tests.md` (vs 27 at WP1 baseline). Real-device verification sweep deferred to Edgar.

---

## What worked

### Parallel-session model (Slot 2 + Slot 3) with the worktree HARD RULE

After the WP5a session-stash collisions on 2026-04-27 (three sessions sharing the same working tree, branches checked out sequentially evicting each other's unstaged work), the COORDINATION.md HARD RULE for `git worktree add` was the single highest-leverage change. Slot 2 (WP3 + WP4 + WP5a) and Slot 3 (WP5b + WP5c + WP5d) ran without filesystem-level interference because each session opened in its own worktree path. Branch isolation alone would not have been enough. The rule is now permanent and should propagate to any future multi-WP project (Phase 8+, larger refactors, etc.).

### Test-Driven Design with `baseline_known_failure`

Writing tests first — and accepting that every WP's new tests start as `baseline_known_failure` — kept the team honest about what "done" means. The `baseline_known_failure` status is a durable promise: once the WP closes and the test-target works, the status flips to `baseline`. This made it visible per-WP what was claimed-but-unverified vs verified-and-load-bearing.

The test count grew honestly: 27 at WP1 → 36 after WP2 → 49 after WP3 → 65 after WP4 → 82 after WP5a → 92 after WP5b → 103 after WP5d → 118 after WP6.

### `ha-code-reviewer` Gate 2 catching real defects

Across the 6 WPs, the reviewer caught (non-exhaustive):
- WP4 round 1: missing `default:` semantics in state-switch (must be a state-name string, not a card definition); `position: fixed` descendants escape the state-switch grid hide
- WP5a round 1: missing `!include` line for living-room popup in shell.yaml; Automations-header inline-vs-template inconsistency
- WP5b: stale fusion-tests.md per-category counts table (caught at WP5b, finally fixed at WP6)
- WP6: dashboard-YAML `Gate 2 reviewed:` marker convention drift; `:host-context()` Safari caveat; defensive `person.edgar` guard symmetry suggestion

These were not all blocking findings, but each one improved the merged version. The `MODE: code-review` half of `ha-code-reviewer` earned its keep.

### Bubble Card popup wrapper duplication-not-include

The 2026-04-27 WP5a decision to duplicate the popup wrapper structure verbatim (vs `!include`-ing a sub-key) avoided a class of YAML-merge bugs and made each popup file independently grep-able. With only 4 popups, the duplication cost is low. Pattern would re-evaluate if a 5th popup arrives.

### Verbatim-relocation contract for WP2

WP2's contract — "every byte of the dashboard YAML must move 1:1 into the new file structure, no behaviour change" — was verifiable by structural fingerprint (TEST-101 / TEST-102 / TEST-103). When WP2 deployed, the harness-reachable fingerprints matched WP1's exactly. This bought a clean foundation for WP3-WP6 to layer changes on top without losing the ability to bisect "did WP2 introduce this drift?"

---

## What broke (and what we'd change)

### WP5c-deploy-stomp incident (2026-04-29)

**What happened.** Slot-2 verification found the deployed dashboard rendering an empty body. Root cause: HA Green's `/config/dashboards/fusion/` was desynchronised from `main` — `shell.yaml` had two popup includes (one valid, one rogue from an unmerged branch) and one of the two referenced popup files was missing from disk. Fix took ~30 minutes of `git archive main config/dashboards/fusion/` + per-file md5 diff + targeted SCP recovery.

**Two surface causes:**
1. **`deploy.sh` doesn't handle `config/dashboards/`.** Only handles `config/packages/*.yaml`. Dashboard files have to be SCPed manually, and the manual flow makes it easy to leave HA in a partial state during multi-session work.
2. **Lovelace `!include` resolution is lazy.** `ha core check` doesn't catch a missing popup include (the `!include` resolves at request time, not config-load time), so the deploy "succeeded" structurally even with a broken include.

**Fix forward (BACKLOG):** extend `deploy.sh` (or add `deploy-dashboard.sh`) that refuses partial syncs / orphan files and runs a "full include resolution" check before declaring the deploy clean. Surfaced in BACKLOG.

### Bubble Card body-class fingerprint drift across WP5a/b/d tests

**What happened.** The WP6 brief's "hook Bubble Card's `bubble-popup-open` body class" was wrong — the actual class is `bubble-body-scroll-locked`. WP6 caught it by decompressing `bubble-card.js.gz` and grepping for body-classList ops. WP5a/b/d's tests TEST-403, TEST-432, TEST-452 inherited the brief's wrong class name and would have silently failed Edgar's real-device pass.

**Root cause.** No earlier WP had a reason to actually verify the body-class assumption against source — the popup-open browser tests have been deferred to Edgar's real-device pass since WP5a (Chrome MCP harness blocker), so the wrong assumption never surfaced.

**Fix forward (BACKLOG, doc-only PR).** Update TEST-403, TEST-432, TEST-452 to either use `bubble-body-scroll-locked` or accept either class (cross-version safety). Already fixed `_template.yaml` line 23 in WP6.

### Chrome MCP `hui-panel-view` chunk-load harness blocker

**What happened.** From WP5b onward, the Chrome MCP harness on the macOS host could not load the `hui-panel-view` chunk for the FUSION dashboard URL — verified via `customElements.get('hui-panel-view') === false` after multiple full reloads. The dashboard renders fine on real browsers (Edgar's iPhone, his desktop), so this is harness-specific. Net effect: every popup-open browser test in WP5b/c/d/6 stays `baseline_known_failure` until Edgar's real-device pass.

**Surprising.** Sometimes the panel kicks into rendering after a window resize or a navigation+wait — WP6 caught one render successfully on the second screenshot batch. Not reliable enough to base test verification on.

**Fix forward (no change, just documented).** The `baseline_known_failure` status is the right place for these — they're real tests with real targets, the harness just can't reach them. Edgar's real-device sweep is the canonical verification surface. Phase 8+ should consider whether a phone-emulation harness (DevTools mobile mode via Chrome MCP, or a real iOS device with remote debug) is worth standing up.

### Branch-context drift across long-lived feature branches

**What happened.** A few WPs (WP5a, WP5c) had multi-day gaps between "Gate 2 APPROVED" and "deployed + verified", during which `main` advanced. Rebasing those branches onto the new `main` was always clean (the WPs touched orthogonal files), but the agent's mental model of "is my branch up-to-date?" had to be re-established every session-start.

**Mitigation already in place.** The slot-3 verification session (2026-04-29 morning) caught + fixed the WP5c-deploy-stomp before WP6 started. The session-start `git pull origin main` + `git status` discipline proves load-bearing.

**Fix forward.** No change needed — the existing INSTRUCTIONS.md "session start" rule + each WP's "git pull origin main && git checkout -b" prereq are sufficient. The cost of one rebase pass per WP is below the cost of trying to land everything in a single sitting.

### `templates.yaml` `popup_row` duplicate-keys silent bug

**What happened.** Lines 218-280 of `templates.yaml` define the `popup_row` button-card template with TWO `styles:` blocks — `card`, `icon`, `name`, `grid` keys appear twice. YAML last-wins gives bottom-tab styling for active popup_rows, which means the popup_row template's intended row visual ("horizontal `i n` row") is being overridden by a different shape ("small centered chip"). WP5b shipped with this; WP5d and WP6 inherited it. Empty-state rows that override styles inline still render correctly.

**Root cause.** The bug was introduced at WP5a + carried forward unnoticed because (a) the empty-state rows that exercise the buggy active-row styling override the styles inline, masking the bug; (b) browser-side rendering verification has been deferred since WP5a. The static YAML lint check passes — duplicate keys at sub-mapping level are valid YAML, just ambiguous.

**Fix forward (BACKLOG).** Focused refactor PR after Phase 7 retro cooldown. Visible behaviour change: active popup_rows shift from chip → horizontal-row visual. Test text-content survives the change.

---

## Process improvements adopted mid-stream

### COORDINATION.md HARD RULE for parallel sessions
Added 2026-04-27 after the WP5a stash collisions. Mandatory `git worktree` per parallel session. Slot 2 + Slot 3 ran cleanly because of it.

### Verbatim-relocation contract for relocation-only WPs
Codified at WP2. Future relocation work follows the same shape: 1:1 byte movement, structural fingerprint test as regression guard.

### Manifest header on each popup file
Each room popup file ships with a manifest comment block listing every entity it references, why it's in scope (or excluded), and the rendering contract. Future maintenance reads from the manifest, not from grepping the YAML.

### Per-WP `# Gate 2 reviewed:` markers on dashboard YAMLs (WP6, codified in DECISIONS)
Append-on-edit, not bump-in-place. Documentation-only on dashboard files (the pre-commit hook only enforces on `config/packages/*.yaml`), but the layered form preserves provenance across WPs.

---

## Phase 7 follow-ups (tracked in BACKLOG)

| # | Item | Priority |
|---|------|----------|
| 1 | Doc-only PR: fix WP5a/b/d test class-name fingerprint (`bubble-popup-open` → `bubble-body-scroll-locked`) | Medium — blocks Edgar's real-device sweep |
| 2 | Real-device verification sweep on Edgar's iPhone + desktop browser; capture canonical screenshots at 4 viewports × (popup open/closed) | High — the load-bearing verification |
| 3 | `templates.yaml` `popup_row` duplicate-keys refactor | Low — visual polish |
| 4 | Safari/WebKit `MutationObserver` fallback for `:host-context()` body-class hooks | Low — informational only, Chrome kiosk is target |
| 5 | `# Gate 2 reviewed:` codification for dashboard YAMLs in DECISIONS (already done in DECISIONS 2026-04-29; just confirm it's the codified convention) | Low — cleanup |
| 6 | `deploy.sh` extension for `config/dashboards/` (refuse partial syncs / orphan files) | Medium — would have caught WP5c-deploy-stomp |
| 7 | `person.edgar` defensive `unavailable` guard (and edphone/ipad for symmetry) | Low — resilience polish |

---

## Numbers

| Metric | WP1 baseline | Phase 7 close (WP6) |
|--------|-------------|---------------------|
| Test count | 27 | 118 |
| Dashboard files | 1 monolith (`fusion.yaml`, ~1731 lines) | 14 files (entry + shell + statusbar + templates + 7 panels + 5 popups including `_template.yaml`) |
| Responsive viewports verified | 1 (1280) | 3 effective (1280, 900, ~706 effective via macOS Chrome) + real-device sweep pending for 700 + 375 |
| Bubble Card popups | 0 | 4 (Living Room, Kitchen, Office, Outdoor) |
| Sidebar nav cells | 8 (7 panels + kiosk) | 9 (7 panels + separator + kiosk) |
| Pulsing-dot indicators | 0 | 1 (rendered in 2 DOM positions, both shell branches in DOM by state-switch) |
| Open `baseline_known_failure` (post-real-device-sweep target) | 2 (WP1 sidebar tests) | 5 (permanent harness-limit known-failures) |

---

## Recommendations for Phase 8+

1. **Parallel sessions: keep the worktree HARD RULE.** It's earned its place. Don't soften it to "branch-only" even for "small" WPs.

2. **Verify ecosystem assumptions against source, not docs/briefs.** WP6's class-name verification would have been a one-liner if done at WP5a. Default to "decompress the bundled JS / read the source" for any Bubble Card / state-switch / card-mod claim that isn't already in DECISIONS.

3. **`deploy.sh` should grow `config/dashboards/` support.** The WP5c-deploy-stomp incident was preventable. Add a per-file md5 diff + dashboard-tree integrity check before any partial dashboard SCP.

4. **Real-device verification harness for phone viewports.** Chrome MCP on macOS bottoms out at ~526px effective. iOS Safari + Web Inspector remote debug, OR DevTools mobile-mode emulation via Chrome MCP, would close the verification loop. Phase 8 candidate.

5. **`baseline_known_failure` is the right convention; don't drop it.** It's the honesty bit for tests that are real but harness-blocked. Keep it through Phase 8+. Edgar's real-device sweeps are the flip-to-`baseline` event.

6. **Keep retros short and follow-up-driven.** This retro doc is ~250 lines; the value is in the BACKLOG follow-up table at the top. The narrative is for the agent's future-self, not a deliverable.

---

*End of retro — Phase 7 closed.*
