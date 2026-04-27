# FUSION Phase 7 — Work Package Status

Each parallel session updates this file when it merges its WP to `main`.
Format: `- [x] WPN — merged YYYY-MM-DD — commit <sha> — <one-line note>`

---

## Status

- [x] WP1 — test harness + baseline — merged 2026-04-27 — commit `6393090` (squashed into WP2's PR #6 merge) — 27 tests, 25 baseline + 2 baseline_known_failure (TEST-007/008 — see WP2 note below)
- [x] WP2 — file restructure + YAML mode — merged 2026-04-27 — commit `6393090` (PR #6) — deployed, restarted, verified rendering. **Suite: 35/36 pass.** TEST-103 fails: sidebar fingerprint at 700px is `left=172` (visible) instead of WP1's expected `-84` (off-screen) — **YAML-mode narrow rendering accidentally fixed sidebar visibility on tablet/phone viewports**, ahead of WP3+WP4. TEST-007 + TEST-008 (WP1 known-failures) now pass at the Chrome MCP min-window cap (606px). Real iPhone (375 CSS px) still untested — must verify before flipping the WP1 known-failure status permanently.
- [ ] WP3 — responsive grid migration
- [ ] WP4 — shell swap (state-switch + phone bottom tab)
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
