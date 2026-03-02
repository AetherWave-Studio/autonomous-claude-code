#!/bin/bash
# Discord Bridge Launcher for Claude Code
# Called by PreToolUse hook to ensure the bridge is running.
# Uses a heartbeat file to prevent spawning duplicate instances.
#
# The bridge writes a Unix timestamp to bridge.heartbeat every 10 seconds.
# If the heartbeat is fresh (< 30s old), the bridge is alive — exit immediately.
# If stale or missing, start a new bridge instance.

cd "$(dirname "$0")"

# Check if bridge is alive via heartbeat file (written every 10s by bridge.js)
if [ -f bridge.heartbeat ]; then
  HEARTBEAT=$(cat bridge.heartbeat 2>/dev/null)
  NOW=$(date +%s)
  AGE=$(( NOW - HEARTBEAT ))
  # If heartbeat is less than 30 seconds old, bridge is alive
  if [ "$AGE" -lt 30 ]; then
    exit 0
  fi
fi

# Bridge is not running — start it
# Truncate old log to prevent unbounded growth
tail -100 bridge.log > bridge.log.tmp 2>/dev/null && mv bridge.log.tmp bridge.log 2>/dev/null || true

node bridge.js >> bridge.log 2>&1 &
disown
