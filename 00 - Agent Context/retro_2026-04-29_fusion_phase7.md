# FUSION Phase 7 — Retro

**Date**: 2026-04-29 (written end-of-day, after WP6 close-out + popup hotfix flap + revert)
**Span**: 2026-04-26 (WP1 start) → 2026-04-29 (WP6 deploy + revert) — ~3.5 calendar days, 4 calendar slots, 7 PRs
**Scope**: Six work packages — test harness + baseline (WP1), file restructure + YAML-mode dashboard registration (WP2), responsive grid migration (WP3), state-switch hybrid shell with bottom-tab nav (WP4), popup template + four room popups (WP5a-d), final wiring + nav-hide + cosmetic gaps (WP6 + hotfix revert).

**Outcome — what actually shipped**:
- ✅ Responsive shell — sidebar at ≥871px, bottom-tab nav at <871px (state-switch + entity:mediaquery, WP4)
- ✅ 9 fixed-grid panels migrated to `auto-fit minmax` (WP3) — 3 → 2 → 1 column collapse on phone
- ✅ Sidebar separator between Kitchen and Climate icons (WP6)
- ✅ Pulsing presence dot on the Edgar · Home indicator (WP6)
- ✅ Tap-action: navigate `#popup-<room>` on home-panel room headers for LR/Kitchen/Office/Outdoor (WP6)
- ✅ Bottom-tab `:host-context(body.bubble-body-scroll-locked)` nav-hide CSS rule (WP6) — currently inert, ready for future popup activation
- ✅ Test harness with 118 entries (vs 27 at WP1)
- 🟡 **Bubble Card popups — content authored, mount path doesn't work**. Four popup files in `config/dashboards/fusion/popups/{living-room,kitchen,office,outdoor}.yaml` exist with full entity manifests, six sections each (Header/Lights/Climate-or-Weather/Sensors/Scenes/Automations), 24h ApexCharts. Currently inert (`card_type: popup` is a Bubble Card no-op). Activation requires either restructuring the mount path or — Edgar's chosen path — adding via HA UI manually.

**Real-device verification sweep**: deferred to Edgar — Chrome MCP `hui-panel-view` harness blocker was load-bearing across WP5a/b/c/d/6.

---

## Honest scoreboard: claimed vs delivered

This is the load-bearing section of the retro. Each WP's STATUS.md tick was earned at deploy time; the popup flap revealed that "deployed and ha_check_config valid" is not the same as "users can use the feature." Below is the reconciliation.

| WP | Claimed | Delivered | Gap |
|----|---------|-----------|-----|
| WP1 | Test harness + 27 baseline tests | ✅ As claimed | None |
| WP2 | File restructure + YAML mode | ✅ As claimed | None |
| WP3 | 9 grids → auto-fit minmax | ✅ As claimed | Phone-side collapse verified hands-on by Edgar 2026-04-27 |
| WP4 | State-switch hybrid shell, sidebar/bottom-tab | ✅ As claimed | Hands-on iPhone verification deferred — still pending |
| WP5a | Popup template + Living Room popup | 🟡 Server-side: 17/17 tests "passing" (mostly `baseline_known_failure`). **Reality: popup never opened due to `card_type: popup` registry typo. ha_check_config is opaque to this.** | Popup never opened end-to-end. Bug latent for 2 days. |
| WP5b | Kitchen popup | 🟡 Same as WP5a — popup never opened | Same |
| WP5c | Office popup | 🟡 Same — plus the WP5c-deploy-stomp incident on 2026-04-29 morning | Same |
| WP5d | Outdoor popup | 🟡 Same | Same |
| WP6 | Tap_action wiring + nav-hide + sidebar separator + pulsing dot | ✅ Tap_actions, separator, dot all working. Nav-hide CSS rule correct but inert (popups not activating). **Hotfix → revert flap surfaced the real popup-mount problem.** | Popups still don't open in YAML mode |

The "deployed" signal turned out to be over-confident across the popup series. Five WPs all returned "Gate 3 ✅" with `ha_check_config` green and `lovelace/config` returning structurally-valid YAML, while no popup actually opened on the user's screen at any point. The signal that finally surfaced the bug was Edgar opening it on his phone after WP6 merged — not any test, not any reviewer round, not any deploy verification step.

---

## What worked

### Parallel-session model with the worktree HARD RULE

After the WP5a session-stash collisions on 2026-04-27 (three sessions sharing the same working tree, branches checked out sequentially evicting each other's unstaged work), the COORDINATION.md HARD RULE for `git worktree add` was the single highest-leverage process change. Slot 2 (WP3 + WP4 + WP5a) and Slot 3 (WP5b + WP5c + WP5d) ran without filesystem-level interference because each session opened in its own worktree path. Branch isolation alone would have been not enough.

**Promote to permanent rule**: any future multi-WP project (Phase 8+, larger refactors) inherits this without re-arguing it.

### Test-Driven Design with `baseline_known_failure`

Writing tests first — and accepting that every WP's new tests start as `baseline_known_failure` — kept the work honest about what "done" means within the WP. The status is a durable promise: when the WP closes and the test target works, the status flips to `baseline`.

Test count grew honestly: 27 (WP1) → 36 (WP2) → 49 (WP3) → 65 (WP4) → 82 (WP5a) → 92 (WP5b) → 103 (WP5d) → 118 (WP6).

### `ha-code-reviewer` Gate 2 caught real defects

Across the 6 WPs, the reviewer caught (non-exhaustive):
- WP4 round 1: missing `default:` semantics in state-switch (must be a state-name string, not a card definition); `position: fixed` descendants escape state-switch grid hide
- WP5a round 1: missing `!include` line for living-room popup in shell.yaml
- WP5b: stale `fusion-tests.md` per-category counts table (caught at WP5b, finally fixed at WP6)
- WP6: dashboard-YAML `Gate 2 reviewed:` marker convention drift; `:host-context()` Safari caveat; defensive `person.edgar` guard suggestion

These were not all blocking findings, but each one improved the merged version. The `MODE: code-review` half of `ha-code-reviewer` earned its keep.

What the reviewer **did not** catch (and could not, given its read-only inputs): the `card_type: popup` registry typo at WP5a — the value is opaque to YAML schema validation, and verifying it would have required cross-referencing the bundled HACS card source. The reviewer's input contract is text; this needed bytecode introspection.

### Verbatim-relocation contract for WP2

WP2's contract — "every byte of the dashboard YAML must move 1:1 into the new file structure, no behaviour change" — was verifiable by structural fingerprint (TEST-101 / TEST-102 / TEST-103). When WP2 deployed, the harness-reachable fingerprints matched WP1's exactly. This bought a clean foundation for WP3-WP6 to layer changes on top without losing the ability to bisect "did WP2 introduce this drift?"

### YAML-mode pivot at WP2

The 2026-04-27 decision to flip FUSION to YAML-mode (file → commit → SCP → restart) was ultimately right — the `python_transform` round-trip discovered ~10 sandbox-forbidden builtins over two sessions and one mirror-back-to-local drift incident before YAML mode locked it down. Worth the one-restart-per-merge cost.

### Manifest header on each popup file

Each room popup file ships with a comment block listing every entity it references, why it's in scope (or excluded), and the rendering contract. When the popups eventually ship for real (UI-managed, per Edgar's plan), the manifests are direct content for porting. Even if the YAML-mode mount path was wrong, the manifests are durable artifacts.

---

## What broke (and what we'd change)

### The popup `card_type` typo + mount-geometry bug (the Phase 7 lesson)

**Chronology** (the hard part to capture honestly):
- 2026-04-27 (WP5a): popup template authored with `card_type: popup` (un-hyphenated). Brief said this; pattern doc copied it; `_template.yaml` enshrined it; living-room.yaml used it. **Latent bug #1 introduced.**
- 2026-04-28 / 2026-04-29 (WP5b/c/d): the three remaining popups copied `_template.yaml` verbatim. Latent bug #1 propagated to 4 popup files.
- 2026-04-29 morning (slot-3 verification): server-side checks confirmed `lovelace/config` returns `card_type: popup` correctly. No popup ever opened end-to-end. WS-level checks looked green. Browser tests deferred.
- 2026-04-29 afternoon (WP6 deploy): tap_actions added, nav-hide CSS rule added (referencing `bubble-popup-open` per the brief — also wrong, see below).
- 2026-04-29 evening (WP6 hotfix-1): I decompressed `bubble-card.js.gz` while wiring nav-hide, found that the actual body-class is `bubble-body-scroll-locked` (not `bubble-popup-open`). Fixed `_template.yaml` + the WP6 nav-hide CSS to use the correct class. Did NOT think to check `card_type` — the registry pattern wasn't surfaced yet.
- 2026-04-29 evening (Edgar real-device test #1): "the popups don't open." Diagnostic: `setConfig` runs, outer `<ha-card>` shell renders, `updateBubbleCard()` looks up `Zt["popup"]` which is undefined, so the popup-wrapper builder is a no-op. Found `card_type: "pop-up"` is the actual registry key. **Bug #1 fixed**: 5 files, one-character change.
- 2026-04-29 evening (Edgar real-device test #2): popups now open. **But render the entire FUSION shell inside the popup overlay** — Bubble Card popups, when mounted as siblings of dashboard content in a vertical-stack inside a panel-mode mod-card, adopt the dashboard's vertical-stack siblings as the popup's children. **Bug #2 surfaces** — mount geometry is wrong. Reverted Bug #1 fix back to the inert form so the dashboard renders normally. Edgar will UI-add real popups separately.

**Two distinct bugs** — both introduced at WP5a and propagated through WP5b/c/d untouched:
1. **`card_type: popup` is a Bubble Card no-op** because the source registers `pop-up` (hyphenated). Verifiable by decompressing `bubble-card.js.gz` and grepping the registry key. Brief used the un-hyphenated form; YAML schema can't catch it; `ha_check_config` is opaque to it; lovelace/config WS message returns it verbatim.
2. **Mount geometry**: even with `card_type: pop-up` correct, popups mounted as siblings of dashboard content in a panel-mode mod-card stuff the dashboard inside the popup overlay. Discovered only by activating the popup with bug #1 fixed.

**Why neither bug surfaced for ~2-3 days**:
- Browser-side popup-open tests have been deferred to "Edgar's real-device pass" since WP5a, because Chrome MCP's `hui-panel-view` harness blocker prevented any popup from opening in the harness on this macOS host.
- That deferral is a real harness limitation, not a discipline failure — the harness genuinely cannot reach the popup-open state at <606px effective viewport.
- BUT: the deferral became compound interest. WP5a → WP5b → WP5c → WP5d → WP6 each marked their popup tests `baseline_known_failure` and shipped. Five WPs of accumulated deferred verification.

**What we'd change**:

1. **Run real-device verification at the END of every popup WP, not deferred to phase close.** Block the merge of any popup WP until Edgar confirms the popup opens end-to-end on his phone or desktop browser. This is one round-trip per WP and would have caught bug #1 at WP5a (1 day of wasted work prevented). The cost is real (Edgar's time, asynchronous gate) but the alternative is what we just lived through.

2. **For HACS cards with non-trivial DOM mutation (popups, slide-overs, modals), introspect the bundled JS during Gate 1.** When a brief says "use `card_type: X`" or "the body class is `Y`", grep the bundled source — or at minimum the README and changelog — to verify the claim. The brief is allowed to be wrong; YAML-time validation cannot catch a wrong opaque-string field. Add this to the research-advisor's checklist for any new HACS card class.

3. **Bubble Card popup mount path is now documented as "doesn't work in panel-mode + nested in vertical-stack as sibling".** Future popup work in FUSION must mount popups via UI (storage-mode dashboard or ad-hoc), or via a different YAML structure that gives the popup a top-level mount. DECISIONS 2026-04-29 captures this; do not re-discover.

### The WP5c-deploy-stomp incident (2026-04-29 morning)

**What happened.** Slot-2 verification found the deployed dashboard rendering an empty body. Root cause: HA Green's `/config/dashboards/fusion/` was desynchronised from `main` — `shell.yaml` had two popup includes (one valid, one rogue from an unmerged branch) and one of the two referenced popup files was missing from disk. Fix took ~30 minutes of `git archive main config/dashboards/fusion/` + per-file md5 diff + targeted SCP recovery.

**Two surface causes:**
1. **`deploy.sh` doesn't handle `config/dashboards/`.** Only handles `config/packages/*.yaml`. Dashboard files have to be SCPed manually, and the manual flow makes it easy to leave HA in a partial state during multi-session work.
2. **Lovelace `!include` resolution is lazy.** `ha core check` doesn't catch a missing popup include (the `!include` resolves at request time, not config-load time), so the deploy "succeeded" structurally even with a broken include.

**Fix forward (BACKLOG):** extend `deploy.sh` (or add `deploy-dashboard.sh`) that refuses partial syncs / orphan files and runs a "full include resolution" check before declaring the deploy clean. Surfaced in BACKLOG.

### Bubble Card body-class fingerprint drift across WP5a/b/d tests

**What happened.** The WP6 brief's "hook Bubble Card's `bubble-popup-open` body class" was wrong — the actual class is `bubble-body-scroll-locked`. WP6 caught it by decompressing `bubble-card.js.gz` and grepping for body-classList ops. WP5a/b/d's tests TEST-403, TEST-432, TEST-452 inherited the brief's wrong class name and now look for `bubble-popup-open` which never gets set.

**Root cause.** Same pattern as the `card_type` typo — no earlier WP had a reason to verify the body-class assumption against source until WP6 needed the class for the nav-hide CSS rule.

**Fix forward (BACKLOG, doc-only PR).** Update TEST-403, TEST-432, TEST-452 to use `bubble-body-scroll-locked`. Already fixed `_template.yaml` reference comment in WP6.

### Chrome MCP `hui-panel-view` chunk-load harness blocker

**What happened.** From WP5b onward, the Chrome MCP harness on the macOS host could not reliably load the `hui-panel-view` chunk for the FUSION dashboard URL. Sometimes a window resize kicked it into rendering; usually the screen stayed black. Edgar's real device renders the dashboard fine (verified multiple times), so this is harness-specific.

**Surprising.** Sometimes the panel kicks into rendering after a navigation+wait, and sometimes after a resize. Not reliable enough to base test verification on. WP6's harness sessions had at least 3 cycles of "render works → render breaks → render works" without any YAML changes between them.

**Fix forward (no change, just documented).** Each affected test stays `baseline_known_failure` until Edgar's real-device sweep flips it. Phase 8+ should consider whether a phone-emulation harness (DevTools mobile mode via Chrome MCP, or a real iOS device with remote debug) is worth standing up. The cost of the current deferral is real (the popup `card_type` bug went latent for 2-3 days because of it), so this isn't a "nice to have."

### Branch-context drift across long-lived feature branches

**What happened.** A few WPs (WP5a, WP5c) had multi-day gaps between "Gate 2 APPROVED" and "deployed + verified", during which `main` advanced. Rebasing those branches onto the new `main` was always clean (the WPs touched orthogonal files), but the agent's mental model of "is my branch up-to-date?" had to be re-established every session-start.

**Mitigation already in place.** The slot-3 verification session (2026-04-29 morning) caught + fixed the WP5c-deploy-stomp before WP6 started. The session-start `git pull origin main` + `git status` discipline proves load-bearing.

**Fix forward.** No change needed.

### `templates.yaml` `popup_row` duplicate-keys silent bug

**What happened.** Lines 218-280 of `templates.yaml` define the `popup_row` button-card template with TWO `styles:` blocks — `card`, `icon`, `name`, `grid` keys appear twice. YAML last-wins gives bottom-tab styling for active popup_rows, which means the popup_row template's intended row visual ("horizontal `i n` row") is being overridden by a different shape ("small centered chip"). WP5b shipped with this; WP5d and WP6 inherited it. Empty-state rows that override styles inline still render correctly.

**Why it didn't matter (yet)**: popups never opened, so `popup_row` was never rendered in the popup context. When Edgar UI-adds the popups and ports the row content, this should be cleaned up first.

**Fix forward (BACKLOG).** Focused refactor PR after Phase 7 retro cooldown.

---

## Work-package coordination — what cracked under load

The first part of this retro covered "what worked / what broke" inside individual WPs. This section covers **how the WPs interacted with each other** — the layer where most of the pain was. Capturing this is the most useful artifact for the next multi-WP project (Phase 8+).

### Issue 1: WP boundaries didn't map to logical units of work

**WP5a, WP5b, WP5c, WP5d were "same task × 4 rooms," not 4 independent WPs.** Each of WP5b/c/d added one popup YAML file (~300 lines) and one `!include` line in shell.yaml. The popup template was defined in WP5a and copy-pasted 3× verbatim per the popup-pattern recipe. WP5b/c/d could not start until WP5a merged (so the template was stable) — they ran in parallel but had identical structural shape.

**Cost of the split:**
- 4× Gate 2 reviews instead of 1 (token + reviewer time)
- 4× CHANGELOG / STATUS / PR overhead per popup
- 4× rebase-onto-main passes when WP5a merged
- 4× deploy passes (each session SCPing its own popup file plus a one-line shell.yaml edit)
- Repeated discovery of the same wrong assumptions in each WP (the `card_type: popup` registry typo and `bubble-popup-open` body-class typo were both inherited verbatim from WP5a — neither WP5b/c/d had the budget to question the inherited contract)

**What drove the split** (in retrospect, not all of these were good reasons):
- **Capacity / parallelism**: three parallel Claude sessions could each take one popup. Reasonable in isolation but not load-bearing — the popups were tiny and could have been done sequentially in one session in less wall-clock time.
- **Risk isolation**: a botched popup wouldn't block the others. True, but the actual risk was in the shared template (`_template.yaml`), not the per-room content.
- **Backlog hygiene**: each room maps to a distinct dashboard panel, making each popup feel like its own unit. Cosmetic — the popups have ~80% identical structure.

**Better split for next time**:

| Phase 7 actual | Better |
|----------------|--------|
| WP5a (template + LR), WP5b (Kitchen), WP5c (Office), WP5d (Outdoor) | Single "WP5 — popup template + 4 room popups" with a per-room TODO list inside it |
| WP3 (grids) + WP4 (shell) as separate WPs | Possibly mergeable — both target responsive viewport behaviour, both touch shell.yaml. WP4 was big enough to stand alone, but the boundary was arbitrary. |

**Rule of thumb for Phase 8+**: only split into separate WPs when the dependencies between them are real (downstream WP genuinely needs upstream WP merged) AND the work units are large enough to justify the overhead (~200+ lines of new YAML, or a non-trivial config change). "Same task × N rooms / panels / entities" should be one WP with an internal checklist, not N WPs.

### Issue 2: `shell.yaml` was a multi-WP hot-spot

**Six WPs touched `shell.yaml` in Phase 7** — WP4 (full rewrite to add state-switch hybrid), WP5a (added LR popup `!include`), WP5b (added Kitchen `!include`), WP5c (added Office `!include`), WP5d (added Outdoor `!include`), WP6 (sidebar separator + bottom-nav-hide CSS + person-card extra_styles).

Every popup WP had a one-line edit in shell.yaml that was structurally a merge conflict waiting to happen. Three of them ran in parallel (Slot 3). The way we worked around it:

- **WP5b's session SCP'd its own kitchen.yaml + `sed -i` injected the kitchen `!include` into HA Green's shell.yaml directly** (sidestepping the local-shell.yaml-vs-other-sessions question).
- **WP5c committed + deployed locally on its branch but didn't merge until WP5b had merged**, then rebased and merged. This worked but is the "deploy ahead of merge" anti-pattern.
- **WP5d redeployed `office.yaml` because HA Green was missing it** (lingering effect of the WP5c-deploy-stomp incident — see Issue 4 below). Out-of-scope but necessary for safety.

**Why this is a problem.** Every parallel session that needed to add an `!include` was waiting on the same file. The HARD RULE of one-worktree-per-session prevented filesystem clobbering, but the *logical* contention on shell.yaml's content was unresolved. The same shape will hit any future Phase that has multiple WPs adding lines to the same shared file.

**Better patterns**:

1. **`!include_dir_*` for the popup includes**: WP5a considered and rejected this (DECISIONS 2026-04-27 — "explicit ordering, downstream-WP-friendly"). In retrospect, with 4 parallel popup WPs and the deploy-stomp risk, `!include_dir_list popups/` would have eliminated the per-WP shell.yaml edit entirely. Each popup WP would just drop a file in `popups/`; HA's loader would pick them up. Cost: lose explicit ordering. Benefit: zero shared-file contention. Worth re-evaluating for Phase 8+.

2. **Designate a single WP as the "shell-edit owner" per slot**, with downstream WPs handing their shell.yaml edits to it. Coordinator overhead but no merge conflicts. Awkward in agent-driven workflows.

3. **Make shell.yaml itself smaller** — extract include-list-only sections into their own files. `panels.yaml` (panel includes), `popups.yaml` (popup includes), `nav.yaml` (sidebar nav cards). Each multi-WP edit lands in a smaller, tighter file.

### Issue 3: Brief vs reality drift

The WPN-*.md briefs were authored upfront (WP1 era) and didn't update as reality landed. Three concrete drifts:

1. **WP5a brief said `card_type: popup`** — wrong (registry uses `pop-up`). Propagated through all 4 popup files.
2. **WP6 brief said body class is `bubble-popup-open`** — wrong (actual class is `bubble-body-scroll-locked`). Propagated into WP5a/b/d test fixtures (TEST-403, TEST-432, TEST-452).
3. **WP5a brief said "Do not touch shell.yaml"** — but the popup wiring requires a shell.yaml `!include`. Edgar overrode in chat for WP5a; WP5b/c/d's sessions inherited the override implicitly. The brief's scope rule was wrong AND the override pattern was undocumented across WPs.

**The brief was a snapshot of intent, not a contract that survived contact with reality.** This is normal for upfront planning, but in a 6-WP phase with parallel sessions, brief drift compounds. Each WP that copies a wrong assumption from its brief carries that assumption forward.

**Fix forward**:

- **Brief-vs-implementation reconciliation between WPs.** When WP5a finishes and learns "the brief was wrong about X", update the WP5b/c/d briefs in the same PR before they start. This costs 5-10 min of doc work but prevents cascading errors.
- **"Brief is provisional" marker on every WP brief**, with a "drift log" section the implementing WP fills in at completion. Forces the explicit reconciliation.
- **For HACS-card-API claims (DOM mutation, registry keys, body classes), Gate 1's research-advisor should grep the bundled card source** before sign-off. The brief is allowed to be wrong; verification should not be downstream of the brief.

### Issue 4: WP5c-deploy-stomp incident — the "deploy ahead of merge" anti-pattern

**What happened**, abbreviated (full chronology in the original retro section above):
- WP5c's session committed `office.yaml` + shell.yaml `!include` on its branch (`phase7/wp5c-office`) and deployed to HA Green on 2026-04-28.
- WP5c's PR #13 was NOT yet merged to main — it sat open while Slot-3 verification ran.
- Meanwhile, WP5b's session was running in parallel and made its own shell.yaml edits.
- Result: HA Green's shell.yaml referenced both `living-room.yaml` (legitimate, from WP5a) AND `office.yaml` (deployed but not merged). One of the two files (`living-room.yaml`) was actually missing from disk because WP5a's deploy never ran end-to-end.
- Slot-2 verification on 2026-04-29 morning found the dashboard rendering an empty body. ~30 minutes of `git archive main config/dashboards/fusion/` + per-file md5 diff to recover.

**The anti-pattern**: deploying to HA Green from a branch that hasn't merged to main yet. The HA filesystem becomes a stateful surface that can drift from `main` independently. With multiple parallel sessions doing this, the drift compounds.

**Why it happened**: each WP's Gate 3 pipeline goes "validate → deploy → verify". Edgar's standard workflow merges the PR after Gate 3 verifies. So there's always a gap between "deployed" and "merged to main". Normally this gap is short (Gate 3 → merge in the same session). But in the parallel-session WP5 model, three sessions had simultaneous open Gate-3-deployed-but-not-merged states.

**Fix forward**:

- **Codify "deploy = merge ready"**: only deploy to HA Green from a branch that's about to merge in the same session. If Gate 3 verifies but the PR is going to sit open for any non-trivial duration, **roll back the deploy** and re-deploy after the merge. The branch's HA-Green-side artifact is ephemeral.
- **Or, less radical**: a `deploy.sh --dashboard` flag that records "deployed-from-branch-X" metadata, and a session-start health check that warns when HA Green's dashboard tree doesn't match `main`. Auto-detect drift instead of rediscovering it via "the dashboard is empty."
- **The right structural fix is Issue 2's pattern #1** — `!include_dir_*` would eliminate the cross-WP shell.yaml edit, which would eliminate the deploy-stomp risk class entirely.

### Issue 5: Merging-without-real-device-verification compounded across WPs

**What happened**: PR #11 (WP4) merged before Edgar's iPhone hands-on verification. PR #9 (WP5a), #14 (WP5b), #13 (WP5c), #15 (WP5d) all merged the same way. STATUS.md flipped to ✅ for each of them based on server-side checks (`ha_check_config`, `lovelace/config` shape, structural fingerprint tests). None of those signals would have caught the popup `card_type` typo or the mount-geometry bug — both were render-time runtime issues that only surface when a real human opens the dashboard on a real device.

**The deferral chain**:
- WP4 merge: "iPhone hands-on deferred — does NOT block downstream WPs"
- WP5a merge: "browser-side hash test deferred (harness blocker) — pending Slot-2 re-verify"
- WP5b merge: "browser-side hash test deferred — same harness blocker"
- WP5c merge: "browser hash-test pending Edgar's real-device verification"
- WP5d merge: "browser-side hash test deferred"
- WP6 merge: "real-device verification sweep deferred to Edgar"

Six consecutive WPs each shipped with a deferral. The deferrals compounded into a 3-day latent window during which both popup bugs lived undetected on `main`.

**Fix forward**:

- **Gate 4 — real-device verification — between Gate 3 and merge**, for any WP whose Gate 3 ends with "browser-side test deferred." Cost: Edgar's eyeballs for 5-10 min per WP, asynchronous. Benefit: stops the deferral chain at the WP boundary instead of letting it accumulate.
- **STATUS.md should distinguish "deployed (server-side green)" from "user-verified (real device green)"** — single ✅ hides this distinction. Phase 7 had nine entries that conflated them. Suggested format: `- [x] WPN — ✅ deployed YYYY-MM-DD — 🟡 real-device pending` or `- [x] WPN — ✅ deployed + verified YYYY-MM-DD`. Two checkboxes, two truths.
- **Hard rule for popup-class work**: no popup WP merges until `location.hash = '#popup-X'` opens the popup on Edgar's screen. The harness blocker is real but it cannot become an excuse to ship un-verified popup behaviour.

### Issue 6: `fusion-tests.md` category-counts table was stale across multiple WPs

Every popup WP from WP5b onward edited `fusion-tests.md` (added new TEST-43X / TEST-44X / TEST-45X entries). The per-category breakdown table at the bottom of the file was last correct at WP4 + WP5a; from WP5b onward, every WP wrote new test totals that didn't match reality. The reviewer caught this at WP5b ("stale category-counts table") but it stayed wrong until WP6 finally refreshed it.

**Why it stayed broken**: each WP added new tests but didn't have its own breakdown table refresh in scope. The table is global (sums across all WPs) but each WP's diff is local. Nobody owned the global rollup.

**Fix forward**: every WP that touches `fusion-tests.md` MUST refresh the category-counts table. Cheap, mechanical, prevents cumulative drift. Add to the WP brief checklist.

### Issue 7: Inter-session stash-pile coordination

WP5b's session noted (CHANGELOG 2026-04-29): "Started on `phase7/wp5d-outdoor` due to a parallel WP5d session leaving a draft in the same working tree. Stashed WP5d's WIP under `WP5d-outdoor-WIP-preserved-by-WP5b-session-2026-04-28` so the parallel session can `git stash pop` it cleanly."

This was after the COORDINATION.md HARD RULE for worktrees was added. So even with the rule, sessions were still observing each other's WIP. The HARD RULE was added 2026-04-27; this entry is dated 2026-04-29. Either the rule was violated, or the rule + worktree weren't enough.

**Likely explanation**: the worktree path for WP5b was set up correctly, but the agent's session start observed a stash from a previous WP5d session that had run in the SAME WP5b directory. Stash entries are not worktree-scoped by default (they live in the shared `.git` repo). So the stash was "leaked" across worktrees.

**Fix forward** (small):
- Document in COORDINATION.md that `git stash` is shared across worktrees.
- Each session's start should run `git stash list` and report any stashes that aren't its own. Don't auto-pop.
- Better: each session names stashes with a session-specific prefix so cross-session stashes are obvious.

### Summary table — coordination issues + recommended fixes

| # | Issue | Fix priority | Cost to fix |
|---|-------|--------------|-------------|
| 1 | WP boundaries didn't match logical units (4 WPs for "1 template + 4 popups") | High | Brief authoring discipline — write fewer, larger WPs |
| 2 | `shell.yaml` as multi-WP hot-spot, every popup WP added a line | High | `!include_dir_*` for collection includes, OR designated shell-owner WP, OR smaller shell files |
| 3 | Brief-vs-implementation drift across WPs | High | "Brief is provisional" + drift-log + Gate 1 source-introspection for HACS card claims |
| 4 | Deploy-ahead-of-merge anti-pattern → WP5c-deploy-stomp | High | "Deploy = merge-ready" rule, OR drift-detection at session start |
| 5 | Merge-without-real-device-verification compounded across 6 WPs | High | Gate 4 (real-device) before merge, OR two-checkbox STATUS.md |
| 6 | `fusion-tests.md` category-counts table stale across multiple WPs | Medium | Per-WP discipline: every test edit refreshes the rollup |
| 7 | Cross-session stash-pile leakage despite worktree HARD RULE | Low | Document that stashes are repo-scoped not worktree-scoped + naming convention |

---

## Process improvements adopted mid-stream (keep these)

- **COORDINATION.md HARD RULE for parallel sessions** (added 2026-04-27 after WP5a stash collisions).
- **Verbatim-relocation contract for relocation-only WPs** (codified at WP2).
- **Manifest header on each popup file** (every reference entity, why in/excluded, contract).
- **Per-WP `# Gate 2 reviewed:` markers on dashboard YAMLs, layered (append-on-edit)** (codified in DECISIONS 2026-04-29 during WP6).
- **`baseline_known_failure` test status** (durable promise, surfaces when a test should pass but can't be verified yet).

## Process gap that bit us (fix)

- **Real-device verification gate per popup WP** (NEW, must add for Phase 8+ if popups recur).
- **HACS card source-introspection in Gate 1** (NEW, for any non-trivial HACS card claim).

---

## Phase 7 follow-ups (tracked in BACKLOG, prioritised)

| # | Item | Priority | Why |
|---|------|----------|-----|
| 1 | UI-add Bubble Card popups (Edgar's hand) | High | The user-facing popup feature still doesn't ship — YAML files are reference content only. |
| 2 | Real-device verification sweep on Edgar's iPhone + desktop browser | High | Flips TEST-007, 008, 305..311, 400..416, 430..439, 450..460, 500..514 from `baseline_known_failure` → `baseline`. Capture canonical screenshots at 4 viewports × (popup closed/open) under `screenshots/final/`. |
| 3 | Doc-only PR: fix WP5a/b/d test class-name fingerprint (`bubble-popup-open` → `bubble-body-scroll-locked`) | Medium | Blocks the real-device sweep for those tests. |
| 4 | `templates.yaml` `popup_row` duplicate-keys refactor | Medium | Once UI-popups land, `popup_row` becomes load-bearing. Today it's silently broken. |
| 5 | `deploy.sh` extension for `config/dashboards/` (refuse partial syncs / orphan files) | Medium | Would have caught WP5c-deploy-stomp. |
| 6 | Phone-emulation harness investigation (DevTools mobile mode via Chrome MCP, or real iOS device remote debug) | Medium | Current deferral compounded into a 3-day latent bug; this is the structural fix. |
| 7 | Safari/WebKit `MutationObserver` fallback for `:host-context()` body-class hooks | Low | Informational only; Chrome kiosk is the canonical target. |
| 8 | `# Gate 2 reviewed:` codification for dashboard YAMLs in DECISIONS | Low | Already added 2026-04-29; just confirm the convention sticks. |
| 9 | `person.edgar` defensive `unavailable` guard (and edphone/ipad for symmetry) | Low | Resilience polish. |

---

## Numbers

| Metric | WP1 baseline | Phase 7 close (WP6 + revert) |
|--------|-------------|------------------------------|
| Test count | 27 | 118 |
| Dashboard files | 1 monolith (`fusion.yaml`, ~1731 lines) | 14 files (entry + shell + statusbar + templates + 7 panels + 4 popups + 1 popup template) |
| Responsive viewports verified | 1 (1280) | 3 effective (1280, 900, ~700 effective via macOS Chrome) + real-device sweep pending for 700 + 375 |
| Bubble Card popups | 0 | 0 working popups (4 popup files exist as reference content, awaiting UI-add) |
| Sidebar nav cells | 8 (7 panels + kiosk) | 9 (7 panels + separator + kiosk) |
| Pulsing-dot indicators | 0 | 1 (rendered in 2 DOM positions, both shell branches in DOM by state-switch) |
| Open `baseline_known_failure` post-real-device-sweep target | 2 (WP1 sidebar tests) | 5 (permanent harness-limit known-failures) |
| PRs merged | 7 (PR #6, #7, #8, #9, #10, #11, #13, #14, #15, #16 — 10 actually) | (Including the WP6 hotfix flap inside #16) |
| Latent bugs surfaced post-merge | 0 | 2 (`card_type: popup` typo, popup mount-geometry mismatch) |

---

## Recommendations for Phase 8+

These are ranked by leverage — top of the list = biggest improvement per unit of process change.

1. **Author fewer, larger WPs. Match WP boundaries to logical units of work, not to parallel-session capacity.** The "WP5a/b/c/d × 4 rooms" split cost 4× the overhead with no real risk-isolation benefit. A single "WP5 — popup template + 4 room popups" with an internal per-room checklist would have been faster, would have surfaced the brief-drift bugs in one place instead of four, and would have eliminated the shell.yaml multi-WP hot-spot. **Rule of thumb**: only split when downstream WP genuinely depends on upstream merge, AND each piece is ≥200 lines of new content or a non-trivial structural change. "Same task × N entities" is one WP.

2. **Real-device verification (Gate 4) per WP for any user-facing surface, not deferred to phase close.** The deferral chain across 6 WPs was the single biggest cause of the 3-day latent-bug window. ~5 min of your time per WP, asynchronous. Stops compounding. Add to the standard workflow: **Gate 1 → 2 → 3 → 4 (real-device) → merge.** For popup-class work specifically: hard rule, no merge until `location.hash = '#popup-X'` opens the popup on a real device.

3. **Two-checkbox STATUS.md format**: distinguish "deployed (server-side green, ha_check_config passes)" from "user-verified (Edgar opened it on a real device and confirmed)." Phase 7 had nine entries that conflated these. Suggested: `- [x] WPN — ✅ deployed YYYY-MM-DD — 🟡 real-device pending` until both are true. Single ✅ should require BOTH.

4. **For HACS cards with DOM-mutating behaviour (popups, slide-overs, modals), introspect the bundled JS source before shipping.** Twice this phase, a brief-level claim about a HACS card's API was wrong (`card_type: popup` vs `pop-up`; body class `bubble-popup-open` vs `bubble-body-scroll-locked`). Each cost a multi-day latent bug window. The fix: at Gate 1, decompress the bundled card JS and grep the registry / classList ops for any claim the brief makes. ~5 min of agent work; stops a whole class of bug. Add to the research-advisor's checklist.

5. **Parallel sessions: keep the worktree HARD RULE.** It earned its place. Don't soften to "branch-only" for "small" WPs. Plus one addition: stashes are repo-scoped, not worktree-scoped — sessions should report any cross-session stashes at start without auto-popping.

6. **Brief is provisional; reconcile drift between WPs.** When WP5a learns "the brief was wrong about X", update WP5b/c/d's briefs in the same PR before they start. Cost: 5-10 min per drift. Benefit: prevents cascading. Add a "Drift log" section to every WP brief that the implementing WP fills in at completion.

7. **`shell.yaml` (or any shared file) is a multi-WP attractor.** Two structural fixes for Phase 8+: (a) `!include_dir_list` for collection-includes (e.g. popups dir auto-includes everything in it — eliminates per-WP `!include` lines and the deploy-stomp risk class entirely); (b) split shared files into smaller, ownership-tighter pieces (panels.yaml, popups.yaml, nav.yaml — each gets one designated owner-WP). Do one or both; the as-is shape will hit again.

8. **"Deploy = merge-ready" rule.** Only deploy from a branch about to merge in the same session. If Gate 3 verifies but the PR will sit open for any non-trivial duration, roll back the deploy. The branch's HA-Green-side artifact is ephemeral. Or: instrument `deploy.sh` to record "deployed-from-branch-X" and detect drift at session start.

9. **`deploy.sh --dashboard` flag** (or separate `deploy-dashboard.sh`): refuses partial syncs / orphan files, runs include-resolution check, would have caught WP5c-deploy-stomp. Phase 7's main deploy.sh handles `config/packages/*.yaml` only. Same shape will hit any future YAML-mode dashboard work.

10. **Phone-emulation harness investigation.** Chrome MCP on macOS bottoms out at ~526px effective. iOS Safari + Web Inspector remote debug, OR DevTools mobile-mode via Chrome MCP, would close the verification loop. The cost of NOT having this in Phase 7 was the popup-bug latent window.

11. **`baseline_known_failure` convention stays, with a hygiene rule.** When a WP's `baseline_known_failure` count exceeds 3, require a real-device round-trip before merge. Don't let it compound across WPs.

12. **Per-WP discipline: every WP that touches `fusion-tests.md` refreshes the category-counts table.** Cheap, mechanical, prevents cumulative drift. Add to the WP brief checklist.

13. **Keep retros candid.** This retro is the longest in the project because it includes the popup flap and the coordination layer honestly. Future retros should match that bar — capture what shipped vs what was claimed, the bug chronology, AND the inter-WP coordination friction (not just per-WP discipline). The cross-WP layer is where Phase 7's biggest losses lived.

---

## What Phase 7 actually delivered (one-paragraph version, for the next session-start agent reading CHANGELOG)

A responsive shell (sidebar/bottom-tab swap at 871px), nine grids migrated to `auto-fit minmax`, sidebar separator + pulsing presence dot polish, room-row `tap_action: navigate` wires to `#popup-<room>` hashes, and a `:host-context(body.bubble-body-scroll-locked)` nav-hide CSS rule. **The Bubble Card popups themselves don't work in YAML mode** — `card_type: popup` is a no-op (registry uses `pop-up`) and the correct hyphenated form has a mount-geometry mismatch when nested inside the panel-mode shell. Edgar will UI-add real popups separately; the four popup YAML files in `config/dashboards/fusion/popups/` are reference content (entity manifests, sections, ApexCharts configs, FUSION dark theme) for porting into UI-managed popups. 118 tests in `fusion-tests.md` (vs 27 at WP1). Real-device verification sweep deferred to Edgar.

---

*End of retro — Phase 7 closed, with eyes open about what shipped and what didn't.*
