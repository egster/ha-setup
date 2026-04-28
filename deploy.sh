#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# deploy.sh — Ship a config/packages/*.yaml file to HA Green and reload
#
# Usage:
#   ./deploy.sh config/packages/vacation_mode.yaml
#   ./deploy.sh config/configuration.yaml
#
# What it does:
#   1. Validates YAML locally (yamllint)
#   2. SCPs the file to the right path on HA Green
#   3. Waits for supervisor jobs to settle (avoids "Another job is running"
#      false-rollback — see BACKLOG 2026-04-27, office_motion_light deploy)
#   4. Runs `ha core check`. On generic config errors, rolls back. On a
#      supervisor-lock error specifically, exits WITHOUT rollback (the file
#      may be perfectly valid; check just couldn't run).
#   5. Prints the per-domain reload services this package needs.
#      Reloads must be issued via MCP `ha_call_service` or HA Developer Tools.
#      The supervisor CLI does NOT expose individual reload services, and
#      `ha core reload-all` is a silent no-op on core-2026.4+ (BACKLOG 2026-04-26).
#
# Requirements:
#   - ssh ha is configured (~/.ssh/config, key auth working)
#   - yamllint installed (pip3 install yamllint)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

HA_HOST="ha"
HA_CONFIG_ROOT="/config"

# Job-poll guard. 30 × 3s = 90s ceiling — covers the ~70s stuck supervisor job
# observed on 2026-04-27 (office_motion_light deploy) without unbounded waiting.
JOB_POLL_MAX_TRIES=30
JOB_POLL_INTERVAL=3

# ── Argument check ────────────────────────────────────────────────────────────
if [ $# -eq 0 ]; then
  echo "Usage: ./deploy.sh <path-to-file>"
  echo "  e.g. ./deploy.sh config/packages/vacation_mode.yaml"
  exit 1
fi

LOCAL_FILE="$1"

if [ ! -f "$LOCAL_FILE" ]; then
  echo "❌ File not found: $LOCAL_FILE"
  exit 1
fi

# ── Derive remote path ────────────────────────────────────────────────────────
# Strip leading "config/" to get the path relative to /config on HA
RELATIVE="${LOCAL_FILE#config/}"
REMOTE_PATH="${HA_CONFIG_ROOT}/${RELATIVE}"
REMOTE_DIR=$(dirname "$REMOTE_PATH")

echo "📦 Deploying: $LOCAL_FILE → root@${HA_HOST}:${REMOTE_PATH}"
echo ""

# ── 1. Local YAML validation ──────────────────────────────────────────────────
echo "1/5  Validating YAML syntax locally..."
if ! yamllint -d '{extends: relaxed, rules: {line-length: {max: 120}}}' "$LOCAL_FILE"; then
  echo "❌ YAML syntax error — fix before deploying."
  exit 1
fi
echo "     ✅ Syntax OK"
echo ""

# ── 2. SCP to HA ──────────────────────────────────────────────────────────────
echo "2/5  Copying to HA Green..."
ssh "$HA_HOST" "mkdir -p $REMOTE_DIR"
scp "$LOCAL_FILE" "${HA_HOST}:${REMOTE_PATH}"
echo "     ✅ File transferred"
echo ""

# ── 3. Wait for supervisor jobs to settle ────────────────────────────────────
# Without this, `ha core check` can return "Another job is running for job group
# container_homeassistant" while a previous job is still completing — and the
# rollback below would then remove a perfectly valid file. Poll until idle.
# `grep -o '"done":false'` counts both parent and child jobs (child_jobs[].done),
# which is the conservative correct behaviour: we wait for any nested job too.
echo "3/5  Waiting for supervisor jobs to settle..."
for i in $(seq 1 "$JOB_POLL_MAX_TRIES"); do
  JOBS_JSON=$(ssh "$HA_HOST" "ha jobs info --raw-json" 2>/dev/null) || JOBS_JSON='{"data":{"jobs":[]}}'
  ACTIVE=$(printf '%s' "$JOBS_JSON" | (grep -o '"done":false' || true) | wc -l | tr -d ' ')
  if [ "$ACTIVE" = "0" ]; then
    echo "     ✅ No active jobs"
    break
  fi
  if [ "$i" = "$JOB_POLL_MAX_TRIES" ]; then
    echo "     ⚠️  Still ${ACTIVE} active job(s) after $((JOB_POLL_MAX_TRIES * JOB_POLL_INTERVAL))s — proceeding anyway."
    echo "         (Step 4 will detect a supervisor lock and skip rollback if it occurs.)"
    break
  fi
  echo "     ... ${ACTIVE} active job(s), retrying in ${JOB_POLL_INTERVAL}s (${i}/${JOB_POLL_MAX_TRIES})"
  sleep "$JOB_POLL_INTERVAL"
done
echo ""

# ── 4. HA config check ────────────────────────────────────────────────────────
echo "4/5  Running ha core check on HA..."
CHECK_OUTPUT=$(ssh "$HA_HOST" "ha core check 2>&1" || true)

# Lock-error detection comes BEFORE the generic error grep. If the supervisor
# returned "Another job is running" the check did NOT actually validate the
# config — rolling back would delete a possibly-valid file. Exit non-zero so
# the operator knows to retry, but leave the file in place.
if echo "$CHECK_OUTPUT" | grep -qi "another job is running\|job group container_homeassistant"; then
  echo "⚠️  Supervisor job lock — config validity unknown, NOT rolling back."
  echo "$CHECK_OUTPUT"
  echo ""
  echo "   File remains at ${REMOTE_PATH}. Wait ~60s and re-run:"
  echo "   ./deploy.sh ${LOCAL_FILE}"
  exit 1
fi

if echo "$CHECK_OUTPUT" | grep -qi "error\|invalid\|failed"; then
  echo "❌ HA config check failed:"
  echo "$CHECK_OUTPUT"
  echo ""
  echo "⚠️  Rolling back: removing deployed file..."
  ssh "$HA_HOST" "rm -f $REMOTE_PATH"
  echo "   File removed. Fix the config and try again."
  exit 1
fi
echo "     ✅ Config valid"
echo ""

# ── 5. Reload follow-up ──────────────────────────────────────────────────────
echo "5/5  Reload follow-up..."

if [[ "$RELATIVE" == "configuration.yaml" ]]; then
  echo "     ⚠️  configuration.yaml changed — full restart required."
  echo "     Run manually: ssh ha 'ha core restart'"
  echo ""
  echo "✅ File deployed. Restart HA to apply."
else
  # Detect top-level domains in the deployed package. Per BACKLOG 2026-04-26:
  # supervisor CLI cannot call individual reload services, so the operator
  # (Claude in Gate 3, or Edgar manually) issues these via MCP `ha_call_service`
  # or HA Developer Tools → Services.
  RELOAD_DOMAINS=$(grep -E '^(template|automation|script|scene|input_number|input_text|input_boolean|input_datetime|input_select):' "$LOCAL_FILE" | cut -d: -f1 | sort -u || true)

  echo "     ℹ️  Reload services this package needs:"
  if [ -n "$RELOAD_DOMAINS" ]; then
    while IFS= read -r domain; do
      echo "        • ${domain}.reload"
    done <<< "$RELOAD_DOMAINS"
    if ! printf '%s\n' "$RELOAD_DOMAINS" | grep -qx "automation"; then
      echo "        • automation.reload  (always — catches package-level alias changes)"
    fi
  else
    echo "        • automation.reload  (default — no recognised top-level domains in package)"
  fi
  echo ""
  echo "✅ File deployed and validated. Call the reload services above to make changes live."
  echo "   (MCP: ha_call_service domain=<d> service=reload — one call per line.)"
fi
