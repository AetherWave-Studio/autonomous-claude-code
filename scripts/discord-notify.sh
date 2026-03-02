#!/bin/bash
# Discord Notification Hook for Claude Code
# Sends formatted status updates to Discord when Claude stops
# Supports per-session threads -- each session gets its own named thread
#
# Installation:
#   1. Copy this file to ~/.claude/discord-notify.sh
#   2. chmod +x ~/.claude/discord-notify.sh
#   3. Update WEBHOOK_URL below with your Discord webhook
#   4. Add hook to ~/.claude/settings.json
#
# Windows WSL users: install to /home/YOUR_WSL_USER/.claude/discord-notify.sh

# ============================================
# CONFIGURATION
# ============================================

WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"

# Thread mode (recommended: true)
# true  = each session gets its own named thread
# false = all messages post to channel directly (original behavior)
USE_THREADS=true

COLOR_STOP="15105570"
COLOR_PERMISSION="16776960"
COLOR_ERROR="15548997"
COLOR_IDLE="16776960"

if [ -n "$COLOR" ]; then
  COLOR_STOP="$COLOR"
fi

# ============================================
# NOTIFICATION GATE
# ============================================
# Modern (CLAUDE_ENV_FILE): session-scoped, auto-destroyed on session end
# Legacy (toggle file): touch ~/.claude/notifications-enabled to enable

if [ -n "$CLAUDE_ENV_FILE" ]; then
  if [ "${CLAUDE_DISCORD_NOTIFY}" != "true" ]; then
    exit 0
  fi
else
  if [ ! -f ~/.claude/notifications-enabled ]; then
    exit 0
  fi
fi

# ============================================
# PARSE HOOK INPUT
# ============================================

INPUT=$(cat)
EVENT_NAME=$(echo "$INPUT" | grep -o '"hook_event_name":"[^"]*"' | cut -d'"' -f4)
LAST_MESSAGE=$(echo "$INPUT" | grep -o '"last_assistant_message":"[^"]*"' | cut -d'"' -f4 | head -c 1500)
NOTIF_MESSAGE=$(echo "$INPUT" | grep -o '"message":"[^"]*"' | cut -d'"' -f4 | head -c 500)
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | grep -o '"stop_hook_active":[^,}]*' | cut -d':' -f2)

# Use last_assistant_message if available, fall back to message field
if [ -z "$LAST_MESSAGE" ]; then
  LAST_MESSAGE="$NOTIF_MESSAGE"
fi

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

case "$EVENT_NAME" in
  "Stop")
    COLOR="$COLOR_STOP"
    TITLE="Claude Code Stopped"
    ;;
  "Notification")
    if echo "$INPUT" | grep -q "permission_prompt"; then
      COLOR="$COLOR_PERMISSION"
      TITLE="Permission Needed"
    elif echo "$INPUT" | grep -q "idle_prompt"; then
      COLOR="$COLOR_IDLE"
      TITLE="Claude Idle"
    else
      COLOR="$COLOR_PERMISSION"
      TITLE="Claude Notification"
    fi
    ;;
  "Error")
    COLOR="$COLOR_ERROR"
    TITLE="Claude Code Error"
    ;;
  *)
    COLOR="15548997"
    TITLE="Claude Code Event: $EVENT_NAME"
    ;;
esac

ESCAPED_MESSAGE=$(echo "$LAST_MESSAGE" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# ============================================
# THREAD MANAGEMENT
# ============================================
# Each session gets its own named thread.
# Thread ID stored in ~/.claude/sessions/{SESSION_ID}.thread
# First message creates the thread, subsequent messages post to it.
# Set USE_THREADS=false to revert to direct channel posting.

build_payload() {
  local title="$1"
  local msg="$2"
  local color="$3"
  local session="$4"
  local ts="$5"
  local thread_name="$6"

  if [ -n "$thread_name" ]; then
    echo "{\"thread_name\": \"${thread_name}\", \"embeds\": [{\"title\": \"${title}\", \"description\": \"${msg}\", \"color\": ${color}, \"footer\": {\"text\": \"Session: ${session} | ${ts}\"}}]}"
  else
    echo "{\"embeds\": [{\"title\": \"${title}\", \"description\": \"${msg}\", \"color\": ${color}, \"footer\": {\"text\": \"Session: ${session} | ${ts}\"}}]}"
  fi
}

if [ "$USE_THREADS" = "true" ] && [ -n "$SESSION_ID" ]; then

  SESSIONS_DIR="$HOME/.claude/sessions"
  THREAD_FILE="${SESSIONS_DIR}/${SESSION_ID}.thread"
  mkdir -p "$SESSIONS_DIR"

  if [ ! -f "$THREAD_FILE" ]; then
    # First message for this session -- create new thread
    PAYLOAD=$(build_payload "$TITLE" "$ESCAPED_MESSAGE" "$COLOR" "$SESSION_ID" "$TIMESTAMP" "Session: ${SESSION_ID}")
    RESPONSE=$(curl -s -X POST "${WEBHOOK_URL}?wait=true" -H "Content-Type: application/json" -d "$PAYLOAD")  # wait=true returns body with channel_id
    THREAD_ID=$(echo "$RESPONSE" | grep -o '"channel_id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$THREAD_ID" ]; then
      echo "$THREAD_ID" > "$THREAD_FILE"
    fi
  else
    # Thread exists -- post to it
    THREAD_ID=$(cat "$THREAD_FILE")
    PAYLOAD=$(build_payload "$TITLE" "$ESCAPED_MESSAGE" "$COLOR" "$SESSION_ID" "$TIMESTAMP" "")
    curl -s -X POST "${WEBHOOK_URL}?thread_id=${THREAD_ID}" -H "Content-Type: application/json" -d "$PAYLOAD" > /dev/null 2>&1
  fi

else
  # Thread mode off -- post directly to channel
  PAYLOAD=$(build_payload "$TITLE" "$ESCAPED_MESSAGE" "$COLOR" "$SESSION_ID" "$TIMESTAMP" "")
  curl -s -X POST "$WEBHOOK_URL" -H "Content-Type: application/json" -d "$PAYLOAD" > /dev/null 2>&1
fi

exit 0
