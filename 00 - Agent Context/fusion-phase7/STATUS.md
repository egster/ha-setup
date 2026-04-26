# FUSION Phase 7 — Work Package Status

Each parallel session updates this file when it merges its WP to `main`.
Format: `- [x] WPN — merged YYYY-MM-DD — commit <sha> — <one-line note>`

---

## Status

- [ ] WP1 — test harness + baseline (foundation) — PR open, branch `phase7/wp1-test-harness`, 27 tests (25 baseline + 2 baseline_known_failure for TEST-007/008 sidebar at `left=−84` on narrow viewports)
- [ ] WP2 — file restructure + YAML mode (enabler)
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
