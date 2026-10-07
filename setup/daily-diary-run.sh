#!/usr/bin/env bash
# daily-diary-run.sh — launchd wrapper for the daily-diary skill.
# Guards: PID lockfile (no concurrent double-runs) + 2-hour cooldown based
# on the last COMPLETED run (prevents reboot loops and double-fires).
#
# A failed agent run (non-zero exit) does NOT bump the cooldown, so the
# next scheduled run retries instead of waiting out the full 2 hours.

set -u

LOG="$HOME/Library/Logs/daily-diary.log"
STATE_DIR="$HOME/.local/state/daily-diary"
LOCK="$STATE_DIR/daily-diary.pid"
LAST_COMPLETED="$STATE_DIR/last_completed_run"
COOLDOWN_SECONDS=7200   # 2 hours

mkdir -p "$STATE_DIR" "$(dirname "$LOG")"

log() { echo "=== $(date '+%F %T') $*" >> "$LOG"; }

# Resolve the claude CLI (launchd PATH is minimal)
CLAUDE="$(command -v claude || true)"
[ -z "$CLAUDE" ] && [ -x "/opt/homebrew/bin/claude" ] && CLAUDE="/opt/homebrew/bin/claude"
if [ -z "$CLAUDE" ]; then
  log "skip: claude CLI not found on PATH"
  exit 1
fi

# --- PID lockfile -----------------------------------------------------------
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
  log "skip: already running (pid $(cat "$LOCK"))"
  exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# --- Cooldown based on last completed run ------------------------------------
now=$(date +%s)
last=0
[ -f "$LAST_COMPLETED" ] && last=$(cat "$LAST_COMPLETED" 2>/dev/null || echo 0)
age=$((now - last))
if [ "$age" -lt "$COOLDOWN_SECONDS" ]; then
  log "skip: cooldown active ($age s < $COOLDOWN_SECONDS s)"
  exit 0
fi

# --- Run headless agent ------------------------------------------------------
log "run: starting headless claude"
"$CLAUDE" -p "Run the /daily-diary skill now." >> "$LOG" 2>&1
rc=$?

if [ "$rc" -ne 0 ]; then
  log "run: FAILED rc=$rc; cooldown NOT updated (next scheduled run will retry)"
  exit "$rc"
fi

date +%s > "$LAST_COMPLETED"
log "run: completed rc=0"
exit 0
