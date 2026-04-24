# Session Retro — FUSION Dashboard full build
# 2026-04-24

Scope: building FUSION from a design spec + BACKLOG approach to a fully polished dashboard deployed at `/dashboard-fusion`. 16 commits across Phases 0–6n. Merged as PR #1 (squash).

---

## What worked well

- **Visual verification via Chrome MCP was essential.** At least five separate issues were invisible in code review and YAML lint but obvious the moment the dashboard rendered: `show_label: false` default (Phase 2), status-bar cells collapsing to 0 width in grid `auto` columns (Phase 2), row right-edge overflow past room card (Phase 6n), rows collapsing to content-width after `width: calc(...)` fix (Phase 6n), the 100px `hui-view-container` padding that explained the "too much left space" complaint (Phase 6l). None of these would have been caught by Gate 2 code review. Browser DOM inspection + screenshots belong in the deploy loop for every visual feature, not just as a one-off.
- **Cross-dashboard pattern lift (BubbleDash → FUSION Kiosk).** 6j used `kiosk_mode.hide_header: "{{ is_state(...) }}"` — the exact shape BubbleDash uses and Edgar had already confirmed worked on this instance. Worked first try. The earlier attempts in 6i using the documented `entity_settings` array never fired. **Principle**: when something in the HA plugin ecosystem has a "correct" documented shape and an "empirically working on this instance" shape, prefer the latter.
- **Gate 2 + gate3-plan-critic on Phase 0+1 was proportional.** Large novel feature → both reviewers engaged. Later cosmetic phases (6j–6n) were skipped through the gate pipeline — correct call, the spec says gates are for "non-trivial" changes and a padding-top bump doesn't qualify.
- **Full-dashboard edits via `python_transform` after the 40 KB inline-JSON limit.** `ha_config_set_dashboard(config=...)` has an implicit ~40 KB inline limit on this MCP. Once FUSION crossed ~50 KB, switching to `python_transform` with surgical key edits kept iteration tight. Used it ~10 times this session without corrupting state.
- **Measured-then-tuned alignment.** Home nav padding-top went 88 → 121 → 130 across three phases as the statusbar/KPI heights changed. Each was "measure the divider Y in Chrome, subtract icon height, set padding." No guessing — reproducible each time.

---

## What didn't work — rules proposed

### R1 🆕 — Document the `python_transform` sandbox forbidden-builtin list in one place.

**Observation**: hit `isinstance`, `type`, `hasattr`, `enumerate`, `list`, `str`, and `replace` as forbidden during this session, each costing a failed call + error parse + refactor. The sandbox is well-intended but the list of what's missing is only discoverable by failing against it. An earlier DECISIONS.md row (2026-04-24) captured `isinstance/type/hasattr/enumerate/list` — but I still hit `str()` (used for defensive `"statusbar" in str(x)`) and `string.replace()` in this session alone.

**Proposed rule**: append the complete observed-forbidden list to DECISIONS.md (or as a `# ⚠ python_transform gotchas` comment block in `fusion.yaml` / any future large dashboard file). List: `isinstance, type, hasattr, enumerate, list, str, dict, set, replace, open, def, class, try/except, import, __*__`. Pre-read before writing any non-trivial transform.

**Where to encode**: `00 - Agent Context/DECISIONS.md` — extend the 2026-04-24 python_transform row with the fuller list. Cheap, prevents rediscovery next dashboard session.

---

### R2 🆕 — `custom:layout-card` ignores `width:` on its internal wrapper; use `margin` for horizontal shift, wrapper padding for insets.

**Observation**: Phase 6l tried `margin: 0 0 0 -84px` + `width: calc(100% + 68px)` on the outer layout-card. Margin worked, width silently did nothing — the element still spanned full container width. Phase 6k had the same symptom with `width: calc(100% + 50px)` (deployed, no visual effect, Playing tile still truncated on the right). Eventually solved by using `margin: 0 16px 0 -84px` (margin on both sides) instead of trying to override width.

**Proposed rule**: for layout-card horizontal sizing, use left + right margins (they both work). Don't reach for `width: calc(...)` — it's silently ignored on the inner wrapper.

Same lesson in a different form: Phase 6n's `width: calc(100% - 20px)` on row button-card templates collapsed the rows to content-width because % resolved against a content-sized button-card host. Fix was to move the inset to the mod-card wrapper's `padding`, not the row's `width`.

**Where to encode**: `00 - Agent Context/DECISIONS.md` — new row on "layout-card + button-card width quirks: prefer margin on layout-card, wrapper padding on button-card."

---

### R3 🆕 — For cosmetic/tuning phases, batch-commit at session end, not per-tweak.

**Observation**: Phases 6j through 6n were five separate commits for what is essentially one coherent pass of "polish the dashboard per Edgar's feedback." Each commit had its own CHANGELOG entry, its own push, its own gate checklist. Squash-merge consolidated them, but during the session the commit overhead was real — ~30 seconds per commit × 5 commits. A single end-of-session commit with a summary CHANGELOG entry would have been cleaner.

**Proposed rule**: when work is iterative cosmetic tuning on a feature branch that will be squash-merged anyway, one commit at the end is enough. Reserve per-phase commits for milestones that could genuinely be reverted in isolation.

**Where to encode**: INSTRUCTIONS.md §Session hygiene or similar — one sentence: "On a feature branch destined for squash-merge, prefer one end-of-session commit over per-tweak commits when the tweaks don't independently warrant a revert point."

---

### R4 🆕 — Chrome MCP DOM walks should land the home-nav icon deterministically, not via fragile filters.

**Observation**: measured the home-nav icon Y position 4 times during this session. Each time my filter (`w > 30 && w < 80`, `icon === 'mdi:home-variant'`, `top > 150`) caught it or missed it unpredictably. In Phase 6n's final check, the filter matched `homeIconCenterY: 268` correctly on one try but returned `null` on the previous attempt with the same DOM.

**Proposed approach**: instead of scanning by icon attribute + size filters, target nav elements by their `view_layout` or a known container selector. Add a stable CSS class or `id` to the sidebar via card-mod — e.g. `.fusion-sidebar > .fusion-nav-icon`. Then `querySelector('.fusion-sidebar .fusion-nav-icon:first-child ha-icon')`.

**Where to encode**: this is a one-off hack for DOM inspection reliability — probably not worth an INSTRUCTIONS rule. Noting it here in case a future session does more Chrome DOM work; consider adding a named `id` on the sidebar mod-card.

---

### R5 🆕 — "Equal padding" is ambiguous — measure both "outer layout padding" and "visible content padding" before agreeing on a target.

**Observation**: Phase 6l spent several round-trips ending at "outer layout-card: 16px from panel edge on each side" which is symmetric at the layout level. But at the content level, sidebar icons have their own 10px internal margin and KPI tiles have 14px internal padding, so the visible left padding (panel edge to nav icon) is 26px and visible right padding (tile right to panel edge) is 30px. Not quite equal.

Edgar's follow-up in 6m acknowledged the layout-level symmetry was close enough, but an earlier clarifying question ("do you mean layout-edge equal or content-visible-edge equal?") would have saved one deploy cycle.

**Proposed rule**: when Edgar asks for "equal padding," clarify whether that's measured at the container edge or the visible-content edge before choosing a fix. Show a quick sketch or measurement of both.

**Where to encode**: no formal rule needed — a "habit" note in my own session playbook. Include this line in the retro so future sessions remember.

---

## Priority bumps to BACKLOG

- **BubbleDash v4 archival** — still on BACKLOG. After this session FUSION is the primary dashboard with all core flows working. Suggest 2 weeks of living on FUSION (catch any missing panels or rooms), then archive BubbleDash's YAML export + disable the dashboard. Don't delete the HACS deps it uses until FUSION is verified stable.
- **Bubble Card popups (Phase 4 original)** — move from "open enhancement" to explicitly **superseded**. Stacked-row design in 6d + button-shaped rows in 6m + green occupancy indicator in 6m give Edgar everything he asked for inline. Popups would now be *nice-to-have for slider controls* (light brightness, climate setpoint) — a different use case. Re-word the BACKLOG entry so future agents don't re-attempt the deprecated approach.
- **Kitchen scenes** (Morning Brew, Cooking Mode, Dinner Ambience, Cleaning Mode) — still blocked on scene definitions. This is a content task (create the scenes), not a dashboard task. Separate from FUSION polish, doesn't block anything.

---

## Context doc drift / gaps caught

- **BACKLOG's FUSION entry** — already self-maintained this session; ⚠️ items got flipped to ✅ as they were fixed. Good.
- **PROFILE.md** — got BQ16 network entities but didn't get the kitchen/office/entrance motion sensor entity IDs. Minor; next session can add when touching PROFILE.
- **DECISIONS.md** — 6 new rows this session, all load-bearing. Good density.
- **FUSION-DESIGN-SPEC.md** — was the anchor all session. Did NOT drift. The one exception was §4's card-mod-for-active-icon recommendation that we pivoted away from (documented in DECISIONS). Spec is still accurate for future reference.

---

## What Edgar should decide before closing this retro

1. **R1 (document python_transform forbidden list)** — accept? Extend DECISIONS.md row with the fuller observed list.
2. **R2 (layout-card + button-card width quirks)** — accept? New DECISIONS row capturing "use margin, not width."
3. **R3 (batch-commit on cosmetic iteration branches)** — accept? One line in INSTRUCTIONS.md.
4. **R5 (clarify "equal padding" before acting)** — no rule, just a note to self. Keep in retro only.
5. **Priority bumps** — move BubbleDash v4 archival to 🔴 for scheduling? Mark Bubble Card popups as superseded in BACKLOG?
6. **Merge the 6j-6n CHANGELOG entries into one consolidated "Phase 6 Polish" entry** — reduces CHANGELOG length, matches the squash-merge model. Or keep separate for granular history?

If Edgar accepts R1–R3, the main agent applies them in a follow-up commit (DECISIONS.md + INSTRUCTIONS.md) — no HA system changes, pure docs.
