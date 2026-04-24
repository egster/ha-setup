# FUSION Dashboard — Design Spec
_Version: 1.0 | Created: 2026-04-24 | Source: ha-dashboard-design artifact (FUSION tab)_
_Read alongside: BACKLOG.md → "FUSION Dashboard — Full Implementation"_

---

## Purpose of this document

This spec is the single reference for implementing the FUSION dashboard in Home Assistant Lovelace. It covers visual tokens, layout structure, every panel's content + entity mappings, and open questions. Use it at the start of every implementation session — don't derive intent from the HTML mockup.

---

## 1. Visual Tokens

These are the design's CSS custom properties. Use them in `card-mod` style blocks throughout.

```css
/* Backgrounds */
--bg:    #090909   /* page / outermost background */
--s1:    #111      /* sidebar, status bar, inner panels */
--s2:    #161616   /* cards, room tiles, chart wrappers */
--s3:    #1e1e1e   /* input fields, inner elements, toggle tracks */

/* Borders */
--bd:    #2a2a2a   /* all card/section borders */

/* Text */
--t1:    #e8e8e8   /* primary text */
--t2:    #888      /* secondary / labels */
--t3:    #555      /* tertiary / disabled / separators */

/* Accent colours */
--acc:   #4f8ef7   /* blue — interactive, setpoints, sliders */
--grn:   #4caf6e   /* green — occupied, on, online */
--red:   #e05555   /* red — errors, alerts */
--amb:   #d4a843   /* amber — warnings, power */

/* Typography */
font-family: 'Inter', system-ui, sans-serif
font-size base: 13px
```

**Chip colours (occupancy/state badges on room cards):**
```css
/* ON chip */  background:#1a2a1e; border:#2d5237; color:var(--grn)
/* AUTO chip */ background:#1a1e2a; border:#2d3d52; color:var(--acc)
/* BASE chip */ background:var(--s3); border:var(--bd); color:var(--t2)
```

**Occupied room card:** `border-left: 3px solid var(--grn)`

---

## 2. Layout Structure

```
┌─────────────────────────────────────────────────────┐
│ STATUS BAR (36px, fixed, z-index:9999, bg:#000)     │
├────────┬────────────────────────────────────────────┤
│  ICON  │                                            │
│ SIDE-  │         MAIN CONTENT PANEL                 │
│  BAR   │         (overflow-y: auto)                 │
│ (58px) │                                            │
│  bg:   │                                            │
│  --s1  │                                            │
└────────┴────────────────────────────────────────────┘
```

**Implementation card:** `custom:layout-card` with CSS grid:
- `grid-template-rows: 36px 1fr`
- `grid-template-columns: 58px 1fr`
- Status bar spans both columns (row 1)
- Sidebar = col 1, row 2
- Content = col 2, row 2

**Panel switching:** `input_select.fusion_panel` with options:
`home | kitchen | climate | media | network | energy | automations`

Main content area renders different card stacks based on the input_select state via `custom:config-template-card`.

---

## 3. Status Bar

**Height:** 36px | **Background:** `#000` | **Border-bottom:** `1px solid #222`

| Element | Position | Entity | Display |
|---------|----------|--------|---------|
| Presence dot | Left | `person.edgar` | Pulsing green dot + "Edgar · Home" |
| iPad badge | Left | `device_tracker.ipad` | "iPad 🏠" (or Away) |
| Edphone badge | Left | `device_tracker.edphone` (confirm exact ID) | "Edphone 🏠" |
| Outdoor temp | Right | `sensor.air_conditioning_bedroom_outside_temperature` (⚠️ unavailable) OR `weather.forecast_home` temperature attribute | "11°C" |
| WAN status | Right | Confirm ASUS BQ16 entity — likely `binary_sensor.wan_online` or similar | Green dot "●" |
| Download speed | Right | Confirm ASUS BQ16 entity — likely `sensor.bq16_download_speed` | "↓ 4.3 KiB/s" |
| Upload speed | Right | Confirm ASUS BQ16 entity — likely `sensor.bq16_upload_speed` | "↑ 19.4 KiB/s" |

⚠️ **Outdoor temp fallback:** `sensor.air_conditioning_bedroom_outside_temperature` is currently unavailable (Panasonic setup_error). Use `weather.forecast_home` attribute `temperature` as fallback. If also unavailable, show `input_number.monitoring_outdoor_temperature` (updated by temperature poller automation).

⚠️ **ASUS BQ16 entity IDs are unconfirmed.** Run `ha_search_entities` for "bq16" or "asus" before implementing the status bar.

---

## 4. Icon Sidebar

**Width:** 58px | **Background:** `--s1` | **Border-right:** `1px solid --bd`

Nav icons: 42×42px, `border-radius: 10px`. Active state: `--s2` bg + `--bd` border + `--t1` text colour.

| Position | Icon | Label | Panel ID | HA relevance |
|----------|------|-------|----------|--------------|
| 1 | 🏠 | Home | `home` | Overview — rooms + scenes |
| 2 | 🍳 | Kitchen | `kitchen` | Kitchen-specific controls |
| — | separator | | | `width:28px; height:1px; bg:--bd` |
| 3 | 🌡 | Climate | `climate` | All climate entities |
| 4 | 🎵 | Media | `media` | All media players |
| 5 | 📡 | Network | `network` | ASUS BQ16 + device trackers |
| 6 | ⚡ | Energy | `energy` | Power + energy sensors |
| 7 | ⚙️ | Automations | `automations` | All automations |

**Implementation:** Each icon = `custom:button-card` with `tap_action: call-service: input_select.select_option`. Active highlight via `card-mod` template checking `states['input_select.fusion_panel'].state`.

---

## 5. Panel: Home

### 5a. Hero Strip (6 tiles, single row)

Tile styling: `--s2` bg, `1px solid --bd` border, `border-radius: 10px`, 12px 10px padding.
- Icon: 20px
- Value: 18px bold
- Label: 10px uppercase `--t2`
- `ok` variant: value colour `--grn`
- `warn` variant: value colour `--amb`

| # | Icon | Value | Label | Colour | Entity/Template |
|---|------|-------|-------|--------|-----------------|
| 1 | 🏠 | 3/3 | Rooms Occupied | green | Template: count of motion sensors `on` in occupied areas. Target areas: `living_room`, `kitchen`, `office`, `entrance`, `garage`, `bedroom`, `jona_s_room` |
| 2 | 💡 | 7 | Lights On | default | Template: count of `light.*` entities with `state = on` |
| 3 | 🌡 | 21.5° | Avg Temp | default | Template: average of `climate.living_room_area`, `climate.kitchen_area`, `climate.office_area` current temperatures |
| 4 | ⚡ | 1.34kW | Power Now | amber/warn | Confirm energy sensor entity — likely from HA Energy dashboard `sensor.current_power` or similar |
| 5 | 📡 | Online | Network | green | WAN status entity (see status bar section) |
| 6 | 🎵 | 2 | Playing | default | Template: count of `media_player.*` with `state = playing` |

### 5b. Floor-Grouped Room Grid

One section per floor. Section header: floor icon + floor name (12px bold uppercase `--t2`) + horizontal rule.
Grid: 3 columns, 10px gap.

**MAIN FLOOR** (icon: 🏠)
| Room | area_id | Occupancy entity | Climate entity | Light circuits | Media |
|------|---------|------------------|----------------|----------------|-------|
| Living Room 🛋 | `living_room` | Motion sensor (confirm entity) | `climate.living_room_area` (floor heat, Wiser) | Ceiling, Uplights (Front/Back L/R) | Sonos Arc group + HomePod |
| Kitchen 🍳 | `kitchen` | `binary_sensor.kitchen_motion` (confirm) | `climate.kitchen_area` (floor heat, Wiser) | Ceiling, Counter | Kitchen speakers |
| Office 💼 | `office` | `binary_sensor.office_motion` (confirm) | `climate.office_area` (floor heat, Wiser) | Ceiling, Desk | — |

**UPPER FLOOR** (icon: 🛏)
| Room | area_id | Occupancy entity | Climate entity | Light circuits | Media |
|------|---------|------------------|----------------|----------------|-------|
| Bedroom 🛏 | `bedroom` | `binary_sensor.bedroom_motion` (confirm) | `climate.air_conditioning_bedroom` (AC, ⚠️ unavailable) | Ceiling (unavailable — wall-switched), Bedside (unavailable) | Upstairs speaker |
| Jona's Room 🌟 | `jona_s_room` | None configured | None | Jona Bedroom Left/Right (Hue) | `media_player.jona_speaker` |

**DOWNSTAIRS** (icon: ⬇️)
| Room | area_id | Occupancy entity | Auto | Light circuits |
|------|---------|------------------|------|----------------|
| Entrance 🚪 | `entrance` | Motion sensor (×2) | ✅ motion light | Entrance Left/Middle/Right |
| Garage 🏠 | `garage` | `binary_sensor.garage_motion` (confirm) | ✅ motion light | Main garage light |

**OUTSIDE** (icon: 🌿)
| Room | area_id | Occupancy entity | Light circuits |
|------|---------|------------------|----------------|
| Outdoor 🌿 | `outdoor` | None | Garden lights, Porch lights |

**Room card chip logic:**
- `Occupied` chip (green): shown if occupancy sensor = `on`
- `N light(s)` chip (green): count of lights `on` in that area
- `Auto` chip (blue): shown for Entrance and Garage (motion-light automations active)
- `Floor ♨` chip: shown if climate entity is Wiser floor heat (kitchen, living_room, office)
- `AC` chip: shown if climate entity is Panasonic (bedroom)
- `▶ Playing` chip (green): shown if any media_player in the area = `playing`

**Room card tap action:** Opens Bubble Card popup (see Section 8).

### 5c. Scenes Row

Pill buttons (border-radius: 20px). Active: `#1a2236` bg, `--acc` border + text.

| Label | Entity |
|-------|--------|
| 🌅 Good Morning | `scene.good_morning` (confirm entity exists) |
| 🌙 Evening | `scene.evening` (confirm) |
| 🎬 Movie Night | `script.movie_mode` (confirmed — exists) |
| 💼 Work Mode | `scene.work_mode` (confirm) |
| 🎉 Party | `scene.party` (confirm) |
| 🔒 Away | Vacation mode automation trigger or `scene.away` (confirm) |
| ⚫ All Off | `script.goodnight` OR new script (see Backlog: Goodnight Kill Switch) |
| 🕯 Cosy | `scene.cosy` (confirm) |

⚠️ **Confirm all scene entity IDs before wiring.** Several may not exist yet — create if missing or omit.

---

## 6. Panel: Kitchen

2×2 card grid (`grid-template-columns: 1fr 1fr`, gap 12px).

| Card | Content | HA Implementation |
|------|---------|-------------------|
| ⏱ Timers | Timer display (tabular nums, `--acc` colour, 22px bold) + start/pause/reset per timer | `timer.*` helper entities. Create `timer.kitchen_1` and `timer.kitchen_2` if not present. Native `entities` card with timer rows. |
| 🛒 Shopping List | Input field + add button + checkbox list | Native `todo` card against `todo.shopping_list`. Requires `todo` integration enabled. |
| 📖 Recipes | List of recipe names with tap-to-open | No native HA solution. Use `markdown` card with static curated list + URLs. Defer dynamic recipes unless a recipe integration is added. |
| ✨ Kitchen Scenes | 4 scene buttons (pill style) | Morning Brew, Cooking Mode, Dinner Ambience, Cleaning Mode — create as `scene.*` if not present |

---

## 7. Panel: Climate

**Grid:** 4 columns for climate cards.

**Climate card anatomy:**
- Room name: 11px `--t2`
- Current temp: 28px bold
- Setpoint: 11px with `--acc` highlight — "Setpoint 22°"
- Progress bar: 3px height, gradient from `--acc` to `--red`
- Type badge: 9px uppercase `--t3` — "Floor Heating" or "AC · Panasonic"

| Room | Entity | Type | Note |
|------|--------|------|------|
| Living Room | `climate.living_room_area` | Floor Heating (Wiser) | |
| Kitchen | `climate.kitchen_area` | Floor Heating (Wiser) | |
| Office | `climate.office_area` | Floor Heating (Wiser) | |
| Bedroom | `climate.air_conditioning_bedroom` | AC · Panasonic | ⚠️ currently unavailable |

**Chart below grid:** `custom:apexcharts-card` — temperature history 24h.
- Series: LR (`--acc` blue), KI (`--grn` green), OF (`--amb` amber)
- Entities: climate current_temperature attributes for each room
- Requires `statistics` domain retention for historical data

---

## 8. Panel: Media

**Grid:** 3 columns.

**Media card anatomy:**
- Room name: 11px `--t2`
- Album art thumbnail: 40×40px gradient bg + 🎵 emoji placeholder
- Track name: 12px bold, truncated
- Artist: 10px `--t2`
- Controls: ⏮ Prev / ⏸ Play▶ / ⏭ Next buttons (28px circle)
- Volume slider: `accent-color: --acc`, 3px height

| Room | Entity | Note |
|------|--------|------|
| Living Room | Sonos group or `media_player.sonos_arc` (confirm group entity) | Surround: Arc + Sub Mini + Era 300 ×2 |
| Living Room | `media_player.homepod` (confirm) | HomePod — may report separately |
| Kitchen | Kitchen speaker entity (confirm) | 2× speakers — confirm if grouped |
| Bedroom | Upstairs speaker entity (confirm) | |
| Jona's Room | `media_player.jona_speaker` | Google Nest Mini |

**Beamer card** (bonus): Static card showing VisionMaster Pro state. Entity likely `media_player.visionmaster_pro` or Android TV entity (confirm). Note: reports `idle` not `playing` on HDMI sources — show state verbatim.

**Implementation:** Use existing `mini-media-player` (v1.16.11, already installed via HACS) rather than building from scratch.

---

## 9. Panel: Network

**ASUS ZenWiFi BQ16 (CA38)**. ⚠️ All entity IDs below are unconfirmed — search before implementing.

**3 stat tiles (row):**

| Tile | Entity | Expected value |
|------|--------|----------------|
| WAN Status | `binary_sensor.wan_online` or similar | "Online" (green) |
| Uptime | `sensor.bq16_uptime` or similar | "11d 13h" |
| Throughput | `sensor.bq16_download_speed` + `sensor.bq16_upload_speed` | "↓ 4.3 KiB/s / ↑ 19.4 KiB/s" |

Stat tile styling: `--s2` bg, `1px solid --bd`, radius 10px, 14px padding.
- Label: 10px uppercase `--t2`
- Value: 24px bold
- Sub-label: 10px `--t3`
- WAN Online value: `--grn`

**Throughput chart:** `custom:apexcharts-card` line chart — DL (`--acc` blue filled) + UL (`--amb` amber filled), last 12h.

**Device tracker table:**

| Device | Entity | Expected state |
|--------|--------|----------------|
| Edphone | `device_tracker.edphone` (confirm exact ID) | Home |
| iPad | `device_tracker.ipad` (confirm exact ID) | Home |

---

## 10. Panel: Energy

**2 stat tiles (row):**

| Tile | Entity | Note |
|------|--------|------|
| Current Power | Confirm — likely from HA Energy dashboard | Target display: "1.34 kW" (amber) |
| Today | Confirm — `sensor.energy_today` or from energy dashboard | Target display: "8.2 kWh" (green) |

⚠️ Energy sensor entity IDs depend on whether the HA Energy dashboard is configured. Check `ha_search_entities` for "energy" and "power" before implementing.

**Power chart:** `custom:apexcharts-card` bar chart — hourly power (W) over current day.

---

## 11. Panel: Automations

**List layout** — each row: icon + name + trigger type + last triggered + on/off toggle.

**Implementation:** `custom:auto-entities` filtered to `domain: automation`, rendered as `entities` card.
- `secondary_info: last-triggered` for last run timestamp
- Toggle = native HA automation enable/disable

No entity mapping needed — auto-entities discovers all automations dynamically.

---

## 12. Room Popups (Bubble Card)

Triggered by tapping any room card in the Home panel floor grid.

**Modal anatomy:**
- Backdrop: `rgba(0,0,0,.7)` overlay
- Modal container: `--s2` bg, `1px solid --bd`, radius 14px, 20px padding, 340px wide, max-height 70vh
- Header: room emoji + room name + ✕ close button

**Popup content by section:**

**Lights section** (all rooms):
- One row per light circuit in the area
- Row: light name (flex:1, 12px) + brightness slider (`accent-color: --acc`) + dim% value (11px `--t2`)
- Use `custom:mushroom-light-card` or native light entity rows

**Heat/Climate section** (rooms with climate):
| Room | Entity | Type shown |
|------|--------|-----------|
| Living Room | `climate.living_room_area` | "Floor Heating" |
| Kitchen | `climate.kitchen_area` | "Floor Heating" |
| Office | `climate.office_area` | "Floor Heating" |
| Bedroom | `climate.air_conditioning_bedroom` | "AC · Panasonic" (⚠️ unavailable) |

Controls: `−` / setpoint value / `+` buttons (0.5° step) + current temp display.

**Media section** (Living Room, Office only):
- Show `mini-media-player` card inline

---

## 13. Confirmed Missing / Open Questions

Before implementing, resolve these unknowns:

1. **ASUS BQ16 entity IDs** — WAN status, uptime, download speed, upload speed. Run `ha_search_entities` for "bq16", "asus", "wan", "router".
2. **Energy sensor entity IDs** — current power, today's kWh. Check HA Energy dashboard config.
3. **Outdoor temp fallback chain** — `sensor.air_conditioning_bedroom_outside_temperature` (primary, unavailable) → `weather.forecast_home` temperature (secondary) → `input_number.monitoring_outdoor_temperature` (polled fallback).
4. **Scene entity IDs** — Good Morning, Evening, Work Mode, Party, Away, Cosy. Run `ha_search_entities` for "scene".
5. **Device tracker entity IDs** — Exact IDs for Edphone and iPad trackers.
6. **Occupancy per room** — Motion sensor binary_sensor IDs per area. Several are inferred. Confirm before templating the hero tile + room card occupied state.
7. **Bedroom lights** — Wall-switched off, entities unavailable. Popup should handle `unavailable` state gracefully (show dimmed row, no slider interaction).
8. **Living Room media entity** — Multiple players (Sonos group, HomePod). Determine which entity to feature on the media card. Likely the Sonos group if one exists.

---

## 14. Implementation Order

Per the BACKLOG entry, recommended phase sequence:

```
Phase 0  →  Install layout-card, apexcharts-card, config-template-card
            Create input_select.fusion_panel helper
Phase 1  →  Shell: status bar + sidebar + panel switcher (architecture proof)
Phase 2  →  Home panel (hero strip + floor grid + scenes)
Phase 3  →  Automations → Climate → Media → Energy → Network (1 hr each)
Phase 4  →  Room popups (adapt existing Bubble Card popups)
Phase 5  →  Kitchen panel (timers + shopping list + scenes; defer recipes)
Phase 6  →  Polish (card-mod global styling, iPad test, cutover)
```

**First session target:** Complete Phase 0 + Phase 1. Validates the architecture before any panel content is built.
