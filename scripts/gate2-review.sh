#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# gate2-review.sh — Assemble a ready-to-paste ha-code-reviewer prompt
#
# Usage:
#   ./scripts/gate2-review.sh config/packages/pomodoro.yaml "<original request>"
#
# Prints to stdout a self-contained prompt block that can be fed to the
# ha-code-reviewer subagent. Bundles:
#   - the original request (arg 2, or read from stdin if omitted)
#   - the full file contents (arg 1)
#   - pointers to INSTRUCTIONS.md and DECISIONS.md
#   - a PROFILE.md availability note
#
# Rule A1 (2026-04-19 meta session): this exists so the Gate 2 review ceremony
# stays cheap — agents should not skip the reviewer because prompt assembly
# feels tedious.
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-package-yaml> [<original-request>]" >&2
  echo "  If <original-request> is omitted, read it from stdin." >&2
  exit 1
fi

FILE="$1"
if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE" >&2
  exit 1
fi

if [ $# -ge 2 ]; then
  REQUEST="$2"
else
  echo "Paste the original request (end with Ctrl-D):" >&2
  REQUEST="$(cat)"
fi

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
INSTRUCTIONS="$REPO_ROOT/00 - Agent Context/INSTRUCTIONS.md"
DECISIONS="$REPO_ROOT/00 - Agent Context/DECISIONS.md"
PROFILE="$REPO_ROOT/00 - Agent Context/PROFILE.md"

if [ -f "$PROFILE" ]; then
  PROFILE_NOTE="PROFILE.md is available at the path above — read it directly."
else
  PROFILE_NOTE="PROFILE.md is NOT available in this environment (gitignored for public-repo safety). Entity IDs referenced in the YAML should be sanity-checked against HA state live via MCP at Gate 3 Step 2 — review here is syntax/architecture only."
fi

cat <<EOF
MODE: code-review

## Original request

$REQUEST

## Proposed solution — full file contents

Path: \`$FILE\`

\`\`\`yaml
$(cat "$FILE")
\`\`\`

## Reference docs

- INSTRUCTIONS.md path: \`$INSTRUCTIONS\` — read it directly.
- DECISIONS.md path: \`$DECISIONS\` — read it directly.
- $PROFILE_NOTE

Please return APPROVED or BLOCKED with line-level findings.
EOF
