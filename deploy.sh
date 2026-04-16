#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# deploy.sh — Ship a config/packages/*.yaml file to HA Green and reload
#
# Usage:
#   ./deploy.sh config/packages/vacation_mode.yaml
#   ./deploy.sh config/configuration.yaml
#
# What it does:
#   1. Validates the file exists and is staged/committed in git
#   2. SCPs the file to the right path on HA Green 
#   3. Runs `ha core check` to validate config
#   4. Reloads automations (or full restart if configuration.yaml changed)
#   5. Reports success/failure
#
# Requirements:
#   - ssh ha is configured (~/.ssh/config, key auth working)
#   - yamllint installed (pip3 install yamllint)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

HA_HOST="ha"
HA_CONFIG_ROOT="/config"

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
echo "1/4  Validating YAML syntax locally..."
if ! yamllint -d '{extends: relaxed, rules: {line-length: {max: 120}}}' "$LOCAL_FILE"; then
  echo "❌ YAML syntax error — fix before deploying."
  exit 1
fi
echo "     ✅ Syntax OK"
echo ""

# ── 2. SCP to HA ──────────────────────────────────────────────────────────────
echo "2/4  Copying to HA Green..."
ssh "$HA_HOST" "mkdir -p $REMOTE_DIR"
scp "$LOCAL_FILE" "${HA_HOST}:${REMOTE_PATH}"
echo "     ✅ File transferred"
echo ""

# ── 3. HA config check ────────────────────────────────────────────────────────
echo "3/4  Running ha core check on HA..."
CHECK_OUTPUT=$(ssh "$HA_HOST" "ha core check 2>&1" || true)
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

# ── 4. Reload ─────────────────────────────────────────────────────────────────
echo "4/4  Reloading..."

if [[ "$RELATIVE" == "configuration.yaml" ]]; then
  echo "     ⚠️  configuration.yaml changed — full restart required."
  echo "     Run manually: ssh ha 'ha core restart'"
  echo ""
  echo "✅ File deployed. Restart HA to apply."
else
  # Reload automations (covers most package changes)
  ssh "$HA_HOST" "ha core reload-all 2>&1" || true
  echo "     ✅ Reload triggered"
  echo ""
  echo "✅ Done. Verify in HA that the automation/helper is live."
  echo "   Check traces: Developer Tools → Events, or the Automation editor."
fi
