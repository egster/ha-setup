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
- [ ] WP5b — Kitchen popup — branch `phase7/wp5b-kitchen` — Gate 2 APPROVED (superpowers:code-reviewer fallback after `ha-code-reviewer` hit org limit; APPROVED with 4 non-blocking concerns: stale category-counts table, untracked-files staging caution, sensors row ordering note, manifest-comment vs render parity). 10 new tests (TEST-430 … TEST-439) — yaml_schema, entity_existence (13 manifest entities), behavioural popup-open, DOM section presence + motion-state + ApexCharts. Deployed 2026-04-29: backup `d5deafb0`, SCP'd living-room.yaml (closing WP5a deploy gap that was reintroduced by the WP5c-deploy-stomp recovery) + kitchen.yaml; surgical sed-edit of HA Green's shell.yaml to add the `!include popups/kitchen.yaml` line (avoiding stomping on parallel WP5c). `ha_check_config` valid. WS `lovelace/config { force: true }` returned config with 3 shell cards including `#popup-kitchen`. **Browser-side hash test deferred:** the Chrome MCP harness on this host hits a `hui-panel-view` chunk-load issue affecting all dashboards (BubbleDash + FUSION + Overview-via-redirect), so the live-popup verification will run on Edgar's real-device next pass — same precedent as WP4 (PR #11 merged before iPhone hands-on).
- [ ] WP5c — Office popup — committed + deployed 2026-04-28 on branch `phase7/wp5c-office` (worktree per HARD RULE), Gate 3 deploy.sh ✅ for both `popups/office.yaml` and `shell.yaml` (!include wired). Browser hash-test of `#popup-office` pending. PR open for review/merge.
- [ ] WP5d — Outdoor popup
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
