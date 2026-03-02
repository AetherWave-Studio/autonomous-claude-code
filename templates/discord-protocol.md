# Discord Protocol - Autonomous Mode

Enable autonomous coding mode with Discord notifications and two-way chat.

This is a **mode switch**, not a session initializer. Invoke it any time during
a session — at the start, before stepping away, or mid-task. Disable with
`/end-protocol` when you return.

## Usage

```
/discord-protocol
/discord-protocol "Your task description here"
```

---

## What This Activates

**Step 1 — Enable webhook notifications for this session:**

Check which mechanism your Claude Code version supports:

```bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  # Modern: session-scoped, auto-cleans when session ends
  echo 'export CLAUDE_DISCORD_NOTIFY=true' >> "$CLAUDE_ENV_FILE"
else
  # Legacy: toggle file fallback
  touch ~/.claude/notifications-enabled
fi
```

**Step 2 — Confirm dependencies. If any are missing, STATUS: BLOCKED immediately:**
- `~/.claude/CLAUDE.md` exists (STATUS protocol)
- `~/.claude/discord-notify.sh` is executable and `WEBHOOK_URL` is set
- `~/.claude/discord-poll.sh` is executable (inbound message polling)

See [docs/SETUP.md](../docs/SETUP.md) if any of these are missing.

**Step 3 — Begin autonomous work following `~/.claude/CLAUDE.md`:**
- Work autonomously on implementation details
- Stop only for strategic decisions, breaking changes, or blockers
- Write structured STATUS blocks at every stop point

**Step 4 — Inbound messages from the developer:**
The `discord-poll.sh` hook runs automatically after every tool call and checks
`#claude-code-chat` for new messages. You do not need to manually check Discord.
When a message arrives, it surfaces automatically as hook output — you will see
it and should respond via MCP `send-message` before continuing work.

> Note: Polling only fires when tools are executing. If you are idle and waiting
> for terminal input, you cannot receive Discord messages until a tool fires.
> During active autonomous work this is not a limitation — tools fire constantly.

**Step 5 — Before every stop:**
Write your final message as a STATUS block. This becomes the webhook notification
sent to the developer's phone. Format per `CLAUDE.md`:

```
STATUS: [COMPLETED | BLOCKED | NEEDS INPUT | ERROR]

- What was done:
- Current state:
- Next step:
- Session:
- Modified:
- Test:
```

---

## How Two-Way Communication Works

| Mode | Inbound | Outbound |
|------|---------|----------|
| Autonomous (tools firing) | `discord-poll.sh` detects your message within 2 min | Webhook posts STATUS to `#claude-logs` thread |
| Idle (waiting for input) | Not available — use terminal directly | N/A |

This is not a limitation — it is correct architecture. Discord two-way solves the
hard problem: redirecting Claude mid-autonomous-run without touching the terminal.
When Claude is idle, you are already at the terminal.

---

## Requirements

- Discord webhook URL set in `~/.claude/discord-notify.sh`
- Discord poll script at `~/.claude/discord-poll.sh`
- `PostToolUse` hook wired in `~/.claude/settings.json`
- `~/.claude/CLAUDE.md` installed from `templates/CLAUDE.md`

See [docs/SETUP.md](../docs/SETUP.md) for full installation instructions.

---

## Session Naming

Use `{feature}-{component}-{number}` in every STATUS block:
```
auth-middleware-001
video-editor-recon-002
api-refactor-001
```

---

## Aliases
- `/autonomous`
- `/discord`
- `/remote`

---

## To Disable

```
/end-protocol
```

Stops notifications. Claude continues working silently in the same session.
