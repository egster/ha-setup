#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# run-fusion-tests.sh — Execute the FUSION Phase 7 test suite
#
# Reads `00 - Agent Context/fusion-phase7/fusion-tests.md`, dispatches each test
# to the right backend (SSH for ha-core-check, file-grep for entity-list, JSON
# spec emission for browser-side tests), and prints a pass/fail report.
#
# Two halves:
#   1) SSH + local-shell tests run in-process (yaml_schema, entity_existence
#      via grep+state file, template_eval via /api/template).
#   2) Browser tests (dom_assertion, visual_regression, behavioural) emit a JSON
#      spec to stdout (or --browser-spec=PATH). A Claude Code session with
#      Chrome MCP runs them and writes results back via --results=PATH; this
#      script then re-runs in --report mode to produce the final summary.
#
# Usage:
#   ./scripts/run-fusion-tests.sh                 # run SSH tests + emit browser spec
#   ./scripts/run-fusion-tests.sh --list          # list all tests, no execution
#   ./scripts/run-fusion-tests.sh --category=yaml_schema   # one category only
#   ./scripts/run-fusion-tests.sh --allow-baseline-failures  # known failures count as PASS
#   ./scripts/run-fusion-tests.sh --browser-spec=/tmp/b.json  # write browser spec to file
#   ./scripts/run-fusion-tests.sh --results=/tmp/r.json --report   # consolidate
#
# Exit codes:
#   0 — every test PASSED (or PASSED + known-failures with --allow-baseline-failures)
#   1 — at least one test FAILED unexpectedly
#   2 — runner-internal error (parse failure, missing dependency)
#
# Requirements:
#   - ssh ha (configured, key auth) for yaml_schema + template_eval
#   - jq for JSON handling
#   - yamllint for TEST-042 (optional — test skipped if missing)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Locate repo root + tests file ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_FILE="$REPO_ROOT/00 - Agent Context/fusion-phase7/fusion-tests.md"
DASH_FILE="$REPO_ROOT/config/dashboards/fusion.yaml"

if [ ! -f "$TESTS_FILE" ]; then
  echo "❌ Tests file not found: $TESTS_FILE" >&2
  exit 2
fi

# ── Defaults ──────────────────────────────────────────────────────────────────
FUSION_URL="${FUSION_URL:-http://homeassistant.local:8123/dashboard-fusion/fusion}"
HA_HOST="${HA_HOST:-ha}"
ALLOW_BASELINE_FAILURES=0
LIST_ONLY=0
CATEGORY=""
BROWSER_SPEC_PATH=""
RESULTS_PATH=""
REPORT_MODE=0

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --allow-baseline-failures) ALLOW_BASELINE_FAILURES=1 ;;
    --list) LIST_ONLY=1 ;;
    --category=*) CATEGORY="${arg#--category=}" ;;
    --browser-spec=*) BROWSER_SPEC_PATH="${arg#--browser-spec=}" ;;
    --results=*) RESULTS_PATH="${arg#--results=}" ;;
    --report) REPORT_MODE=1 ;;
    -h|--help)
      sed -n '2,/^# ──/p' "$0" | sed 's/^# \{0,1\}//' | head -n -1
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ── Dependency checks ─────────────────────────────────────────────────────────
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required tool not on PATH: $1" >&2; exit 2; }; }
need awk
need grep
need ssh

HAVE_JQ=0; command -v jq >/dev/null 2>&1 && HAVE_JQ=1
HAVE_YAMLLINT=0; command -v yamllint >/dev/null 2>&1 && HAVE_YAMLLINT=1

# ── Parse fusion-tests.md into newline-delimited "test records" ───────────────
# Each record is a single line:  TEST-NNN|<title>|<key=b64>|<key=b64>|...
# `assertion` and other multi-line values are base64-encoded so they survive
# the pipe delimiter and embedded newlines. Line-based state machine — works on
# BSD awk (macOS) where multi-char RS is unsupported.
parse_tests() {
  awk '
    function flush_field() {
      if (cur_key != "") {
        out_keys[++n_out] = cur_key
        out_vals[n_out] = cur_val
      }
      cur_key = ""; cur_val = ""
    }
    function flush_test() {
      flush_field()
      if (cur_id == "") return
      printf "%s|%s", cur_id, cur_title
      for (k = 1; k <= n_out; k++) {
        v = out_vals[k]
        cmd = "printf %s " shquote(v) " | base64 | tr -d \"\\n\""
        cmd | getline b64
        close(cmd)
        printf "|%s=%s", out_keys[k], b64
      }
      printf "\n"
      cur_id = ""; cur_title = ""; n_out = 0
      delete out_keys; delete out_vals
    }
    function shquote(s,    out) {
      gsub(/'\''/, "'\''\"'\''\"'\''", s)
      return "'\''" s "'\''"
    }
    BEGIN { in_tests = 0; cur_id = ""; n_out = 0; in_cont = 0 }
    # Mark when we cross from the header into the test list.
    /^### .*\(TEST-/ { in_tests = 1; next }
    # Test heading at column 0 (also closes any active continuation)
    /^## TEST-[0-9]+:/ {
      if (in_tests == 0) next            # skip references in the header docs
      flush_test()
      hdr = $0; sub(/^## /, "", hdr)
      col = index(hdr, ": ")
      cur_id = substr(hdr, 1, col - 1)
      cur_title = substr(hdr, col + 2)
      n_out = 0
      in_cont = 0
      delete out_keys; delete out_vals
      next
    }
    # Field with explicit pipe-folded scalar (- key: |)
    cur_id != "" && /^- [a-z_]+: \|$/ {
      flush_field()
      ln = $0
      col = index(ln, ": ")
      cur_key = substr(ln, 3, col - 3)
      cur_val = ""
      in_cont = 1
      next
    }
    # Field with single-line value (- key: value)
    cur_id != "" && /^- [a-z_]+: / {
      flush_field()
      ln = $0
      col = index(ln, ": ")
      cur_key = substr(ln, 3, col - 3)
      cur_val = substr(ln, col + 2)
      in_cont = 0
      next
    }
    # Field with empty value (- key:)
    cur_id != "" && /^- [a-z_]+:$/ {
      flush_field()
      ln = $0
      cur_key = substr(ln, 3, length(ln) - 3)
      cur_val = ""
      in_cont = 0
      next
    }
    # Continuation line — only honoured immediately after a key: pipe opener
    # (in_cont == 1) and an active key. Tightened from the old any-4-space
    # rule so prose notes blocks with embedded indented code or lists cannot
    # accrete into the next tests fields.
    cur_id != "" && cur_key != "" && in_cont == 1 && /^    / {
      cont = substr($0, 5)
      if (cur_val != "") cur_val = cur_val "\n" cont
      else cur_val = cont
      next
    }
    # Blank line — end the current field; cancels continuation.
    cur_id != "" && /^[[:space:]]*$/ {
      flush_field()
      in_cont = 0
      next
    }
    # Section divider or new ### heading ends the current test
    cur_id != "" && (/^---$/ || /^### / || /^## /) {
      flush_test()
      in_cont = 0
      next
    }
    END { flush_test() }
  ' "$TESTS_FILE"
}

# Decode a base64 field-value back to text
b64d() { printf "%s" "$1" | base64 -d; }

# Lookup a field value from a parsed test record
field() {
  local rec="$1" key="$2"
  local kv val
  IFS='|' read -ra parts <<< "$rec"
  for kv in "${parts[@]:2}"; do
    if [[ "$kv" == "$key="* ]]; then
      val="${kv#$key=}"
      b64d "$val"
      return 0
    fi
  done
  return 1
}

# ── Run a single SSH/local-shell test, return PASS/FAIL/SKIP via stdout ──────
run_yaml_schema() {
  local id="$1" title="$2" assertion="$3" expected="$4" tolerance="$5"
  local out
  case "$id" in
    TEST-041|TEST-100)
      out="$(ssh -n "$HA_HOST" 'ha core check 2>&1' 2>&1 || true)"
      if echo "$out" | grep -qiE "completed successfully|configuration will not prevent home assistant from starting"; then
        echo "PASS"
      else
        echo "FAIL"
        echo "    output (truncated):" >&2
        echo "$out" | tail -5 | sed 's/^/      /' >&2
      fi
      ;;
    TEST-042)
      if [ "$HAVE_YAMLLINT" -eq 0 ]; then
        echo "SKIP yamllint not installed"
        return
      fi
      local count
      count="$(yamllint -d '{rules: {line-length: disable}}' "$DASH_FILE" 2>&1 | wc -l | tr -d ' ')"
      if [ "$count" = "0" ]; then echo "PASS"; else echo "FAIL ($count lint issues)"; fi
      ;;
    TEST-105)
      # Every WP2 include file must exist and be non-empty.
      local paths=(
        "$REPO_ROOT/config/dashboards/fusion/templates.yaml"
        "$REPO_ROOT/config/dashboards/fusion/statusbar.yaml"
        "$REPO_ROOT/config/dashboards/fusion/shell.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/home.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/kitchen.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/climate.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/media.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/network.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/energy.yaml"
        "$REPO_ROOT/config/dashboards/fusion/panels/automations.yaml"
        "$REPO_ROOT/config/dashboards/fusion/popups/.gitkeep"
      )
      local missing=0
      for p in "${paths[@]}"; do [ -s "$p" ] || missing=$((missing+1)); done
      if [ "$missing" -eq 0 ]; then echo "PASS"; else echo "FAIL ($missing of ${#paths[@]} files missing or empty)"; fi
      ;;
    TEST-106)
      local lines
      lines="$(wc -l < "$DASH_FILE" 2>/dev/null | tr -d ' ')"
      if [ -n "$lines" ] && [ "$lines" -lt 100 ]; then
        echo "PASS"
      else
        echo "FAIL ($lines lines, threshold is <100)"
      fi
      ;;
    TEST-107)
      if ! command -v python3 >/dev/null 2>&1; then
        echo "SKIP python3 not installed"
        return
      fi
      local fails=0 total=0
      for f in "$REPO_ROOT"/config/dashboards/fusion/templates.yaml \
               "$REPO_ROOT"/config/dashboards/fusion/statusbar.yaml \
               "$REPO_ROOT"/config/dashboards/fusion/shell.yaml \
               "$REPO_ROOT"/config/dashboards/fusion/panels/*.yaml; do
        [ -f "$f" ] || continue
        total=$((total+1))
        # Loader tolerates HA's custom YAML directives (!include, etc.) — we
        # only care about syntactic validity here, not include resolution.
        python3 -c "
import yaml, sys
class L(yaml.SafeLoader): pass
for t in ['!include','!include_dir_list','!include_dir_named','!include_dir_merge_list','!include_dir_merge_named','!secret']:
    L.add_constructor(t, lambda loader, node: None)
yaml.load(open(sys.argv[1]), L)
" "$f" 2>/dev/null || fails=$((fails+1))
      done
      if [ "$total" -eq 0 ]; then echo "FAIL (no include files found)"
      elif [ "$fails" -eq 0 ]; then echo "PASS ($total files parsed)"
      else echo "FAIL ($fails of $total files failed to parse)"
      fi
      ;;
    TEST-400)
      # WP5a — _template.yaml is valid YAML and exports a popup_template
      # mapping. Same loader as TEST-107 (tolerant of !include).
      if ! command -v python3 >/dev/null 2>&1; then
        echo "SKIP python3 not installed"
        return
      fi
      local f="$REPO_ROOT/config/dashboards/fusion/popups/_template.yaml"
      if [ ! -f "$f" ]; then echo "FAIL ($f does not exist)"; return; fi
      local result
      result="$(python3 -c "
import yaml, sys
class L(yaml.SafeLoader): pass
for t in ['!include','!include_dir_list','!include_dir_named','!include_dir_merge_list','!include_dir_merge_named','!secret']:
    L.add_constructor(t, lambda loader, node: None)
d = yaml.load(open(sys.argv[1]), L)
print('ok' if isinstance(d, dict) and 'popup_template' in d else 'fail')
" "$f" 2>&1)" || result="parse_error"
      if [ "$result" = "ok" ]; then echo "PASS"
      else echo "FAIL ($result)"; fi
      ;;
    TEST-401)
      # WP5a — living-room.yaml is valid YAML.
      if ! command -v python3 >/dev/null 2>&1; then
        echo "SKIP python3 not installed"
        return
      fi
      local f="$REPO_ROOT/config/dashboards/fusion/popups/living-room.yaml"
      if [ ! -f "$f" ]; then echo "FAIL ($f does not exist)"; return; fi
      python3 -c "
import yaml, sys
class L(yaml.SafeLoader): pass
for t in ['!include','!include_dir_list','!include_dir_named','!include_dir_merge_list','!include_dir_merge_named','!secret']:
    L.add_constructor(t, lambda loader, node: None)
yaml.load(open(sys.argv[1]), L)
" "$f" 2>/dev/null && echo "PASS" || echo "FAIL (parse error)"
      ;;
    *)
      echo "FAIL (unknown yaml_schema test id: $id)"
      ;;
  esac
}

run_entity_existence() {
  local id="$1"
  case "$id" in
    TEST-051|TEST-052|TEST-053)
      # All three entity-existence tests run via the browser leg. The browser
      # has the authenticated `hass` object — looking entity state up via
      # HASS().states is one-line and authoritative. The runner has no need
      # to duplicate the entity list locally.
      echo "BROWSER_DEFER"
      ;;
    *)
      echo "FAIL (unknown entity_existence test id: $id)"
      ;;
  esac
}

run_template_eval() {
  # Template evaluation always runs in the browser. The dashboard page has the
  # logged-in `hass` object; HASS().callApi('POST','template',{template:...})
  # gives correct, authenticated results in one call.
  #
  # An SSH-side path was prototyped (curl POST to /api/template via the
  # supervisor token in /data/options.json) but rejected: that file is
  # add-on options, not an API token, so the path can't authenticate on a
  # stock HA Green. Reintroduce only with a documented HA_TOKEN env var.
  echo "BROWSER_DEFER"
}

# ── Browser test JSON spec emitter ───────────────────────────────────────────
emit_browser_spec() {
  local id="$1" title="$2" type="$3" viewport="$4" assertion="$5" expected="$6" tolerance="$7" status="$8"
  if [ "$HAVE_JQ" -eq 1 ]; then
    jq -nc \
      --arg id "$id" --arg title "$title" --arg type "$type" \
      --arg viewport "$viewport" --arg assertion "$assertion" \
      --arg expected "$expected" --arg tolerance "$tolerance" \
      --arg status "$status" --arg url "$FUSION_URL" \
      '{id:$id,title:$title,type:$type,viewport:$viewport,url:$url,assertion:$assertion,expected:$expected,tolerance:$tolerance,status:$status}'
  else
    # Lossy fallback when jq is missing — quote-escape minimally.
    printf '{"id":"%s","type":"%s","viewport":"%s","status":"%s"}\n' "$id" "$type" "$viewport" "$status"
  fi
}

# ── Result classification ────────────────────────────────────────────────────
classify() {
  local id="$1" outcome="$2" status="$3"
  # outcome is "PASS", "FAIL ...", or "SKIP ..."
  case "$outcome" in
    PASS*) echo "pass" ;;
    SKIP*) echo "skip" ;;
    FAIL*)
      if [ "$status" = "baseline_known_failure" ]; then echo "known_failure"
      else echo "fail"; fi
      ;;
    BROWSER_DEFER*) echo "deferred" ;;
    *) echo "unknown" ;;
  esac
}

# ── Pretty status icon for a result ──────────────────────────────────────────
icon() {
  case "$1" in
    pass) printf "✅" ;;
    fail) printf "❌" ;;
    known_failure) printf "🟡" ;;
    skip) printf "⏭️ " ;;
    deferred) printf "🌐" ;;
    *) printf "❓" ;;
  esac
}

# ── Main ─────────────────────────────────────────────────────────────────────
PARSED="$(parse_tests)"
if [ -z "$PARSED" ]; then
  echo "❌ Parse produced 0 tests. Check $TESTS_FILE format." >&2
  exit 2
fi

if [ "$LIST_ONLY" -eq 1 ]; then
  echo "FUSION test suite — $(echo "$PARSED" | wc -l | tr -d ' ') tests"
  while IFS= read -r rec; do
    [ -z "$rec" ] && continue
    id="${rec%%|*}"
    rest="${rec#*|}"; title="${rest%%|*}"
    type="$(field "$rec" type 2>/dev/null || echo unknown)"
    status="$(field "$rec" status 2>/dev/null || echo unknown)"
    printf "  %-9s %-18s %-25s %s\n" "$id" "$type" "$status" "$title"
  done <<< "$PARSED"
  exit 0
fi

if [ "$REPORT_MODE" -eq 1 ]; then
  if [ -z "$RESULTS_PATH" ] || [ ! -f "$RESULTS_PATH" ]; then
    echo "❌ --report requires --results=PATH pointing to an existing JSON file." >&2
    exit 2
  fi
  if [ "$HAVE_JQ" -eq 0 ]; then
    echo "❌ --report requires jq" >&2
    exit 2
  fi
  echo "FUSION test suite — consolidated report"
  echo "Results file: $RESULTS_PATH"
  # Render rows + tally counts.
  TALLY="$(jq -r '.[] | "\(.outcome // "unknown")\t\(.id)\t\(.title // "")"' "$RESULTS_PATH" | \
    awk -F'\t' '
      { total++; counts[$1]++; rows[NR] = $0 }
      END {
        for (i=1;i<=NR;i++) {
          split(rows[i], f, "\t")
          icon = f[1]=="pass"?"✅":f[1]=="fail"?"❌":f[1]=="known_failure"?"🟡":f[1]=="skip"?"⏭️":"❓"
          printf "  %s %s — %s\n", icon, f[2], f[3]
        }
        printf "TALLY|%d|%d|%d|%d|%d\n",
          counts["pass"]+0, counts["fail"]+0, counts["known_failure"]+0, counts["skip"]+0, total
      }')"
  # Print rows; extract tally for exit-code logic.
  echo "$TALLY" | grep -v "^TALLY|"
  TALLY_LINE="$(echo "$TALLY" | grep "^TALLY|")"
  IFS='|' read -r _ R_PASS R_FAIL R_KNOWN R_SKIP R_TOTAL <<< "$TALLY_LINE"
  printf "\nResult: %d passed, %d failed, %d known-failures, %d skipped, %d total\n" \
    "$R_PASS" "$R_FAIL" "$R_KNOWN" "$R_SKIP" "$R_TOTAL"
  if [ "${R_FAIL:-0}" -gt 0 ]; then exit 1; fi
  if [ "${R_KNOWN:-0}" -gt 0 ] && [ "$ALLOW_BASELINE_FAILURES" -eq 0 ]; then
    echo ""
    echo "⚠️  ${R_KNOWN} tests are baseline_known_failure. Pass --allow-baseline-failures to treat them as success."
    exit 1
  fi
  exit 0
fi

# ── Default mode: run SSH+local tests in-process, emit browser specs ─────────
[ -n "$BROWSER_SPEC_PATH" ] && : > "$BROWSER_SPEC_PATH"  # truncate

PASS=0; FAIL=0; KNOWN=0; SKIP=0; DEFER=0
echo "FUSION test suite — $(date +%Y-%m-%d\ %H:%M:%S)"
echo "Tests file: $TESTS_FILE"
echo "Dashboard URL: $FUSION_URL"
echo ""

while IFS= read -r rec; do
  [ -z "$rec" ] && continue
  id="${rec%%|*}"
  rest="${rec#*|}"; title="${rest%%|*}"
  type="$(field "$rec" type)"
  viewport="$(field "$rec" viewport 2>/dev/null || echo any)"
  assertion="$(field "$rec" assertion 2>/dev/null || echo "")"
  expected="$(field "$rec" expected 2>/dev/null || echo "")"
  tolerance="$(field "$rec" tolerance 2>/dev/null || echo 0)"
  status="$(field "$rec" status 2>/dev/null || echo baseline)"

  # Category filter
  if [ -n "$CATEGORY" ] && [ "$type" != "$CATEGORY" ]; then continue; fi

  outcome=""
  case "$type" in
    yaml_schema)
      outcome="$(run_yaml_schema "$id" "$title" "$assertion" "$expected" "$tolerance")"
      ;;
    entity_existence)
      outcome="$(run_entity_existence "$id" "$title" "$assertion" "$expected" "$tolerance")"
      ;;
    template_eval)
      outcome="$(run_template_eval "$id" "$title" "$assertion" "$expected" "$tolerance")"
      ;;
    dom_assertion|visual_regression|behavioural)
      outcome="BROWSER_DEFER"
      ;;
    *)
      outcome="FAIL (unknown type: $type)"
      ;;
  esac

  cls="$(classify "$id" "$outcome" "$status")"
  printf "  %s %-9s %-18s %s\n" "$(icon "$cls")" "$id" "$type" "$title"
  case "$cls" in
    pass) PASS=$((PASS+1)) ;;
    fail) FAIL=$((FAIL+1)) ;;
    known_failure) KNOWN=$((KNOWN+1)) ;;
    skip) SKIP=$((SKIP+1)) ;;
    deferred)
      DEFER=$((DEFER+1))
      if [ -n "$BROWSER_SPEC_PATH" ]; then
        emit_browser_spec "$id" "$title" "$type" "$viewport" "$assertion" "$expected" "$tolerance" "$status" >> "$BROWSER_SPEC_PATH"
      fi
      ;;
  esac
done <<< "$PARSED"

TOTAL=$((PASS + FAIL + KNOWN + SKIP + DEFER))
echo ""
echo "Result: $PASS passed, $FAIL failed, $KNOWN known-failures, $SKIP skipped, $DEFER deferred-to-browser, $TOTAL total"
[ -n "$BROWSER_SPEC_PATH" ] && echo "Browser test spec written to: $BROWSER_SPEC_PATH ($DEFER tests)"
echo ""
echo "Browser-deferred tests must be executed via Chrome MCP from a Claude Code session."
echo "Then re-run: $0 --results=<results.json> --report"

# Exit code logic
if [ "$FAIL" -gt 0 ]; then exit 1; fi
if [ "$KNOWN" -gt 0 ] && [ "$ALLOW_BASELINE_FAILURES" -eq 0 ]; then
  echo ""
  echo "⚠️  $KNOWN tests are baseline_known_failure. Pass --allow-baseline-failures to treat them as success."
  exit 1
fi
exit 0
