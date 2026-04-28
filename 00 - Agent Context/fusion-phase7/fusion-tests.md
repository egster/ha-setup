# FUSION Test Suite

_The test contract for FUSION Phase 7. Every WP starts by adding its tests to this file; the suite must pass (modulo `baseline_known_failure` entries) before the WP merges._

---

## How this file is parsed

Every test is a level-2 heading `## TEST-NNN: <title>` followed by a block of `- key: value` lines (YAML-flavoured). The fields below are required for each test; the runner (`scripts/run-fusion-tests.sh`) ignores anything else.

| field | required | format | meaning |
|-------|----------|--------|---------|
| `viewport` | yes  | `WxH` or `any` | Browser viewport for the test. Ignored for non-DOM tests. |
| `type` | yes | one of `dom_assertion`, `visual_regression`, `behavioural`, `yaml_schema`, `entity_existence`, `template_eval` | Dispatch hint for the runner. |
| `url` | optional | full URL | Defaults to `${FUSION_URL}` env var or `http://homeassistant.local:8123/dashboard-fusion/fusion`. |
| `assertion` | yes | JS expression / shell snippet / template string | The assertion body. For DOM tests, JS evaluated in the page; the runner injects the `WALK` preamble first (see below). |
| `expected` | yes | string / number / regex | Expected value. Compared against the assertion's return value. |
| `tolerance` | optional | `0`, `±N`, `regex` | Comparison strictness. Default `0` = exact match. |
| `owner_wp` | yes | `WP1` … `WP6` | Which WP introduced (or owns) the test. Useful for blame + scope. |
| `status` | yes | `baseline`, `baseline_known_failure`, `future` | `baseline_known_failure` = expected to fail today, must pass after the owning WP closes. |

### Preamble (injected before every `dom_assertion` and `behavioural` JS run)

```js
window.WALK = (root, sel) => {
  if (!root) return null;
  const direct = root.querySelector ? root.querySelector(sel) : null;
  if (direct) return direct;
  const all = root.querySelectorAll ? Array.from(root.querySelectorAll('*')) : [];
  for (const el of all) {
    if (el.shadowRoot) {
      const r = WALK(el.shadowRoot, sel);
      if (r) return r;
    }
  }
  return null;
};
window.WALK_ALL = (root, sel, acc=[]) => {
  if (!root) return acc;
  if (root.querySelectorAll) acc.push(...root.querySelectorAll(sel));
  const all = root.querySelectorAll ? Array.from(root.querySelectorAll('*')) : [];
  for (const el of all) {
    if (el.shadowRoot) WALK_ALL(el.shadowRoot, sel, acc);
  }
  return acc;
};
window.HASS = () => document.querySelector('home-assistant') && document.querySelector('home-assistant').hass;
// Aggregate visible text across light DOM + shadow DOM. innerText alone misses
// shadow content (most of the dashboard renders inside shadow roots).
window.WALK_TEXT = (node, acc) => {
  acc = acc || [];
  if (!node) return acc;
  if (node.nodeType === 3) {
    const t = node.textContent;
    if (t && t.trim()) acc.push(t);
  }
  if (node.childNodes) {
    for (const c of node.childNodes) WALK_TEXT(c, acc);
  }
  if (node.shadowRoot) WALK_TEXT(node.shadowRoot, acc);
  return acc;
};
```

### Running

```bash
# Full suite (SSH-dispatched tests + browser-test specs to stdout)
./scripts/run-fusion-tests.sh

# Allow the documented baseline failures (WP1 only; downstream WPs should not need this)
./scripts/run-fusion-tests.sh --allow-baseline-failures

# List tests without running
./scripts/run-fusion-tests.sh --list

# Run only one category
./scripts/run-fusion-tests.sh --category=yaml_schema
```

Browser tests (`dom_assertion`, `visual_regression`, `behavioural`) require a Claude Code session with Chrome MCP connected and the dashboard page already authenticated. The runner emits each browser test's spec as a JSON line; a Claude session executes them via `mcp__Claude_in_Chrome__javascript_tool` (with the preamble injected) and writes results back via `--results=<path>`. See the runner script for the full IPC.

---

## Tests

### DOM assertions (TEST-001 … TEST-013)

## TEST-001: hui-view-container padding-left at 1280px
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    getComputedStyle(WALK(document, 'hui-view-container')).paddingLeft
- expected: "100px"
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-002: hui-view-container padding-left at 900px
- viewport: 900x900
- type: dom_assertion
- assertion: |
    getComputedStyle(WALK(document, 'hui-view-container')).paddingLeft
- expected: "100px"
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-003: hui-view-container padding-left at 700px (narrow mode trips here)
- viewport: 700x900
- type: dom_assertion
- assertion: |
    getComputedStyle(WALK(document, 'hui-view-container')).paddingLeft
- expected: "0px"
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-004: hui-view-container padding-left at 375px
- viewport: 375x812
- type: dom_assertion
- assertion: |
    getComputedStyle(WALK(document, 'hui-view-container')).paddingLeft
- expected: "0px"
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-005: Sidebar nav cell visible at 1280px (left ≥ 0)
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (function(){const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})()
- expected: ">=0"
- tolerance: regex
- owner_wp: WP1
- status: baseline

## TEST-006: Sidebar nav cell visible at 900px (left ≥ 0)
- viewport: 900x900
- type: dom_assertion
- assertion: |
    (function(){const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})()
- expected: ">=0"
- tolerance: regex
- owner_wp: WP1
- status: baseline

## TEST-007: Sidebar nav cell visible at 700px (left ≥ 0) — KNOWN FAILURE
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (function(){const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})()
- expected: ">=0"
- tolerance: regex
- owner_wp: WP1
- status: baseline_known_failure
- notes: Phase 7 root cause — at 700px the sidebar lives at left=−84, off-screen. Fixed by WP3+WP4 (shell swap to bottom-tab on phone, responsive grid).

## TEST-008: Sidebar nav cell visible at 375px (left ≥ 0) — KNOWN FAILURE
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (function(){const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})()
- expected: ">=0"
- tolerance: regex
- owner_wp: WP1
- status: baseline_known_failure
- notes: Same off-screen sidebar as TEST-007. Real 375 cannot be reached on macOS Chrome (capped at ~526); harness uses the smallest reachable inner-width. Phone test must be re-run on real device or DevTools emulation when WP3+WP4 ship.

## TEST-009: Sidebar holds 8 cells (7 panels + kiosk toggle) at 1280
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>=40&&r.height<=70;}).length
- expected: 8
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-010: Hero strip renders ≥5 KPI tiles at 1280
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    WALK_ALL(document,'button-card').filter(b=>{const r=b.getBoundingClientRect();return r.height>60&&r.height<100&&r.top<200&&r.top>50&&r.width>100;}).length
- expected: ">=5"
- tolerance: regex
- owner_wp: WP1
- status: baseline
- notes: Spec calls for 6 (Power Now is the 6th, blocked on power source). When Power tile lands, expected becomes ">=6".

## TEST-011: Floor headers render on Home panel
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (function(){const txt=WALK_TEXT(document.body).join(' ').toUpperCase();return ['MAIN FLOOR','UPPER FLOOR','DOWNSTAIRS','OUTSIDE'].filter(n=>txt.includes(n)).length;})()
- expected: 4
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-012: MAIN FLOOR row contains Living Room + Kitchen + Office cards
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (function(){const txt=WALK_TEXT(document.body).join(' ');return ['Living Room','Kitchen','Office'].every(n=>txt.includes(n));})()
- expected: true
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-013: input_select.fusion_panel is currently 'home'
- viewport: any
- type: dom_assertion
- assertion: |
    HASS() && HASS().states['input_select.fusion_panel'] && HASS().states['input_select.fusion_panel'].state
- expected: "home"
- tolerance: 0
- owner_wp: WP1
- status: baseline
- notes: Suite preamble forces home before each run; this test catches a regression where the preamble or the helper is broken.

### Visual regression (TEST-021 … TEST-024)

## TEST-021: Visual baseline at 1280
- viewport: 1280x900
- type: visual_regression
- assertion: |
    capture_screenshot('baseline_1280px.png')
- expected: "match-or-capture"
- tolerance: manual
- owner_wp: WP1
- status: baseline
- notes: First run captures baseline (or records screenshot ID in baseline-measurements.md). Subsequent runs compare against it; differences flag for human review.

## TEST-022: Visual baseline at 900
- viewport: 900x900
- type: visual_regression
- assertion: |
    capture_screenshot('baseline_900px.png')
- expected: "match-or-capture"
- tolerance: manual
- owner_wp: WP1
- status: baseline

## TEST-023: Visual baseline at 700 (narrow-mode entry)
- viewport: 700x900
- type: visual_regression
- assertion: |
    capture_screenshot('baseline_700px.png')
- expected: "match-or-capture"
- tolerance: manual
- owner_wp: WP1
- status: baseline
- notes: Visible breakage starts here — sidebar disappears off the left edge.

## TEST-024: Visual baseline at 375 (phone)
- viewport: 375x812
- type: visual_regression
- assertion: |
    capture_screenshot('baseline_375px.png')
- expected: "match-or-capture"
- tolerance: manual
- owner_wp: WP1
- status: baseline
- notes: Confirmed broken state — WP3+WP4 fix targets. Real 375 must be tested on phone or DevTools emulation; macOS Chrome bottoms out at ~526.

### Behavioural (TEST-031 … TEST-033)

## TEST-031: Click kitchen nav icon → fusion_panel becomes 'kitchen'
- viewport: 1280x900
- type: behavioural
- assertion: |
    (async()=>{const before=HASS().states['input_select.fusion_panel'].state;await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'kitchen'});await new Promise(r=>setTimeout(r,300));const after=HASS().states['input_select.fusion_panel'].state;return JSON.stringify({before,after});})()
- expected: "{\"before\":\"home\",\"after\":\"kitchen\"}"
- tolerance: regex
- owner_wp: WP1
- status: baseline
- notes: Calls the service the icon's tap_action would dispatch. Real click test would tap the icon DOM element; this is a one-step fidelity trade-off for stability.

## TEST-032: Click home nav icon → fusion_panel becomes 'home'
- viewport: 1280x900
- type: behavioural
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});await new Promise(r=>setTimeout(r,300));return HASS().states['input_select.fusion_panel'].state;})()
- expected: "home"
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-033: Kiosk toggle flips input_boolean.fusion_kiosk
- viewport: 1280x900
- type: behavioural
- assertion: |
    (async()=>{const start=HASS().states['input_boolean.fusion_kiosk'].state;await HASS().callService('input_boolean','toggle',{entity_id:'input_boolean.fusion_kiosk'});await new Promise(r=>setTimeout(r,300));const mid=HASS().states['input_boolean.fusion_kiosk'].state;await HASS().callService('input_boolean','toggle',{entity_id:'input_boolean.fusion_kiosk'});await new Promise(r=>setTimeout(r,300));const end=HASS().states['input_boolean.fusion_kiosk'].state;return JSON.stringify({start,mid,end});})()
- expected: "^\\{\"start\":\"(on|off)\",\"mid\":\"(off|on)\",\"end\":\"(on|off)\"\\}$"
- tolerance: regex
- owner_wp: WP1
- status: baseline
- notes: End state must match start (toggle twice). Mid state must be the opposite of start. Regex validates all three are valid HA boolean states.

### YAML schema (TEST-041 … TEST-042)

## TEST-041: ha core check passes
- viewport: any
- type: yaml_schema
- assertion: |
    ssh ha "ha core check 2>&1"
- expected: "completed successfully"
- tolerance: regex
- owner_wp: WP1
- status: baseline
- notes: Runs the full HA config check against the deployed config (which includes the dashboard via the dashboards: registration). Catches breakage before it lands.

## TEST-042: yamllint passes on config/dashboards/fusion.yaml
- viewport: any
- type: yaml_schema
- assertion: |
    yamllint -d "{rules: {line-length: disable}}" config/dashboards/fusion.yaml 2>&1 | wc -l
- expected: 0
- tolerance: 0
- owner_wp: WP1
- status: baseline
- notes: line-length disabled because some inline JS templates legitimately exceed 80 cols.

### Entity existence (TEST-051 … TEST-053)

## TEST-051: input_select.fusion_panel exists with all 7 panel options
- viewport: any
- type: entity_existence
- assertion: |
    HASS().states['input_select.fusion_panel'].attributes.options.sort().join(',')
- expected: "automations,climate,energy,home,kitchen,media,network"
- tolerance: 0
- owner_wp: WP1
- status: baseline

## TEST-052: All entity references in fusion.yaml resolve to a real entity
- viewport: any
- type: entity_existence
- assertion: |
    (function(){const refs=["binary_sensor.entrance_motion_sensors","binary_sensor.eve_motion_20eby9901_occupancy_2","binary_sensor.office_motion_sensors","binary_sensor.zenwifi_bq16_ca38_wan_status","climate.air_conditioning_bedroom","climate.kitchen_area","climate.living_room_area","climate.office_area","device_tracker.edphone","device_tracker.ipad","input_boolean.fusion_kiosk","input_boolean.fusion_more_overlay","input_number.monitoring_outdoor_temperature","input_select.fusion_panel","light.entrance_ceiling","light.garage","light.jona_lights","light.kitchen_lights","light.living_room_lights","light.office_lights","light.outdoor_lights","light.uplight_back_left","light.uplight_back_right","light.uplight_front","light.upstairs_hall_lights","media_player.homepod","media_player.jona_speaker","media_player.kitchen_speakers","media_player.living_room","media_player.living_room_tv_2","media_player.upstairs_speaker","person.edgar","scene.lights_off","script.lr_relax","script.movie_mode","sensor.eve_energy_20ebo8301_energy","sensor.eve_energy_20ebo8301_energy_2","sensor.eve_energy_20ebo8301_power","sensor.eve_energy_20ebo8301_power_2","sensor.zenwifi_bq16_ca38_download_speed","sensor.zenwifi_bq16_ca38_upload_speed","sensor.zenwifi_bq16_ca38_uptime","timer.kitchen_timer_1","timer.kitchen_timer_2","todo.shopping_list"];const states=HASS().states;return JSON.stringify(refs.filter(e=>!states[e]));})()
- expected: "[]"
- tolerance: 0
- owner_wp: WP1
- status: baseline
- notes: |
    The hardcoded list mirrors the unique entity references in `config/dashboards/fusion.yaml` (excluding service-call false positives like `input_select.select_option`). When a WP adds, removes, or renames an entity reference, update this list in lockstep — diffing the test alongside the YAML is the regression signal. To regenerate the list:
    `grep -hoE "(binary_sensor|sensor|light|climate|media_player|input_select|input_boolean|input_number|input_text|automation|scene|script|switch|timer|todo|device_tracker|person|weather)\.[a-z0-9_]+" config/dashboards/fusion.yaml | sort -u | grep -vE "^(input_select\.select_option|input_boolean\.toggle|scene\.turn_on|script\.turn_on)$"`
    "Unavailable" entities (e.g. wall-switched Hue bulbs) still resolve through HA — only fully-missing entities cause this test to fail.

## TEST-053: ASUS BQ16 status-bar entities exist
- viewport: any
- type: entity_existence
- assertion: |
    ['binary_sensor.zenwifi_bq16_ca38_wan_status','sensor.zenwifi_bq16_ca38_uptime','sensor.zenwifi_bq16_ca38_download_speed','sensor.zenwifi_bq16_ca38_upload_speed'].every(e=>HASS().states[e]&&HASS().states[e].state!=='unavailable'&&HASS().states[e].state!=='unknown')
- expected: true
- tolerance: 0
- owner_wp: WP1
- status: baseline
- notes: These four are the load-bearing status-bar entities. Catches integration drift.

### Template eval (TEST-061 … TEST-062)

## TEST-061: Lights On count template evaluates without error
- viewport: any
- type: template_eval
- assertion: |
    {{ states.light | selectattr('state', 'eq', 'on') | list | count }}
- expected: "^\\d+$"
- tolerance: regex
- owner_wp: WP1
- status: baseline

## TEST-062: Avg Temp template evaluates without error
- viewport: any
- type: template_eval
- assertion: |
    {% set rooms = ['climate.living_room_area','climate.kitchen_area','climate.office_area'] %}
    {% set vals = rooms | map('state_attr','current_temperature') | reject('none') | list %}
    {{ (vals | sum / vals | count) | round(1) if vals | count > 0 else 'n/a' }}
- expected: "^[0-9]+\\.[0-9]$"
- tolerance: regex
- owner_wp: WP1
- status: baseline
- notes: Renders the hero-strip Avg Temp value. If any of the 3 climate entities goes unavailable, this still resolves (filter rejects None). Catches Jinja syntax breakage.

### File system + integration (TEST-100 … TEST-108) — owned by WP2

These cover the file restructure + YAML-mode conversion. Pre-extraction the file_system tests fail (the new files do not exist yet); post-extraction they pass. TEST-101…103 are stricter visual_regression entries that compare a structural fingerprint at three viewports rather than relying on manual diff.

## TEST-100: ha_check_config passes after YAML-mode dashboard registration
- viewport: any
- type: yaml_schema
- assertion: |
    ssh ha "ha core check 2>&1"
- expected: "completed successfully"
- tolerance: regex
- owner_wp: WP2
- status: baseline
- notes: |
    Same shell as TEST-041 — runs `ha core check`. Owned by WP2 because the YAML-mode registration in configuration.yaml is the breakage source if the include tree is malformed. Pre-restructure passes redundantly; post-restructure must still pass against the new YAML-mode tree. Kept distinct so reviewers can grep "TEST-100" to confirm the YAML-mode path specifically.

## TEST-101: Structural fingerprint at 1280 matches WP1 baseline
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    JSON.stringify({hui_cards:WALK_ALL(document,'hui-card').length,nav_cells:WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length,sidebar_left:(()=>{const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})(),padding_left:getComputedStyle(WALK(document,'hui-view-container')).paddingLeft,panel_state:HASS().states['input_select.fusion_panel'].state})
- expected: '{"hui_cards":59,"nav_cells":8,"sidebar_left":272,"padding_left":"100px","panel_state":"home"}'
- tolerance: 0
- owner_wp: WP2
- status: baseline
- notes: |
    Captures a 5-element structural fingerprint of the rendered dashboard at 1280: hui_cards=59, nav_cells=8, sidebar_left=272, padding_left=100px, panel_state=home. Pre-WP2 captures the current state; post-WP2 (verbatim relocation) must be byte-identical. Any drift means the !include tree changed structure, not just file location. If hui_cards count drifts, bisect via per-panel screenshots to find which panel's relocation introduced cards.

## TEST-102: Structural fingerprint at 900 matches WP1 baseline
- viewport: 900x900
- type: dom_assertion
- assertion: |
    JSON.stringify({nav_cells:WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length,sidebar_left:(()=>{const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})(),padding_left:getComputedStyle(WALK(document,'hui-view-container')).paddingLeft})
- expected: '{"nav_cells":8,"sidebar_left":272,"padding_left":"100px"}'
- tolerance: 0
- owner_wp: WP2
- status: baseline
- notes: hui_cards count omitted at this viewport because some lazy-rendered cards may not be in the DOM yet — sidebar position + padding are the load-bearing checks for WP2's verbatim-relocation contract.

## TEST-103: Structural fingerprint at 700 matches WP1 baseline (narrow mode)
- viewport: 700x900
- type: dom_assertion
- assertion: |
    JSON.stringify({nav_cells:WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length,sidebar_left:(()=>{const cells=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;});return cells.length?Math.round(cells[0].getBoundingClientRect().left):null;})(),padding_left:getComputedStyle(WALK(document,'hui-view-container')).paddingLeft})
- expected: '{"nav_cells":8,"sidebar_left":-84,"padding_left":"0px"}'
- tolerance: 0
- owner_wp: WP2
- status: baseline_known_failure
- notes: |
    Original WP2 intent — confirm the narrow-mode breakage is preserved by verbatim relocation. Status flipped to baseline_known_failure by WP3 (2026-04-27) after the WP2 deploy revealed a harness limit: the macOS Chrome MCP harness can only reach ~606 px inner width, which doesn't trigger the narrow-mode breakage on this host. At real iPhone 375 px the storage-mode breakage IS preserved exactly as the WP1 baseline documented (Edgar verified hands-on, see CHANGELOG 2026-04-27 corrections). The structural-fingerprint regression check is now load-bearing only at 1280 (TEST-101) and 900 (TEST-102); TEST-103's role is documentation of the semantic intent. Same convention as TEST-007/008 — manual real-device verification fills the gap. Once WP4 ships, this test becomes obsolete (the bottom-tab shell variant removes the negative-margin source of the breakage entirely).

## TEST-104: All 7 panel input_select options render their respective panel
- viewport: 1280x900
- type: behavioural
- assertion: |
    (async()=>{const opts=['home','kitchen','climate','media','network','energy','automations'];const out=[];for(const o of opts){await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:o});await new Promise(r=>setTimeout(r,400));const txt=WALK_TEXT(document.body).join(' ');out.push({option:o,observed:HASS().states['input_select.fusion_panel'].state,non_empty:txt.length>500});}await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return JSON.stringify(out.every(r=>r.option===r.observed&&r.non_empty));})()
- expected: "true"
- tolerance: 0
- owner_wp: WP2
- status: baseline
- notes: |
    Cycles through all 7 panel options. For each, verifies (a) input_select state changed correctly and (b) the rendered DOM has > 500 chars of visible text (i.e. the panel rendered something, not blank). Resets to home at the end. Catches a !include path typo that silently produces an empty conditional card.

## TEST-105: All 11 WP2 include files exist and are non-empty
- viewport: any
- type: yaml_schema
- assertion: |
    bash -c 'paths=("config/dashboards/fusion/templates.yaml" "config/dashboards/fusion/statusbar.yaml" "config/dashboards/fusion/shell.yaml" "config/dashboards/fusion/panels/home.yaml" "config/dashboards/fusion/panels/kitchen.yaml" "config/dashboards/fusion/panels/climate.yaml" "config/dashboards/fusion/panels/media.yaml" "config/dashboards/fusion/panels/network.yaml" "config/dashboards/fusion/panels/energy.yaml" "config/dashboards/fusion/panels/automations.yaml" "config/dashboards/fusion/popups/.gitkeep"); missing=0; for p in "${paths[@]}"; do if [ ! -s "$p" ]; then missing=$((missing+1)); fi; done; echo $missing'
- expected: 0
- tolerance: 0
- owner_wp: WP2
- status: baseline_known_failure
- notes: 10 yaml include files + 1 .gitkeep in the empty popups/ directory (popups are WP5a-d's deliverable). Pre-WP2 every path is missing → returns 11; flips to 0 once extraction completes.

## TEST-106: Entry-point fusion.yaml is < 100 lines
- viewport: any
- type: yaml_schema
- assertion: |
    wc -l < config/dashboards/fusion.yaml
- expected: "<100"
- tolerance: regex
- owner_wp: WP2
- status: baseline_known_failure
- notes: Pre-WP2 the entry-point is the 1731-line monolith → fails. Post-WP2 it should be ~30 lines (title + button_card_templates !include + kiosk_mode + view header + shell !include).

## TEST-107: Every include file is independently valid YAML
- viewport: any
- type: yaml_schema
- assertion: |
    bash -c 'fails=0; for f in config/dashboards/fusion/templates.yaml config/dashboards/fusion/statusbar.yaml config/dashboards/fusion/shell.yaml config/dashboards/fusion/panels/*.yaml; do [ -f "$f" ] || continue; python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" 2>/dev/null || fails=$((fails+1)); done; echo $fails'
- expected: 0
- tolerance: 0
- owner_wp: WP2
- status: baseline_known_failure
- notes: Each include file must parse on its own without dependence on the entry-point context. Tests for stranded anchors, dangling `&` references, or accidental top-level merge ops that only resolve in the assembled tree.

## TEST-108: Dashboard reload via input_select cycle does not error
- viewport: 1280x900
- type: behavioural
- assertion: |
    (async()=>{try{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'climate'});await new Promise(r=>setTimeout(r,500));await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});await new Promise(r=>setTimeout(r,500));return 'ok';}catch(e){return 'err:'+String(e);}})()
- expected: "ok"
- tolerance: 0
- owner_wp: WP2
- status: baseline
- notes: |
    Smoke-test that switching panels and switching back works without throwing. WP2's `ha core reload-all` is exercised at deploy time, not in the test suite — this is the runtime-side cousin: prove the assembled dashboard responds to state changes without errors. Catches regression in the way conditional cards reference their panel option string.

### Responsive grid migration (TEST-200 … TEST-212) — owned by WP3

Cover the WP3 swap of fixed `repeat(N, 1fr)` panel grids for `repeat(auto-fit, minmax(MIN, 1fr))`. Pre-WP3, every panel grid is locked to a fixed column count at every viewport. Post-WP3, the grids collapse 3-col → 2-col → 1-col as the viewport narrows.

**Per-panel minmax floors (verify against impl):**

| Grid | minmax floor |
|------|--------------|
| home hero (5 KPIs) | 140 px |
| home rooms (3 cards each floor grid) | 240 px |
| climate (4 zones) | 240 px |
| network (3 stat tiles) | 280 px |
| media (6 player cards) | 280 px |
| energy (2 power tiles) | 280 px |

**Harness limit:** the macOS Chrome MCP harness clips at ~606 px inner width. Tests targeting `viewport: 375x812` execute at the harness floor, not at 375. They stay `baseline_known_failure` permanently — same convention as TEST-007/008. Manual phone verification fills the gap.

## TEST-200: MAIN FLOOR rooms render in 3 columns at 1280px
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Kitchen')&&txt.includes('Office');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})()
- expected: 3
- tolerance: 0
- owner_wp: WP3
- status: baseline
- notes: Pre-WP3 passes via fixed `repeat(3, 1fr)`. Post-WP3 passes via auto-fit clamped to 3 cards. Regression guard for the desktop view.

## TEST-201: MAIN FLOOR rooms render in 3 columns at 900px
- viewport: 900x900
- type: dom_assertion
- assertion: |
    (function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Kitchen')&&txt.includes('Office');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})()
- expected: 3
- tolerance: 0
- owner_wp: WP3
- status: baseline
- notes: Pre-WP3 passes via fixed grid. Post-WP3 needs minmax floor ≤ ~256 px against the 900-viewport content area (~768 px after sidebar + padding) for 3-col to hold.

## TEST-202: MAIN FLOOR rooms collapse to 2 columns at 700px
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Kitchen')&&txt.includes('Office');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})()
- expected: 2
- tolerance: 0
- owner_wp: WP3
- status: baseline_known_failure
- notes: Fails pre-WP3 (returns 3 from fixed grid). Flips to baseline once auto-fit lands — at 700 the content area (~668 px) divided by 240-px floor → 2 cols.

## TEST-203: MAIN FLOOR rooms collapse to 1 column at 375px
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Kitchen')&&txt.includes('Office');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})()
- expected: 1
- tolerance: 0
- owner_wp: WP3
- status: baseline_known_failure
- notes: Harness 606-px floor blocks reaching real 375; at the harness's reach (~606), 2 cols fit (575 / 240 = 2.39 → 2), so this fails on the harness even post-WP3. Stays baseline_known_failure permanently — same convention as TEST-007/008. Manual real-device verification on Edgar's iPhone after WP4 merges.

## TEST-204: Climate zones render in ≥4 columns at 1280px
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'climate'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Bedroom');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: ">=4"
- tolerance: regex
- owner_wp: WP3
- status: baseline
- notes: Pre-WP3 passes via fixed `repeat(4, 1fr)`. Post-WP3 passes via auto-fit clamped to 4 cards.

## TEST-205: Climate zones collapse to 2 columns at 700px
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'climate'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Bedroom');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: 2
- tolerance: 0
- owner_wp: WP3
- status: baseline_known_failure
- notes: Fails pre-WP3 (returns 4). Flips post-WP3 once 240-px floor takes effect.

## TEST-206: Climate zones collapse to 1 column at 375px
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'climate'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;const txt=el.textContent||'';return txt.includes('Living Room')&&txt.includes('Bedroom');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: 1
- tolerance: 0
- owner_wp: WP3
- status: baseline_known_failure
- notes: Harness limit. Same convention as TEST-203.

## TEST-207: Network cards render in 3 columns at 1280px
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'network'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;return (el.textContent||'').includes('WAN Status');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: 3
- tolerance: 0
- owner_wp: WP3
- status: baseline
- notes: Pre-WP3 passes via fixed `repeat(3, 1fr)`. Post-WP3 passes via auto-fit clamped to 3 cards. Anchor `WAN Status` is unique to the network panel.

## TEST-208: Network cards collapse to 1 column at 375px
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'network'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;return (el.textContent||'').includes('WAN Status');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: 1
- tolerance: 0
- owner_wp: WP3
- status: baseline_known_failure
- notes: Harness limit.

## TEST-209: Media players render in ≥2 columns at 1280px
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'media'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;return (el.textContent||'').includes('VisionMaster');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: ">=2"
- tolerance: regex
- owner_wp: WP3
- status: baseline
- notes: Pre-WP3 passes via fixed `repeat(2, 1fr)`. Post-WP3 with 280-px floor at 1280 content (~1148 px) → 4 cols. Anchor `VisionMaster` is unique to the media panel.

## TEST-210: Media players collapse to 1 column at 375px
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'media'});await new Promise(r=>setTimeout(r,500));const result=(function(){const grids=WALK_ALL(document,'*').filter(el=>{if(!el.tagName)return false;let cs;try{cs=getComputedStyle(el);}catch(e){return false;}if(cs.display!=='grid')return false;return (el.textContent||'').includes('VisionMaster');});if(grids.length===0)return -1;const smallest=grids.reduce((a,b)=>{const ar=a.getBoundingClientRect();const br=b.getBoundingClientRect();return (ar.width*ar.height<br.width*br.height)?a:b;});return getComputedStyle(smallest).gridTemplateColumns.split(/\s+/).filter(s=>/[\d.]+px/.test(s)).length;})();await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return result;})()
- expected: 1
- tolerance: 0
- owner_wp: WP3
- status: baseline_known_failure
- notes: Harness limit.

## TEST-211: No horizontal page overflow on home panel at 1280px
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    document.documentElement.scrollWidth - document.documentElement.clientWidth
- expected: "<=2"
- tolerance: regex
- owner_wp: WP3
- status: baseline
- notes: Regression guard for the desktop view — verifies the responsive-grid swap doesn't introduce horizontal scroll. Multi-viewport overflow at narrower viewports is owned by WP4's shell-swap (the −84 px outer margin causes overflow at <871 px until the bottom-tab variant lands).

## TEST-212: MAIN FLOOR room cards each ≥ 240px wide at 700px
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (function(){const targets=['Living Room','Kitchen','Office'];const widths=[];for(const t of targets){const all=WALK_ALL(document,'*');const candidates=all.filter(e=>{if(!e.tagName)return false;return (e.textContent||'').trim()===t;});if(candidates.length===0)continue;let parent=candidates[0];while(parent&&parent.getBoundingClientRect().width<100){parent=parent.parentElement;}if(parent)widths.push(Math.round(parent.getBoundingClientRect().width));}return widths.length===3?Math.min(...widths):-1;})()
- expected: ">=240"
- tolerance: regex
- owner_wp: WP3
- status: baseline_known_failure
- notes: Fails pre-WP3 — at 700 with `repeat(3, 1fr)`, each card is ~668/3 ≈ 222 px (below the 240-floor target). Flips post-WP3 once minmax(240px, 1fr) takes over and 700-px content collapses to 2-col, putting each card at ~334 px.


### Shell swap (TEST-300 … TEST-315) — owned by WP4

These cover the state-switch hybrid shell: sidebar on desktop/iPad (≥871px), bottom-tab nav on phone (<871px). Pre-implementation: every TEST-300..315 fails (no state-switch in shell, sidebar still rendered everywhere). Post-WP4: all 16 pass + WP1 TEST-007/008 (sidebar off-screen at <871px) flip to baseline because the dashboard at narrow viewports no longer renders the sidebar at all. State-switch syntax used: BOTH media queries listed under `states:` explicitly (no `default:` field — `default` expects a state-name string, not a card definition).

## TEST-300: Desktop sidebar visible at 1280 (≥7 nav cells, width 72)
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length
- expected: ">=7"
- tolerance: regex
- owner_wp: WP4
- status: baseline_known_failure
- notes: At desktop viewport the state-switch active branch is the sidebar layout — same 8-cell sidebar as pre-WP4. ≥7 keeps the assertion robust if the kiosk-toggle cell shifts (TEST-009 already pins it at exactly 8).

## TEST-301: Bottom tab bar NOT in DOM at 1280
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    WALK_ALL(document,'ha-card').filter(c=>{const cs=getComputedStyle(c);return cs.position==='fixed'&&cs.bottom==='0px'&&c.getBoundingClientRect().width>200;}).length
- expected: 0
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: state-switch only renders the active branch — at desktop viewport the phone branch (which contains the fixed-position bottom bar) must not be in DOM at all.

## TEST-302: Statusbar has 7 button-cards visible at top at 1280
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    WALK_ALL(document,'button-card').filter(b=>{const r=b.getBoundingClientRect();const cs=getComputedStyle(b);return r.top<50&&r.height>=20&&r.height<=50&&cs.display!=='none'&&r.width>10;}).length
- expected: 7
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: Desktop statusbar holds 7 cards (person, edphone, ipad, temp, wan, dl, ul). Brief said "8 cells" referring to grid template areas (1 spacer cell). Filter targets visible button-cards in the top 50px band — robust to the grid-area wrapper structure used by the desktop statusbar layout-card.

## TEST-303: No horizontal overflow at 1280
- viewport: 1280x900
- type: dom_assertion
- assertion: |
    document.documentElement.scrollWidth - document.documentElement.clientWidth
- expected: "<=10"
- tolerance: regex
- owner_wp: WP4
- status: baseline_known_failure
- notes: Pre-WP4 the −84px outer margin produces no overflow at 1280 (HA padding compensates), but the dropped-margin variant must not introduce one either. ≤10px tolerates sub-pixel rounding on retina hosts and small box-shadow bleed (measured 4px on 1849 host).

## TEST-304: Sidebar still visible at 900 (above 871 breakpoint)
- viewport: 900x900
- type: dom_assertion
- assertion: |
    WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length
- expected: ">=7"
- tolerance: regex
- owner_wp: WP4
- status: baseline_known_failure
- notes: 900 > 871 → desktop branch still active. iPad portrait (~768) crosses to phone; iPad landscape (~1024) stays desktop. 900 brackets the breakpoint from above.

## TEST-305: Sidebar NOT in DOM at 700, bottom tab bar IS in DOM
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (function(){const navs=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length;const fixed=WALK_ALL(document,'ha-card').filter(c=>{const cs=getComputedStyle(c);return cs.position==='fixed'&&cs.bottom==='0px';}).length;return JSON.stringify({sidebar_cells:navs,fixed_bars:fixed});})()
- expected: '{"sidebar_cells":0,"fixed_bars":1}'
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: Below 871 the phone branch is active — the desktop sidebar's 72px nav cells must not be rendered, and exactly one fixed-position bottom bar must exist.

## TEST-306: Bottom tab bar has 5 visible buttons at 700
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (function(){const bar=WALK_ALL(document,'ha-card').find(c=>{const cs=getComputedStyle(c);return cs.position==='fixed'&&cs.bottom==='0px';});if(!bar)return 0;return WALK_ALL(bar,'button-card').filter(b=>b.getBoundingClientRect().width>30).length;})()
- expected: 5
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: Five primary tabs — Home, Climate, Media, Network, More. The "More" tab opens an inline 3-button overlay (Kitchen, Energy, Automations) above the bar.

## TEST-307: Statusbar has 4 cards at 700 (compressed phone variant)
- viewport: 700x900
- type: dom_assertion
- assertion: |
    (function(){const sb=WALK_ALL(document,'hui-card').find(c=>{const r=c.getBoundingClientRect();return r.height>=30&&r.height<=46&&r.top<10&&r.width>200;});if(!sb)return 0;return WALK_ALL(sb,'button-card').length;})()
- expected: 4
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: Phone statusbar drops edphone, ipad, ul — keeps person, temp, wan, dl. Padding tightens to fit narrow viewports.

## TEST-308: No horizontal overflow at 375
- viewport: 375x812
- type: dom_assertion
- assertion: |
    document.documentElement.scrollWidth - document.documentElement.clientWidth
- expected: "<=2"
- tolerance: regex
- owner_wp: WP4
- status: baseline_known_failure
- notes: Hard goal — phone must not scroll horizontally. Real iPhone 375 CSS px is the canonical target; macOS Chrome harness caps at ~526 inner so this test runs at the harness floor. Visual verification on real device is the load-bearing check (Edgar confirmed 2026-04-27 the WP1 sidebar IS off-screen at real 375).

## TEST-309: Bottom tab bar position is fixed at 375
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (function(){const bar=WALK_ALL(document,'ha-card').find(c=>{const cs=getComputedStyle(c);return cs.position==='fixed'&&cs.bottom==='0px';});return bar?getComputedStyle(bar).position:'not-found';})()
- expected: "fixed"
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure

## TEST-310: Bottom tab bar bottom edge is 0px at 375
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (function(){const bar=WALK_ALL(document,'ha-card').find(c=>{const cs=getComputedStyle(c);return cs.position==='fixed'&&cs.bottom==='0px';});return bar?getComputedStyle(bar).bottom:'not-found';})()
- expected: "0px"
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure

## TEST-311: Phone-branch outer layout has no negative left margin at 375
- viewport: 375x812
- type: dom_assertion
- assertion: |
    (function(){const lc=WALK(document,'hui-view-container');if(!lc)return 999;const child=lc.querySelector('hui-card');if(!child)return 999;const m=parseFloat(getComputedStyle(child).marginLeft||'0');return m;})()
- expected: ">=0"
- tolerance: regex
- owner_wp: WP4
- status: baseline_known_failure
- notes: The −84px margin is the WP1 root-cause bug. Phone branch must drop it entirely (`margin: 0`). The query targets the layout-card child of hui-view-container — that's the outer dashboard wrapper.

## TEST-312: Tap "Climate" tab on phone → fusion_panel becomes 'climate'
- viewport: 700x900
- type: behavioural
- assertion: |
    (async()=>{await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});await new Promise(r=>setTimeout(r,300));await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'climate'});await new Promise(r=>setTimeout(r,300));const after=HASS().states['input_select.fusion_panel'].state;await HASS().callService('input_select','select_option',{entity_id:'input_select.fusion_panel',option:'home'});return after;})()
- expected: "climate"
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: Calls the service the bottom-tab Climate button's tap_action would dispatch — same one-step fidelity trade-off as TEST-031.

## TEST-313: Tap "More" → overlay shows Kitchen/Energy/Automations
- viewport: 700x900
- type: behavioural
- assertion: |
    (async()=>{await HASS().callService('input_boolean','turn_off',{entity_id:'input_boolean.fusion_more_overlay'});await new Promise(r=>setTimeout(r,300));const findOverlayBar=()=>WALK_ALL(document,'ha-card').find(c=>{const cs=getComputedStyle(c);return cs.position==='fixed'&&cs.bottom==='56px'&&cs.display!=='none';});const beforeBar=findOverlayBar();await HASS().callService('input_boolean','turn_on',{entity_id:'input_boolean.fusion_more_overlay'});await new Promise(r=>setTimeout(r,500));const afterBar=findOverlayBar();const overlayText=afterBar?WALK_TEXT(afterBar).join('|'):'';const allLabelsInOverlay=afterBar?['Kitchen','Energy','Automations'].every(n=>overlayText.includes(n)):false;await HASS().callService('input_boolean','turn_off',{entity_id:'input_boolean.fusion_more_overlay'});return JSON.stringify({overlay_was_hidden:!beforeBar,overlay_appeared:!!afterBar,labels_in_overlay:allLabelsInOverlay});})()
- expected: '{"overlay_was_hidden":true,"overlay_appeared":true,"labels_in_overlay":true}'
- tolerance: 0
- owner_wp: WP4
- status: baseline_known_failure
- notes: |
    The overlay is a conditional card gated on input_boolean.fusion_more_overlay. The test (1) toggles the boolean OFF and asserts no fixed-position card at bottom:56px exists, (2) toggles ON and asserts a fixed-position card at bottom:56px appears containing all 3 labels, (3) toggles OFF again. Scoping the label search to the overlay's own ha-card avoids the panel-content false positive (Kitchen/Energy/Automations strings exist in panels/*.yaml content too).

## TEST-314: Resize 1280 → 700 swaps shell live (no reload)
- viewport: 1280x900
- type: behavioural
- assertion: |
    (async()=>{const before=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length;if(typeof mcp_resize!=='function')return 'shim-missing';await mcp_resize(700,900);await new Promise(r=>setTimeout(r,800));const after=WALK_ALL(document,'hui-card').filter(c=>{const r=c.getBoundingClientRect();const k=c.firstElementChild;return k&&k.tagName==='BUTTON-CARD'&&Math.abs(r.width-72)<2&&r.height>40&&r.height<70;}).length;await mcp_resize(1280,900);await new Promise(r=>setTimeout(r,800));return JSON.stringify({before,after,fell_to_zero:after===0});})()
- expected: "fell_to_zero\":true"
- tolerance: regex
- owner_wp: WP4
- status: baseline_known_failure
- notes: |
    state-switch + entity:mediaquery should re-evaluate the active branch on viewport resize, swapping shells without page reload. Uses runner-provided `mcp_resize(w,h)` shim — falls back to 'shim-missing' if absent. Manual check: open dashboard at 1280, drag window to 700 — sidebar disappears, bottom tab bar appears, no page reload.

## TEST-315: Visual diff at 1280 vs WP2 baseline
- viewport: 1280x900
- type: visual_regression
- assertion: |
    capture_screenshot('wp4_1280px.png')
- expected: "match-or-capture"
- tolerance: manual
- owner_wp: WP4
- status: baseline_known_failure
- notes: Only difference from WP2's 1280 baseline should be the dropped −84px margin (visible as a small left-edge shift of the dashboard wrapper). Anything else (KPI tile layout, room cards, scenes row) is regression. Manual review against WP2 baseline screenshot.


---

## Total: 65 tests

| Category | Count | Status (post-WP2 deploy, pre-WP3 implementation) |
|----------|-------|--------|
| DOM assertion | 29 | 11 WP1 baseline + 2 WP1 baseline_known_failure (TEST-007, TEST-008) + 2 WP2 baseline (TEST-101, TEST-102) + 1 WP2 baseline_known_failure (TEST-103, harness limit) + 6 WP3 baseline (TEST-200, 201, 204, 207, 209, 211) + 7 WP3 baseline_known_failure (TEST-202, 203, 205, 206, 208, 210, 212) |
| Visual regression | 4 | All WP1 baseline (manual diff) |
| Behavioural | 5 | 3 WP1 baseline + 2 WP2 baseline (TEST-104, TEST-108) |
| YAML schema | 6 | 2 WP1 baseline + 1 WP2 baseline (TEST-100) + 3 WP2 baseline (TEST-105, TEST-106, TEST-107 — flipped post-WP2 deploy) |
| DOM assertion | 28 | 11 WP1 baseline + 2 WP1 baseline_known_failure (TEST-007, TEST-008) + 3 WP2 baseline (TEST-101, TEST-102, TEST-103) + 12 WP4 baseline_known_failure (TEST-300..311) |
| Visual regression | 5 | 4 WP1 baseline (manual diff) + 1 WP4 baseline_known_failure (TEST-315) |
| Behavioural | 8 | 3 WP1 baseline + 2 WP2 baseline (TEST-104, TEST-108) + 3 WP4 baseline_known_failure (TEST-312, TEST-313, TEST-314) |
| YAML schema | 6 | 2 WP1 baseline + 1 WP2 baseline (TEST-100) + 3 WP2 baseline_known_failure (TEST-105, TEST-106, TEST-107) |
---

| Entity existence | 3 | All WP1 baseline |
| Template eval | 2 | All WP1 baseline |

**Pre-WP2-implementation baseline:** 31 passing (25 WP1 + 6 WP2 regression tests) + 5 known-failures (2 WP1 sidebar + 3 WP2 file_system tests pending extraction). With `--allow-baseline-failures`, exit 0; without, exit 1.

**Post-WP2-implementation:** WP2's 3 file_system tests (TEST-105, TEST-106, TEST-107) flip to `baseline`; TEST-103 flips to `baseline_known_failure` per the WP2 deploy correction (harness can't reach 700-narrow trigger).

**Pre-WP3-implementation (current state on `main`):** 39 passing (25 WP1 + 8 WP2 + 6 WP3 regression guards) + 10 known-failures (2 WP1 sidebar + 1 WP2 narrow-fingerprint + 7 WP3 column-count / min-width). With `--allow-baseline-failures`, exit 0.

**Post-WP3-implementation:** WP3 swap of fixed grids → `auto-fit minmax`. WP3's 3 harness-reachable failures (TEST-202, TEST-205, TEST-212) flip to `baseline`. The WP3 375-px column-count tests (TEST-203, 206, 208, 210) require real-device verification and stay `baseline_known_failure` until a phone-emulation harness lands.

**WP4 contribution:** 16 new tests (TEST-300..315) all currently `baseline_known_failure` until Edgar verifies on real iPhone. Once verified, the 12 phone-only tests + TEST-007/008 (sidebar at narrow) flip to `baseline` because the dashboard at <871px no longer renders the sidebar at all (the phone branch shows the bottom-tab bar instead).

Phase 7 closes when WP3 + WP4 + WP5 ship and every WP1/WP4 sidebar known-failure flips. At that point, run the full suite without `--allow-baseline-failures` and require 65/65 green.

---

## Adding tests in subsequent WPs

Each WP must:

1. Add new tests to the appropriate ID range (TEST-014–020 for more DOM, TEST-025–030 for more visual, TEST-034–040 for more behavioural, TEST-043–050 for YAML, TEST-054–060 for entity, TEST-063–070 for template).
2. Run the suite — new tests must fail (TDD discipline).
3. Implement the WP's YAML/config changes.
4. Run the suite — every new test passes; no `baseline` test regresses; `baseline_known_failure` entries WP owns flip to `baseline`.
5. Gate 2 the changes (the test additions are part of the Gate 2 reviewer's scope).

Tests must be **stable**. Flaky tests are worse than no tests — drop a test rather than ship it flaky.
