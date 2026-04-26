# WP3 — Responsive Grid Migration

**Branch**: `phase7/wp3-grids`
**Branches from**: `main` (after WP2 merged)
**Parallelizable with**: WP4, WP5a (3 simultaneous sessions allowed)
**Estimated effort**: half session

---

## Goal

Replace every fixed grid template (`grid-template-columns: repeat(3, 1fr)` etc.) inside the FUSION panels with `responsive_grid_layout` using `auto-fit, minmax(280px, 1fr)`. This makes panel content gracefully collapse from 3-column → 2-column → 1-column as viewport narrows, and works inside both the desktop and phone shells.

This WP touches **only the panels** — the outer shell change is WP4's job. Grids and shell are independent because the grid columns adapt to whatever container width they're given.

---

## Required reading

1. `00 - Agent Context/INSTRUCTIONS.md`
2. `00 - Agent Context/PROFILE.md`
3. `00 - Agent Context/CHANGELOG.md`
4. `00 - Agent Context/DECISIONS.md` — note layout-card + button-card width quirks (R2 from FUSION retro)
5. `00 - Agent Context/fusion-phase7/COORDINATION.md`
6. `00 - Agent Context/fusion-phase7/STATUS.md` — confirm WP2 merged
7. `00 - Agent Context/fusion-phase7/fusion-tests.md` — current baseline + WP2 additions
8. `00 - Agent Context/FUSION-DESIGN-SPEC.md`
9. `config/dashboards/fusion/panels/*.yaml` — all 7 panel files (post-WP2)
10. HACS `layout-card` docs on `responsive_grid_layout` (web search)

---

## Inputs

- 7 panel files post-WP2 restructure.
- Knowledge of which grids are fixed (`repeat(N, 1fr)`) and which already responsive.

---

## Outputs (writable scope)

- `config/dashboards/fusion/panels/home.yaml`
- `config/dashboards/fusion/panels/kitchen.yaml`
- `config/dashboards/fusion/panels/climate.yaml`
- `config/dashboards/fusion/panels/media.yaml`
- `config/dashboards/fusion/panels/network.yaml`
- `config/dashboards/fusion/panels/energy.yaml`
- `config/dashboards/fusion/panels/automations.yaml`
- `00 - Agent Context/fusion-phase7/fusion-tests.md` — add WP3 tests
- `00 - Agent Context/fusion-phase7/STATUS.md` — update

**Do not touch**: `shell.yaml`, `statusbar.yaml`, `templates.yaml`, `fusion.yaml`, anything under `popups/`. **WP4 and WP5a may be modifying these in parallel — touching them = merge conflict.**

---

## TDD additions (write first)

| ID | Type | Assertion |
|----|------|-----------|
| TEST-200 | DOM | At 1280px on home panel, MAIN FLOOR room cards render in 3 columns |
| TEST-201 | DOM | At 900px on home panel, MAIN FLOOR room cards render in 3 columns |
| TEST-202 | DOM | At 700px on home panel, MAIN FLOOR room cards render in 2 columns |
| TEST-203 | DOM | At 375px on home panel, MAIN FLOOR room cards render in 1 column |
| TEST-204 | DOM | At 1280px on climate panel, climate zones render in ≥4 columns |
| TEST-205 | DOM | At 700px on climate panel, climate zones render in 2 columns |
| TEST-206 | DOM | At 375px on climate panel, climate zones render in 1 column |
| TEST-207 | DOM | At 1280px on network panel, network cards render in 3 columns |
| TEST-208 | DOM | At 375px on network panel, network cards render in 1 column |
| TEST-209 | DOM | At 1280px on media panel, media cards render in 2 columns |
| TEST-210 | DOM | At 375px on media panel, media cards render in 1 column |
| TEST-211 | Visual | No horizontal overflow on any panel at any of the 4 viewports |
| TEST-212 | Visual | Card minimum width of 280px is respected — no card shrinks below |

Run the suite. New tests must fail. Existing baseline + WP2 tests must pass.

---

## Implementation notes

### The pattern

Replace this:
```yaml
type: custom:layout-card
layout_type: custom:grid-layout
layout:
  grid-template-columns: repeat(3, 1fr)
  grid-gap: 8px
```

With this:
```yaml
type: custom:layout-card
layout_type: custom:responsive-grid-layout
layout:
  grid-template-columns: 'repeat(auto-fit, minmax(280px, 1fr))'
  grid-gap: 8px
```

### Per-panel column targets (verify and tune)

| Panel | Old grid | New minmax target | Reasoning |
|-------|----------|-------------------|-----------|
| home (rooms) | `repeat(3, 1fr)` | `minmax(280px, 1fr)` | Room cards need text room |
| climate | `repeat(4, 1fr)` | `minmax(220px, 1fr)` | Zones are compact |
| network | `repeat(3, 1fr)` | `minmax(280px, 1fr)` | |
| media | `repeat(2, 1fr)` | `minmax(320px, 1fr)` | Player cards are wider |
| energy | `repeat(2, 1fr)` | `minmax(320px, 1fr)` | |
| kitchen | (varies — see file) | TBD per existing layout | Kitchen has bespoke layout |
| automations | (varies) | TBD per existing layout | |

### Known gotcha (DECISIONS R2)

`layout-card` ignores `width:` on its internal wrapper. If you find existing `width:` overrides in the panel files, they're probably already broken — don't try to "preserve" them. Use margin or container-padding instead.

### Container-aware sizing

The new responsive grids will respond to whatever container width they're given. When the WP4 shell change lands, panels at 375px viewport will get less container width because the bottom-tab shell removes the 72px sidebar column. Your minmax values should still produce 1-column at 375 - 72 - 32 (margins) = ~270px container width. **Set minmax to 260-280px for safety**, not 320.

### Don't touch the room rows themselves

Each room card contains stacked rows (lights, sensors). Those rows already use `repeat(2, 1fr)` or `1fr` in some cases — that's the inner layout, not the outer panel grid. **Leave inner row layouts alone.** WP3 only touches the panel-level grids.

---

## Implementation steps

1. Read all required reading.
2. `git pull origin main && git checkout -b phase7/wp3-grids`.
3. Confirm WP2 merged via STATUS.md.
4. For each panel file, read it and identify the panel-level `grid-template-columns` declarations.
5. Add the WP3 tests to `fusion-tests.md`. Run the suite — confirm new tests fail.
6. Make the substitutions one panel at a time. Commit per panel: `refactor(fusion): WP3 — responsive grid for <panel>`.
7. After each panel, run that panel's specific tests via the runner.
8. After all 7 panels done, run the full suite. All tests must pass.
9. Visual verification via Chrome MCP: screenshot every panel at all 4 viewports. Save under `screenshots/wp3/`.
10. Gate 2 review via `scripts/gate2-review.sh`.
11. Gate 3 deploy.
12. Update STATUS.md, CHANGELOG, LAST_UPDATED.

---

## Stop-and-ask triggers

- A panel file has a structure that doesn't fit the simple substitution (e.g. nested grids that depend on each other) → STOP and surface.
- Switching to `responsive-grid-layout` changes the visual output beyond column count (e.g. card padding shifts, gaps look wrong) → STOP. The card-mod styling may need adjustment.
- A test passes locally but fails on Edgar's iPad in his manual check → STOP. Don't push past it.

---

## Acceptance criteria

- [ ] All 7 panel files use `responsive_grid_layout` for top-level grids.
- [ ] Column count behaves correctly at 375 / 700 / 900 / 1280 px on every panel.
- [ ] No horizontal overflow at any viewport (verified visually).
- [ ] All baseline + WP2 + WP3 tests pass.
- [ ] `ha-code-reviewer` APPROVED.
- [ ] Visual screenshots saved.
- [ ] STATUS.md, CHANGELOG, DECISIONS (if needed), LAST_UPDATED updated.
- [ ] Branch merged to main.
