# Technical Summary

## Discord Bridge: Two-Way Autonomous Agent Communication

---

## Problem

Claude Code is pull-based — it only acts when tools fire or the user sends CLI input. During autonomous sessions, there is no way to communicate with the agent from a phone. When the agent hits a blocker, you have to be at the terminal.

---

## Solution

A lightweight always-on Discord bridge enabling real-time two-way communication between a developer's phone and a running Claude Code session.

---

## Architecture

```
Inbound:  Discord → WebSocket → bridge.js → discord-inbox.jsonl → PostToolUse hook → Claude
Outbound: Claude → Discord MCP → #claude-code-chat → phone push notification
```

---

## Components

### Bridge Bot (`~/.claude/discord-bridge/bridge.js`)
~50 lines, discord.js v14. Persistent WebSocket connection to the Discord gateway. Listens to a dedicated channel, writes incoming messages as JSONL to a local inbox file. Zero API polling — messages land on disk in microseconds.

### PostToolUse Hook (`~/.claude/discord-poll.sh`)
Reads the local inbox file on every tool call. No network calls, no throttle — just a file read. Clears the inbox after reading. Latency is bounded by tool call frequency, not polling intervals.

### PreToolUse Hook (`~/.claude/discord-bridge/start.sh`)
Auto-starts the bridge bot on the first tool call of every session. Silent no-op if the bridge is already running. No manual steps required.

### Outbound Notifications (`~/.claude/discord-notify.sh`)
Webhook-based STATUS updates on Stop, Error, and Idle events. Each session auto-creates a named thread in Discord via the `thread_name` parameter. Full session history persists in the Discord sidebar — no database required.

---

## Key Design Decisions

**Local file queue over API polling**
The first implementation polled the Discord API every 2 minutes via PostToolUse. Replacing it with a persistent WebSocket bridge writing to a local file brought latency from ~2 minutes down to microseconds. JSONL format with atomic truncation prevents race conditions between bridge writes and hook reads.

**Session-agnostic persistence**
Discord history persists across session crashes and restarts. Multiple agents can share the same channel. The bridge reconnects automatically on failure.

**Hook-native integration**
No modifications to Claude Code itself. Everything runs through the documented hook system: PreToolUse, PostToolUse, Stop, Notification. Forward-compatible with Claude Code updates.

**Per-session thread archive**
Discord's webhook `thread_name` parameter creates a new named thread on first message. Subsequent messages route to that thread via `?thread_id=`. Required `?wait=true` to receive the response body containing `channel_id` — default returns 204 empty.

---

## What It Enables

- Redirect autonomous agents mid-run from your phone
- Push notifications on stops, errors, and permission prompts
- Multi-agent coordination through shared channel history
- Full session archive without a database

---

## What It Doesn't Solve

- **Permission approval prompts** — when Claude is idle waiting for input (1/2/3?), tools are not firing, so PostToolUse does not run. Terminal or Remote Control required for these.
- **Bridge process management** — the bridge must survive as a background process. The PreToolUse hook handles auto-start per session but does not manage system-level persistence across reboots.

---

## Stack

- Node.js + discord.js v14 (bridge bot)
- Bash (hook scripts)
- Claude Code hook system (PreToolUse / PostToolUse / Stop / Notification)
- Discord Webhooks API + Discord Bot Gateway API

---

*Written by Claude Opus 4.6*
