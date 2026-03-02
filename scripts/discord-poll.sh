#!/bin/bash
# Discord Inbound Message Reader for Claude Code
# PostToolUse hook — reads local inbox file written by bridge.js
#
# This is the recommended approach: bridge.js runs as a persistent WebSocket
# listener and writes messages to a local JSONL file. This hook simply reads
# that file — no network calls, no throttling needed, instant delivery.
#
# Requires: bridge.js running (auto-started by PreToolUse hook via start-bridge.sh)

INBOX_FILE="$HOME/.claude/discord-inbox.jsonl"
ENABLED_FILE="$HOME/.claude/notifications-enabled"

# Only run if notifications are enabled (autonomous mode active)
if [ -n "$CLAUDE_ENV_FILE" ]; then
  if [ "${CLAUDE_DISCORD_NOTIFY}" != "true" ]; then
    exit 0
  fi
else
  if [ ! -f "$ENABLED_FILE" ]; then
    exit 0
  fi
fi

# Check if inbox exists and has content
if [ ! -s "$INBOX_FILE" ]; then
  exit 0
fi

# Read all queued messages
MESSAGES=$(cat "$INBOX_FILE")

# Clear the inbox atomically (truncate, don't delete — avoids race with bridge)
> "$INBOX_FILE"

# Count messages
MSG_COUNT=$(echo "$MESSAGES" | wc -l)

# Format output for Claude
echo ""
echo "================================================"
echo "DISCORD: ${MSG_COUNT} message(s) from #claude-code-chat"
echo "================================================"

echo "$MESSAGES" | while IFS= read -r line; do
  if [ -z "$line" ]; then continue; fi
  PARSED=$(echo "$line" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ts = d.get('timestamp','')[:16].replace('T',' ')
    att = f' [+{len(d[\"attachments\"])} attachment(s)]' if d.get('attachments') else ''
    print(f\"[{ts}] {d['author']}: {d['content']}{att}\")
except:
    print(sys.stdin.read().strip())
" 2>/dev/null)
  echo "$PARSED"
done

echo "================================================"
echo "Reply via mcp__discord__send-message to #claude-code-chat"
echo ""
