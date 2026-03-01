# Autonomous Claude Code

**Chat with Claude while it works. Get notified when it stops.**

Three files. Twenty minutes. No babysitting.

---

## What This Is

A lightweight communication layer for Claude Code's autonomous sessions. While Claude is actively working, you can send messages from your phone via Discord — redirect it, change priorities, give it context. Claude picks them up and responds. When Claude stops, your phone buzzes with a structured STATUS update telling you exactly what happened and what's next.

Built on Claude Code's native hook system, Discord webhooks, and a simple communication protocol. No complex dependencies. No proprietary frameworks. Just bash, curl, and a Discord server you already have.

> **Honest limitation:** If Claude stops mid-task and is waiting for a decision (A, B, or C?), it's idle — no tools are firing, so your Discord reply won't reach it. That still requires the terminal. This system shines during active autonomous runs, not at idle decision prompts.

---

## What About the Claude Desktop App?

The Claude desktop app has bypass permissions mode and a remote control feature for watching sessions from another device. It does not have:

- **Push notifications** — nothing buzzes your phone when Claude stops, errors, or needs input
- **Two-way chat via Discord** — no way to send instructions mid-run from a channel your phone already has open
- **Per-session thread archive** — no persistent log of every autonomous session in one place

If you can install the desktop app, this system complements it. If you can't (group policy, Linux server, WSL-only setup), this works from any terminal with no GUI dependency.

| Scenario | Desktop App | This System |
|----------|------------|-------------|
| Autonomous coding | ✅ UI toggle | ✅ CLI flag |
| Watch session from phone | ✅ Remote Control (view only) | ✅ Discord two-way chat |
| Send instructions mid-run | ❓ Unconfirmed with bypass | ✅ Proven working |
| Push notification on stop/error | ❌ None | ✅ Discord to phone |
| Session history archive | ❌ None | ✅ Per-session Discord threads |
| Works without desktop app install | ❌ Required | ✅ Any terminal |

---

## Real Results

**Overnight while the developer slept:**

- 27,000+ lines of code analyzed across two parallel sessions
- 15 technical issues found, severity-rated, with line numbers
- 15 feature proposals with value/complexity matrix
- 6-month implementation roadmap
- Delivered at 5:42 AM with a mobile notification

This is the kind of report you'd pay a consultant thousands of dollars for. Two AI agents running autonomously, coordinated from a phone, zero laptop time required.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTONOMOUS WORKFLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Start Claude Code with a task                           │
│  2. Claude works autonomously                               │
│  3. Claude stops at decision points                         │
│  4. Hook fires → Discord notification sent                  │
│  5. Phone buzzes with STATUS update 📱                      │
│  6. You reply from anywhere                                 │
│  7. Claude sees your reply, continues                       │
│  8. Repeat until done                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

Every notification follows the STATUS protocol:

```
STATUS: COMPLETED

- What was done: Authentication middleware implemented with JWT tokens
- Current state: Middleware working, 8 tests passing
- Next step: Ready for code review
- Session: auth-middleware-001
- Modified: auth.ts, middleware.ts, auth.test.ts
- Test: npm test
```

From your phone, you know exactly what happened, what's working, and what to do next.

---

## Quick Start

**Prerequisites:** Claude Code, Discord account, 20 minutes

```bash
# 1. Clone
git clone https://github.com/AetherWave-Studio/autonomous-claude-code.git
cd autonomous-claude-code

# 2. Create a text channel in Discord and add a webhook
# Discord → Server Settings → Integrations → Webhooks → New Webhook
# Attach it to your channel, copy the URL

# 3. Install the notification hook
cp scripts/discord-notify.sh ~/.claude/
chmod +x ~/.claude/discord-notify.sh
nano ~/.claude/discord-notify.sh
# Set WEBHOOK_URL to your webhook URL

# 4. Install the hooks config
cp templates/settings.json ~/.claude/settings.json

# 5. Install the STATUS protocol
cp templates/CLAUDE.md ~/.claude/

# 6. Install the slash command
mkdir -p ~/.claude/commands
cp templates/discord-protocol.md ~/.claude/commands/

# 7. Test it
claude
# Give it a task, then type /discord-protocol
# Walk away — Discord notification fires when Claude stops
```

**Windows/WSL users:** See [docs/SETUP.md](docs/SETUP.md) for platform-specific steps.

> ⚠️ Never commit your Discord webhook URL to version control. Templates contain `YOUR_WEBHOOK_URL_HERE` placeholders. Your live copy stays in `~/.claude/` only.

---

## Two-Way Communication

The notification system is one-way by default. For full two-way chat from your phone, add the Discord Bridge Bot — a small always-on Node.js process that listens to your Discord channel via WebSocket and surfaces your messages to Claude in real time.

```
Your phone → #claude-code-chat → Bridge Bot (WebSocket)
                                        ↓ writes instantly
                                ~/.claude/discord-inbox.jsonl
                                        ↑ reads on tool calls
                               discord-poll.sh (PostToolUse hook)
                                        ↓
                               Claude sees your message
```

**The result:** You post "switch to the auth bug" from your phone. Within seconds it lands in a local file. On Claude's next tool call, it reads the message, responds in Discord, and changes course.

See [docs/SETUP.md](docs/SETUP.md) for bridge bot installation.

---

## Architecture

### Files

```
~/.claude/
├── discord-notify.sh          # Outbound — fires on Stop/Error/Notification
├── discord-poll.sh            # Inbound — reads local inbox on every tool call
├── discord-bridge/
│   ├── bridge.js              # Always-on WebSocket listener
│   ├── start.sh               # Auto-starts on first tool call
│   └── stop.sh                # Clean shutdown
├── settings.json              # Hook wiring (Stop, Notification, PostToolUse, PreToolUse)
├── CLAUDE.md                  # STATUS protocol
└── commands/
    └── discord-protocol.md    # /discord-protocol slash command
```

### Communication Channels

| Direction | Channel | When |
|-----------|---------|------|
| Outbound | Webhook → `#claude-logs` thread | Every Stop/Error event |
| Inbound | `#claude-code-chat` → Bridge → local file → hook | Any tool call after message arrives |

### Per-Session Thread Archive

Each autonomous session automatically creates a named thread in `#claude-logs`:

```
#claude-logs
├── 📎 Session: auth-middleware-001
├── 📎 Session: video-editor-recon-002
└── 📎 Session: daw-bottlenecks-001
```

Every status update for a session posts inside its thread. Your full session history lives in Discord, readable top to bottom, no database required.

---

## The /discord-protocol Command

`/discord-protocol` is a **mode switch**, not a session initializer. Invoke it any time during a Claude Code session — at the start, before stepping away, or mid-task.

```
/discord-protocol
/discord-protocol "Analyze the authentication system and find security issues"
```

What it enables:
- Webhook notifications to your phone on every stop
- Inbound message polling from Discord
- STATUS block formatting on every stop

```
/end-protocol
```

Disables notifications. Claude keeps working silently in the same session.

---

## Multi-Agent Coordination

Run parallel sessions on different features, coordinate both from your phone:

```
11:23 PM  🟧 Session auth-001: "JWT approach: A) Stateless, B) Redis-backed?"
11:24 PM  You: "Stateless, we're serverless"
11:47 PM  🟦 Session daw-001: "12 DSP bottlenecks found, prioritize?"
11:48 PM  You: "Top 3 by performance impact"
12:15 AM  🟧 Session auth-001: "JWT implemented, 8 tests passing"
1:34 AM   🟦 Session daw-001: "Top 3 resolved, 40% faster processing"
```

Two autonomous sessions. One phone. Zero laptop time.

---

## What This Doesn't Do

**Idle sessions:** The inbound polling only fires when Claude is actively using tools. If Claude is idle waiting for terminal input, it cannot receive Discord messages until it does something. During active autonomous work this is not a limitation — tools fire constantly. When Claude is idle, you're at the terminal already.

**Novel decisions:** Claude handles implementation. You handle architecture, business logic, and anything genuinely new.

---

## Documentation

- **[Technical Summary](docs/TECHNICAL.md)** — Architecture, design decisions, stack
- **[Setup Guide](docs/SETUP.md)** — Full installation including bridge bot
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** — Common issues, Windows/WSL fixes
- **[Advanced Patterns](docs/ADVANCED.md)** — Multi-agent, supervisor layer, MCP integrations
- **[Examples](examples/)** — Real production output

---

## Roadmap

### v1.0 (Current)
- ✅ Discord webhook notifications with per-session threads
- ✅ STATUS protocol
- ✅ Two-way Discord chat via bridge bot
- ✅ Multi-agent coordination
- ✅ Production-tested

### v1.1 (Next)
- Supervisor pattern templates
- Slack integration guide
- Protocol templates for web dev, data science, DevOps
- Auto-start bridge on system boot

### v2.0 (Future)
- Web dashboard
- Session analytics
- Team collaboration features

---

## Contributing

1. Share autonomous success stories — open a Discussion
2. Add protocol templates for different project types
3. Create Slack/Teams webhook variants
4. Improve error handling in hook scripts
5. Port the supervisor pattern into a reusable template

---

## License

MIT — see [LICENSE](LICENSE)

---

## FAQ

**Q: Is this safe?**
Review all code before shipping. Use version control. Start with non-critical work.

**Q: Works with other LLMs?**
Hook system is Claude Code specific. The pattern — webhooks plus protocol — works with any LLM that supports hooks.

**Q: Cost?**
Free. Discord webhooks are free. Claude Code is included in Pro/Max plans.

**Q: Slack instead of Discord?**
Yes. Slack has incoming webhooks — change the URL and adjust the JSON payload.

**Q: Why not just use the Claude desktop app?**
The desktop app requires installation and Anthropic's hosted environment for remote access. This runs in any terminal, on any machine, with no GUI dependency. Group policy blocking your install? WSL and three bash scripts still work.

---

*Three files. Twenty minutes. Claude texts you when it's done.*

**⭐ Star this repo if autonomous coding changed your workflow**
