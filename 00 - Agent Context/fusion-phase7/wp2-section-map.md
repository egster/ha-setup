# WP2 — fusion.yaml section map

_Source: `config/dashboards/fusion.yaml` at `phase7/wp2-restructure` HEAD (post-merge of `origin/main` 2026-04-26 with HA Settings panel + low-battery commits). 1731 lines._

Boundaries below are the line ranges that each new include file claims. **Move verbatim — do not edit content during extraction.** WP3/WP4 will reshape; WP2 only relocates.

```
fusion.yaml (current monolith)
│
├── 1–32     Header comments (Phase 6n/m/l/k/j summary; "DO NOT EDIT VIA HA UI")
│            → discarded (entry-point gets a fresh, shorter header)
│
├── 33       title: Fusion
│            → kept in entry-point fusion.yaml
│
├── 34–215   button_card_templates: (~12 templates)
│            templates: fusion_nav_icon, fusion_floor_header, fusion_room_header,
│                       fusion_room_row_lights, fusion_room_row_climate,
│                       fusion_room_row_media, fusion_room_row_motion,
│                       fusion_kpi_tile, fusion_status_badge, …
│            → templates.yaml
│
├── 216–1727 views: (single view, type: panel)
│   ├── 217–220   view header (title/path/type/cards)
│   │             → kept in entry-point fusion.yaml
│   │
│   └── 221–1727 outer custom:layout-card (THE responsive bug lives here on line 232:
│                margin: 0 16px 0 -84px)
│       ├── 222–236  layout config (grid-template-areas: statusbar / sidebar+content)
│       │            → shell.yaml (top of file)
│       │
│       └── 237–1727 cards: [3 children]
│           ├── 238–417   statusbar layout-card (grid-area: statusbar)
│           │             children: person, edphone, ipad, temp, wan, dl, ul (+ spacer)
│           │             → statusbar.yaml
│           │
│           ├── 418–591   sidebar custom:mod-card (grid-area: sidebar)
│           │             content: vertical-stack of 7 fusion_nav_icon + 1 kiosk toggle
│           │             → shell.yaml (the rest)
│           │
│           └── 592–1727 content vertical-stack (grid-area: content)
│               cards: 7 conditional cards (one per panel)
│               ├── 596–1150   panel home          → panels/home.yaml
│               ├── 1151–1194  panel kitchen       → panels/kitchen.yaml
│               ├── 1195–1277  panel climate       → panels/climate.yaml
│               ├── 1278–1331  panel media         → panels/media.yaml
│               ├── 1332–1516  panel network       → panels/network.yaml
│               ├── 1517–1650  panel energy        → panels/energy.yaml
│               └── 1651–1727  panel automations   → panels/automations.yaml
│                              (visually labelled "HA SETTINGS" since 2026-04-26;
│                               input_select option value still 'automations' for
│                               backwards-compat)
│
└── 1728–1731 kiosk_mode: (top level)
              → kept in entry-point fusion.yaml
```

## File / line accounting

| New file                     | Lines from monolith | Approx new size |
|------------------------------|---------------------|-----------------|
| `fusion.yaml` (entry-point)  | 33, 1728–1731 + view header + new !include refs | < 100 |
| `fusion/templates.yaml`      | 34–215              | ~182            |
| `fusion/statusbar.yaml`      | 238–417             | ~180            |
| `fusion/shell.yaml`          | 221–236, 418–591    | ~190            |
| `fusion/panels/home.yaml`    | 596–1150            | ~555            |
| `fusion/panels/kitchen.yaml` | 1151–1194           | ~44             |
| `fusion/panels/climate.yaml` | 1195–1277           | ~83             |
| `fusion/panels/media.yaml`   | 1278–1331           | ~54             |
| `fusion/panels/network.yaml` | 1332–1516           | ~185            |
| `fusion/panels/energy.yaml`  | 1517–1650           | ~134            |
| `fusion/panels/automations.yaml` | 1651–1727       | ~77             |
| Total relocated              | 1697 lines          | sum ≈ 1701      |

(34 lines lost to the comment header replacement; the rest is verbatim relocation.)

## Indentation rule

Every extracted block needs to lose its current parent indentation so it becomes valid YAML at the new file's root. For each extraction:

- The shell.yaml will hold the outer layout-card's *contents* (since the entry-point uses `!include fusion/shell.yaml` as the single card under `views[0].cards`, the shell.yaml itself needs to be a single mapping at the top — i.e. the `type: custom:layout-card` line is column 0 in shell.yaml).
- statusbar.yaml's root must be a single mapping (the statusbar layout-card). When shell.yaml does `cards: - !include statusbar.yaml`, !include resolves to the file's content as a mapping, slotting in correctly.
- Each panel file's root is the `type: conditional` mapping. The content vertical-stack in shell.yaml does `cards: [- !include panels/home.yaml, - !include panels/kitchen.yaml, ...]`.
- templates.yaml's root is the `button_card_templates:` value — a mapping of template name → template body. Entry-point uses `button_card_templates: !include fusion/templates.yaml`.

## kiosk_mode placement

Top-level `kiosk_mode:` block (lines 1728–1731 of monolith) stays in entry-point fusion.yaml. It is not a view, not a card, not a template — it is a sibling of `title:` and `views:` at dashboard root.

## What stays out of WP2 scope

- The bug (`margin: 0 16px 0 -84px` on line 232) is **moved verbatim** into shell.yaml. WP4 fixes it.
- Popups directory exists but stays empty (placeholder for WP5). The `_template.yaml` is WP5a's deliverable, not WP2's.
- No content edits — verbatim relocation only. Visual diff must be < 1% post-restructure (TEST-101 to 103).

## !include shape contract

The HA YAML loader (`PyYAML` extension) supports:
- `!include path/to/file.yaml` — resolves to the file's parsed YAML root (mapping or sequence)
- `!include_dir_list path/` — resolves to a list of every `*.yaml` in the directory
- `!include_dir_merge_list path/` — resolves to a flat list, merging top-level lists from each file

WP2 uses **only `!include`** (single-file) — the entry-point and shell.yaml each pull in specific files by name. `!include_dir_list` for the panels was considered but rejected: explicit `!include` ordering keeps the conditional cards in deterministic visual order regardless of filesystem ordering, and downstream WPs (WP3 / WP4 / WP5) can swap individual panel files without re-ordering risk.
