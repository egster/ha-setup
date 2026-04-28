# FUSION Phase 7 — Work Package Status

Each parallel session updates this file when it merges its WP to `main`.
Format: `- [x] WPN — merged YYYY-MM-DD — commit <sha> — <one-line note>`

---

## Status

- [x] WP1 — test harness + baseline — merged 2026-04-27 — commit `6393090` (squashed into WP2's PR #6 merge) — 27 tests, 25 baseline + 2 baseline_known_failure (TEST-007/008 — see WP2 note below)
- [x] WP2 — file restructure + YAML mode — merged 2026-04-27 — commit `6393090` (PR #6) — deployed, restarted, verified rendering. **Suite: 35/36 pass at the Chrome MCP harness reach.** TEST-103 fails because the harness can only reach 606 px inner width on this macOS host; at that width the sidebar happens to be visible, but at real iPhone 375 CSS px (verified hands-on by Edgar) the sidebar IS off-screen as the WP1 baseline documented. TEST-007 + TEST-008 stay `baseline_known_failure` — the WP3 + WP4 fix targets are unchanged. Storage-mode `dashboard_fusion` was auto-removed by HA on restart (YAML-mode took the same url_path). See CHANGELOG 2026-04-27 "WP2 — corrections" for the retraction of the earlier "sidebar surprise" claim.
- [ ] WP3 — responsive grid migration — committed + pushed, deploy pending — branch `phase7/wp3-grids` — 9 fixed grids → `repeat(auto-fit, minmax(MIN, 1fr))` across 5 panels (home/climate/media/network/energy); 13 new tests (TEST-200..212) + TEST-103 flipped to baseline_known_failure (harness reach ≥606 px); Gate 2 APPROVED.
- [~] WP4 — shell swap (state-switch + phone bottom tab) — implemented + deployed 2026-04-27 on branch `phase7/wp4-shell` — Gate 2 APPROVED (round 2), ha_check_config valid, dashboard verified rendering at desktop viewport 1849 (8 sidebar nav cells visible, 0 fixed-position bottom bars, 7 statusbar cards, climate-tab + More-overlay behavioural tests pass). **Awaiting Edgar's iPhone hands-on verification before merging PR + flipping TEST-007/008/305..311 to `baseline`.** New entities: `input_boolean.fusion_more_overlay`. New HACS: `thomasloven/lovelace-state-switch` v1.9.6. New tests: TEST-300..315 (16, all `baseline_known_failure` until phone verification confirms).
- [ ] WP5a — popup template + Living Room popup
- [ ] WP5b — Kitchen popup
- [ ] WP5c — Office popup
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
