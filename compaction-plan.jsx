import { useState } from "react";

const proposals = [
  // ── CHANGELOG ──────────────────────────────────────────────────────────────
  {
    id: "C1", file: "CHANGELOG.md", action: "Drop",
    title: "2026-04-13 — Context compaction entry",
    before: `## 2026-04-13 — Context compaction\n\nCompacted CHANGELOG from 252→~90 lines. Dropped meta-compaction record...`,
    after: "[removed — meta entry, no signal about the HA setup]",
    defaultChecked: true,
  },
  {
    id: "C2", file: "CHANGELOG.md", action: "Summarise → Activity Log",
    title: "BubbleDash v1 domain redesign (2026-04-14)",
    before: "## 2026-04-14 — BubbleDash v1 domain redesign\n[25-line entry with tab structure, excluded entities, backup ID]",
    after: "| 2026-04-14 | BubbleDash v1 — domain-type tabs (Lighting/Heating/Media/System). Basic tiles, no popups. Backup `31d33495`. | dashboard | Superseded by v2 same session |",
    defaultChecked: true,
  },
  {
    id: "C3", file: "CHANGELOG.md", action: "Summarise → Activity Log",
    title: "Agent workflow redesign (2026-04-14)",
    before: "## 2026-04-14 — Agent workflow redesign\n[15-line entry describing ha-code-reviewer, new gate structure, old files kept]",
    after: "| 2026-04-14 | Agent workflow redesign — `ha-code-reviewer.md` added to `.claude/agents/`. Gate 3 standardised pipeline in INSTRUCTIONS.md. Decision in DECISIONS.md. | agents/ | Live |",
    defaultChecked: true,
  },
  {
    id: "C4", file: "CHANGELOG.md", action: "Compress",
    title: "BubbleDash v2 enhanced (2026-04-14) — drop config hash + entity corrections detail",
    before: `**Entity corrections vs plan**: Dynamic lighting booleans confirmed as \`input_boolean.kitchen_motion_light_dynamic\` / ...\n**New config hash**: \`3c1460b7d76a0549\` (28,034 bytes).`,
    after: "[those 2 lines removed; keep tabs structure, backup ID, system health, open trace note]",
    defaultChecked: true,
  },
  {
    id: "C5", file: "CHANGELOG.md", action: "Compress",
    title: "Late Night Light Shutoff — drop 'Also done this session' sub-section",
    before: `### Also done this session\nSet up agent folder: created \`Home Automation/.claude/agents/\` with gate2-approach-critic.md and gate3-plan-critic.md. Tested the full Gate 1→2→3→4 workflow with critic agents in the loop. Critics ran 4 revision cycles...`,
    after: "[removed — covered by C3/agent workflow entry]",
    defaultChecked: true,
  },
  {
    id: "C6", file: "CHANGELOG.md", action: "Summarise → Activity Log",
    title: "Vacation mode Zocci cleanup (2026-04-13)",
    before: "## 2026-04-13 — Vacation mode Zocci cleanup\n[13-line entry with 3 automation edits, verification notes]",
    after: "| 2026-04-13 | Vacation mode Zocci cleanup — removed 3 dead switch actions (HTTP 500). Notify-only pattern. Backup `MCP_2026-04-13_18:21:29`. Decision in DECISIONS.md. | automations | Clean |",
    defaultChecked: true,
  },
  {
    id: "C7", file: "CHANGELOG.md", action: "Compress",
    title: "Vacation mode system (2026-04-13) — drop automation inventory, keep known issue",
    before: "## 2026-04-13 — Vacation mode system\n[18-line entry with full automation/helper list, health check note]",
    after: `## 2026-04-13 — Vacation mode system\n4 automations + 2 helpers built (vacation_mode toggle, end datetime, activate/end/deactivate/zocci-warning).\n🔴 **Known issue**: scene snapshots don't survive HA restart → heating restore will silently fail. Fix: replace with 3 \`input_text\` helpers. See BACKLOG #1.`,
    defaultChecked: true,
  },
  {
    id: "C8", file: "CHANGELOG.md", action: "Summarise → Activity Log",
    title: "Zocci deep clean reminder system (2026-04-13)",
    before: "## 2026-04-13 — Zocci deep clean reminder system\n[13-line entry with 3 automations + 1 helper, gate deviations note]",
    after: "| 2026-04-13 | Zocci deep clean — 3 automations + `input_boolean.zocci_deep_clean_needed`. ⚠️ No backup taken (Gate violation). | automations, helpers | Working |",
    defaultChecked: true,
  },
  {
    id: "C9", file: "CHANGELOG.md", action: "Summarise → Activity Log",
    title: "Monitoring system teardown (2026-04-12)",
    before: "## 2026-04-12 — Monitoring system teardown & stabilisation\n[19-line entry: problem, what removed, what kept, lesson learned]",
    after: "| 2026-04-12 | Monitoring teardown — removed 2 automations + 23 counter helpers. Self-triggering cascade (20×), DB 453→785 MB. Lesson + decision in DECISIONS.md. | automations, helpers | Resolved |",
    defaultChecked: true,
  },

  // ── PROFILE.md ─────────────────────────────────────────────────────────────
  {
    id: "P1", file: "PROFILE.md", action: "Update",
    title: "Automation count 23 → 24 + add Late Night Shutoff to Other section",
    before: `## Automations (23 total) *[updated: 2026-04-13]*\n...\n| Beamer → Uplight Front | ... |\n| Office Dimmer | automation.office_dimmer | Purpose/blueprint TBD |`,
    after: `## Automations (24 total) *[updated: 2026-04-14]*\n...\n| Beamer → Uplight Front | ... |\n| Office Dimmer | ... |\n| Late Night Light Shutoff | automation.late_night_light_shutoff_no_motion_check | At 23:00/00:00, turns off Kitchen/LR/Office if all motion sensors quiet for 30min |`,
    defaultChecked: true,
  },
  {
    id: "P2", file: "PROFILE.md", action: "Update",
    title: "Disk usage 10.1 GB → 11.1 GB (confirmed by health check)",
    before: "| Disk | 10.1 GB used / 28 GB total |",
    after:  "| Disk | 11.1 GB used / 28 GB total |",
    defaultChecked: true,
  },

  // ── BACKLOG.md ──────────────────────────────────────────────────────────────
  {
    id: "B1", file: "BACKLOG.md", action: "Remove superseded item",
    title: "Remove old item 3 'HA Control Dashboard — Improve'",
    before: `### 3. HA Control Dashboard — Improve\n**Goal**: Better overview and control of the house from a single dashboard.\n**Current state**: 2 dashboards exist... **Open questions**: What's missing? What device? Preferred style?`,
    after: "[removed — superseded by new item 2 'BubbleDash v3 — Decide Direction' which covers this more specifically]",
    defaultChecked: true,
  },
];

const ACTION_COLORS = {
  "Drop":                     "bg-red-100 text-red-700",
  "Summarise → Activity Log": "bg-yellow-100 text-yellow-700",
  "Compress":                 "bg-blue-100 text-blue-700",
  "Update":                   "bg-green-100 text-green-700",
  "Remove superseded item":   "bg-orange-100 text-orange-700",
};

const FILES = ["CHANGELOG.md", "PROFILE.md", "BACKLOG.md"];

const SIZE_INFO = {
  "CHANGELOG.md": { current: 172, target: 50,  unit: "active lines" },
  "PROFILE.md":   { current: 190, target: 150, unit: "active lines" },
  "BACKLOG.md":   { current: null, target: null, unit: null },
};

const SAVINGS = {
  C1: 5, C2: 24, C3: 14, C4: 3, C5: 8,
  C6: 12, C7: 12, C8: 12, C9: 18,
  P1: 0, P2: 0, B1: 12,
};

export default function CompactionPlan() {
  const [checked, setChecked] = useState(
    Object.fromEntries(proposals.map(p => [p.id, p.defaultChecked]))
  );
  const [expanded, setExpanded] = useState({});
  const [submitted, setSubmitted] = useState(false);

  const toggle = id => setChecked(c => ({ ...c, [id]: !c[id] }));
  const toggleExpand = id => setExpanded(e => ({ ...e, [id]: !e[id] }));

  const toggleAll = (file, val) => {
    const ids = proposals.filter(p => p.file === file).map(p => p.id);
    setChecked(c => Object.fromEntries(Object.entries(c).map(([k, v]) => [k, ids.includes(k) ? val : v])));
  };

  const approvedIds = proposals.filter(p => checked[p.id]).map(p => p.id);

  const projectedSavings = (file) =>
    proposals
      .filter(p => p.file === file && checked[p.id])
      .reduce((sum, p) => sum + (SAVINGS[p.id] || 0), 0);

  const handleSubmit = () => setSubmitted(true);

  if (submitted) {
    return (
      <div className="p-6 max-w-2xl mx-auto font-mono text-sm">
        <div className="bg-green-50 border border-green-300 rounded-lg p-4">
          <div className="font-bold text-green-800 mb-2">✅ Approved changes submitted</div>
          <div className="text-green-700 mb-3">Applying: {approvedIds.join(", ")}</div>
          <div className="text-xs text-green-600">
            {approvedIds.length} of {proposals.length} proposals accepted.
            Skipped: {proposals.filter(p => !checked[p.id]).map(p => p.id).join(", ") || "none"}.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 max-w-3xl mx-auto font-sans text-sm">
      <div className="mb-4">
        <h1 className="text-lg font-bold text-gray-900">Context Compaction Plan</h1>
        <p className="text-gray-500 text-xs mt-1">
          {proposals.length} proposals across {FILES.length} files · Review, adjust, then hit Apply
        </p>
      </div>

      {/* Size overview */}
      <div className="grid grid-cols-3 gap-3 mb-5">
        {FILES.map(f => {
          const info = SIZE_INFO[f];
          if (!info.current) return (
            <div key={f} className="bg-gray-50 border border-gray-200 rounded-lg p-3">
              <div className="font-semibold text-gray-700 text-xs">{f}</div>
              <div className="text-gray-400 text-xs mt-1">Stale item removal only</div>
            </div>
          );
          const projected = info.current - projectedSavings(f);
          const ok = projected <= info.target;
          return (
            <div key={f} className={`border rounded-lg p-3 ${ok ? "bg-green-50 border-green-200" : "bg-yellow-50 border-yellow-200"}`}>
              <div className="font-semibold text-gray-700 text-xs">{f}</div>
              <div className="mt-1 text-xs text-gray-600">
                <span className="font-mono">{info.current}</span> → <span className={`font-mono font-bold ${ok ? "text-green-700" : "text-yellow-700"}`}>{projected}</span>
                <span className="text-gray-400"> / target {info.target}</span>
              </div>
              <div className="text-xs text-gray-400 mt-0.5">{info.unit}</div>
            </div>
          );
        })}
      </div>

      {/* Proposals by file */}
      {FILES.map(file => {
        const fileProps = proposals.filter(p => p.file === file);
        const allChecked = fileProps.every(p => checked[p.id]);
        return (
          <div key={file} className="mb-5">
            <div className="flex items-center justify-between mb-2">
              <h2 className="font-bold text-gray-800">{file}</h2>
              <div className="flex gap-2 text-xs">
                <button onClick={() => toggleAll(file, true)}  className="text-blue-600 hover:underline">All</button>
                <button onClick={() => toggleAll(file, false)} className="text-blue-600 hover:underline">None</button>
              </div>
            </div>

            <div className="space-y-2">
              {fileProps.map(p => (
                <div key={p.id} className={`border rounded-lg ${checked[p.id] ? "border-gray-300 bg-white" : "border-gray-200 bg-gray-50 opacity-60"}`}>
                  <div className="flex items-start gap-3 p-3">
                    <input
                      type="checkbox"
                      checked={checked[p.id]}
                      onChange={() => toggle(p.id)}
                      className="mt-0.5 cursor-pointer"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-mono text-xs text-gray-400">{p.id}</span>
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${ACTION_COLORS[p.action] || "bg-gray-100 text-gray-600"}`}>
                          {p.action}
                        </span>
                        <span className="text-gray-700 text-sm">{p.title}</span>
                      </div>
                      <button
                        onClick={() => toggleExpand(p.id)}
                        className="text-xs text-blue-500 hover:underline mt-1"
                      >
                        {expanded[p.id] ? "▲ hide diff" : "▼ show diff"}
                      </button>
                      {expanded[p.id] && (
                        <div className="mt-2 space-y-2">
                          <div>
                            <div className="text-xs font-semibold text-red-600 mb-1">Before</div>
                            <pre className="text-xs bg-red-50 border border-red-100 rounded p-2 whitespace-pre-wrap text-gray-700 overflow-auto max-h-32">{p.before}</pre>
                          </div>
                          <div>
                            <div className="text-xs font-semibold text-green-600 mb-1">After</div>
                            <pre className="text-xs bg-green-50 border border-green-100 rounded p-2 whitespace-pre-wrap text-gray-700 overflow-auto max-h-32">{p.after}</pre>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        );
      })}

      {/* Summary + Apply */}
      <div className="sticky bottom-0 bg-white border-t border-gray-200 pt-3 mt-4">
        <div className="flex items-center justify-between">
          <div className="text-xs text-gray-500">
            {approvedIds.length} of {proposals.length} selected ·{" "}
            ~{Object.values(SAVINGS).reduce((a,b)=>a+b,0)} lines freed if all accepted
          </div>
          <button
            onClick={handleSubmit}
            className="bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium px-4 py-2 rounded-lg"
          >
            Apply Selected ({approvedIds.length})
          </button>
        </div>
      </div>
    </div>
  );
}
