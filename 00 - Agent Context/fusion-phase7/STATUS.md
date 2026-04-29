# FUSION Phase 7 — Work Package Status

Each parallel session updates this file when it merges its WP to `main`.
Format: `- [x] WPN — merged YYYY-MM-DD — commit <sha> — <one-line note>`

---

## Status

- [x] WP1 — test harness + baseline — merged 2026-04-27 — commit `6393090` (squashed into WP2's PR #6 merge) — 27 tests, 25 baseline + 2 baseline_known_failure (TEST-007/008 — see WP2 note below)
- [x] WP2 — file restructure + YAML mode — merged 2026-04-27 — commit `6393090` (PR #6) — deployed, restarted, verified rendering. **Suite: 35/36 pass at the Chrome MCP harness reach.** TEST-103 fails because the harness can only reach 606 px inner width on this macOS host; at that width the sidebar happens to be visible, but at real iPhone 375 CSS px (verified hands-on by Edgar) the sidebar IS off-screen as the WP1 baseline documented. TEST-007 + TEST-008 stay `baseline_known_failure` — the WP3 + WP4 fix targets are unchanged. Storage-mode `dashboard_fusion` was auto-removed by HA on restart (YAML-mode took the same url_path). See CHANGELOG 2026-04-27 "WP2 — corrections" for the retraction of the earlier "sidebar surprise" claim.
- [x] WP3 — responsive grid migration — merged 2026-04-28 — commit `a1c8924` (PR #10) — 9 fixed grids → `repeat(auto-fit, minmax(MIN, 1fr))` across 5 panels (home/climate/media/network/energy); 13 new tests (TEST-200..212) + TEST-103 flipped to baseline_known_failure (harness reach ≥606 px); Gate 2 APPROVED. Deployed 2026-04-29 (slot-2 verification — see CHANGELOG: WP5c-deploy-stomp incident overwrote shell.yaml + delivered office.yaml without merge; recovered via main re-sync).
- [x] WP4 — shell swap (state-switch + phone bottom tab) — merged 2026-04-28 — commit `d4e648b` (PR #11) — Gate 2 APPROVED (round 2), ha_check_config valid, dashboard verified rendering at desktop viewport 1849 (8 sidebar nav cells visible, 0 fixed-position bottom bars, 7 statusbar cards, climate-tab + More-overlay behavioural tests pass). New entities: `input_boolean.fusion_more_overlay`. New HACS: `thomasloven/lovelace-state-switch` v1.9.6. New tests: TEST-300..315 (16, all `baseline_known_failure`). **Outstanding (does NOT block WP5b/c/d): Edgar's iPhone hands-on verification → flip TEST-007/008/305..311 to `baseline`.** PR #11 was merged before that hands-on completed.
- [x] WP5a — popup template + Living Room popup — merged 2026-04-28 — commit `918c042` (PR #9) — Gate 2 reviewed APPROVED (after one round of fixes for missing shell.yaml include + Automations-header inline-vs-template). 17 tests added (TEST-400 … TEST-416); 8 yaml_schema pass; 14 browser-deferred + 1 entity test pending Slot-2 re-verify. Single-include in shell.yaml puts living-room popup as sibling of state-switch (always in DOM, viewport-agnostic). Deployed 2026-04-29 — see CHANGELOG for the WP5c-deploy-stomp incident.
- [x] WP5b — Kitchen popup — merged 2026-04-29 — commit `0500a41` (PR #14) — Gate 2 APPROVED (superpowers:code-reviewer fallback after `ha-code-reviewer` hit org limit; APPROVED with 4 non-blocking concerns: stale category-counts table, untracked-files staging caution, sensors row ordering note, manifest-comment vs render parity). 10 new tests (TEST-430 … TEST-439). Deployed 2026-04-29 (backup `d5deafb0`, SCP'd kitchen.yaml + sed-edit of HA Green's shell.yaml). `ha_check_config` valid. WS `lovelace/config { force: true }` returned config with 3 shell cards including `#popup-kitchen`. **Browser-side hash test deferred** (Chrome MCP `hui-panel-view` chunk-load issue affects all dashboards on this host) — live-popup verification runs on Edgar's real-device next pass.
- [x] WP5c — Office popup — merged 2026-04-29 — commit `a75c33e` (PR #13) — committed + deployed 2026-04-28 on branch `phase7/wp5c-office` (worktree per HARD RULE), Gate 3 deploy.sh ✅ for both `popups/office.yaml` and `shell.yaml` (!include wired). Rebased onto WP5b's main on merge — kitchen + office includes now both sit as siblings of state-switch in shell.yaml. Browser hash-test of `#popup-office` pending Edgar's real-device verification (same harness blocker as WP5b).
- [x] WP5d — Outdoor popup — implemented + deployed 2026-04-29 on branch `phase7/wp5d-outdoor` — Gate 2 APPROVED (`ha-code-reviewer`, no defects; one ⚠️ on sun.sun next-event boundary flagged as non-blocking + 4 informational notes). 11 new tests (TEST-450 … TEST-460). Deployed via `./deploy.sh` for `popups/outdoor.yaml` + `shell.yaml`. **Also redeployed `popups/office.yaml`** because HA Green was missing it (WP5c-deploy-stomp lingering effect: shell.yaml on git already wires office, so deploying my shell.yaml change without office.yaml on disk would have broken the dashboard). `ha_check_config` valid. WS `lovelace/config { force: true }` confirms 4 popup siblings of `state-switch`: `#popup-living-room`, `#popup-kitchen`, `#popup-office`, `#popup-outdoor`. **Browser-side hash test deferred** (same Chrome MCP `hui-panel-view` chunk-load harness blocker that affected WP5b/c). Outdoor swaps Climate for Weather: current temp tile from `input_number.monitoring_outdoor_temperature` + humidity/UV/wind rows from `weather.forecast_home` + sunrise/sunset rows from `sun.sun` (state-operator highlights next event) + 24h ApexCharts trend on `input_number.monitoring_outdoor_temperature`. WP6 unblocked.
- [ ] WP6 — wiring + nav-hide + cosmetic gaps (close-out)

---

## Parallel-launch readiness gates

A session can start its WP only when its prerequisites are checked above:

| WP | Can start after |
|----|-----------------|
| WP1 | (nothing — foundational) |
| WP2 | WP1 ✅ |
| WP3 | WP2 ✅ |
| WP4 | WP2 ✅ |
| WP5a | WP2 ✅ |
| WP5b | WP5a ✅ |
| WP5c | WP5a ✅ |
| WP5d | WP5a ✅ |
| WP6 | WP3 ✅, WP4 ✅, WP5b ✅, WP5c ✅, WP5d ✅ |
