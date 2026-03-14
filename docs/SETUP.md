# Setup Guide

Complete installation walkthrough for the Autonomous Claude Code system.

---

## Prerequisites

- **Claude Code** installed ([docs.claude.com](https://docs.claude.com))
- **Discord account** with a server you control
- **Node.js** v18+
- **Git** (to clone this repo)
- **curl** (included on Mac/Linux; available in WSL on Windows)

---

## Platform Notes

| Platform | Hook Script | Notes |
|----------|------------|-------|
| macOS | `discord-notify.sh` | Native bash, works directly |
| Linux | `discord-notify.sh` | Native bash, works directly |
| Windows (WSL) | `discord-notify.sh` | Hooks run via WSL bash — **use WSL path** |
| Windows (native) | `discord-notify.ps1` | PowerShell version, requires PS execution policy |

> ⚠️ **Windows users:** Claude Code hooks execute via your WSL environment. Install the `.sh` script to your **WSL home path** (`/home/YOUR_WSL_USER/.claude/`), not your Windows home path.

---

## Step 1: Clone the Repo

```bash
git clone https://github.com/AetherWave-Studio/autonomous-claude-code.git
cd autonomous-claude-code
```

---

## Step 2: Configure Permissions

Claude Code prompts for approval on potentially destructive commands. For autonomous sessions you want minimal interruptions — configure `settings.local.json` to allow routine operations broadly.

### Where settings.local.json lives

Claude Code checks for `settings.local.json` at **each level independently**:

| Location | Scope |
|----------|-------|
| `~/.claude/settings.local.json` | Global — applies to all sessions |
| `<repo>/.claude/settings.local.json` | Project — overrides global for that repo |
| Other tool directories (Obsidian vault, etc.) | Tool-specific — check each one |

> ⚠️ If you have multiple `.claude/` directories, each needs its own `settings.local.json`. The global file does not cascade into project-level overrides. Check all locations.

### Install the permissions config

```bash
cp templates/settings.local.json ~/.claude/settings.local.json
```

**Windows — copy to all relevant locations:**
```powershell
Copy-Item templates\settings.local.json "$env:USERPROFILE\.claude\settings.local.json"
# Repeat for any repo-level .claude\ directories
```

This allows all routine operations (`Bash(*)`, `Read(*)`, `Write(*)`, `Edit(*)`, `WebFetch(*)`) while blocking genuinely destructive commands (recursive deletes from root, disk formatting).

> ⚠️ `settings.local.json` is excluded from version control (see `.gitignore`). Never commit it.

---

## Step 3: Create Your Discord Webhook

1. Open Discord → your server → **Server Settings**
2. Go to **Integrations → Webhooks → New Webhook**
3. Name it (e.g. "Claude Agent Monitor")
4. Select the channel where notifications should post (e.g. `#claude-logs`)
5. Click **Copy Webhook URL** — save it for the next step

The system auto-creates a named thread for each session. All status updates post inside that thread. Full session history lives in your Discord sidebar with no database required.

---

## Step 4: Set Up the Discord Bridge Bot

The bridge bot enables two-way communication — your Discord messages reach Claude mid-session in real time via a persistent WebSocket connection and local file queue.

### Discord Bot Setup

1. Discord Developer Portal → **New Application** → name it (e.g. "ClaudeCode Bridge")
2. Go to **Bot** → **Add Bot**
3. Under **Privileged Gateway Intents**, enable all three:
   - Presence Intent
   - Server Members Intent
   - **Message Content Intent** ← required, without this messages are silently dropped
4. Click **Reset Token** → copy the token
5. Under **OAuth2 → URL Generator**: select `bot` scope + `Read Messages/View Channels` permission
6. Open the generated URL → add the bot to your server
7. Right-click your `#claude-code-chat` channel → **Copy Channel ID** (requires Developer Mode)
8. Right-click your own username → **Copy User ID** the same way

### Install the Bridge

```bash
cp -r scripts/discord-bridge ~/.claude/
cd ~/.claude/discord-bridge
npm install
```

### Set Environment Variables

**macOS / Linux** — add to `~/.bashrc` or `~/.zshrc`:
```bash
export DISCORD_BOT_TOKEN="your-bot-token-here"
export DISCORD_CHANNEL_ID="your-channel-id-here"
export DISCORD_USER_ID="your-discord-user-id-here"
```

**Windows PowerShell** — add to `$PROFILE`:
```powershell
$env:DISCORD_BOT_TOKEN = "your-bot-token-here"
$env:DISCORD_CHANNEL_ID = "your-channel-id-here"
$env:DISCORD_USER_ID = "your-discord-user-id-here"
```

Reload your profile: `source ~/.bashrc` or `. $PROFILE`

> ⚠️ Never commit credentials. The `bridge.js` uses env vars — keep values in your shell profile only.

---

## Step 5: Install the Hook Script

### macOS / Linux

```bash
cp scripts/discord-notify.sh ~/.claude/
chmod +x ~/.claude/discord-notify.sh
nano ~/.claude/discord-notify.sh
# Find: WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"
# Replace with your actual webhook URL
```

### Windows (WSL) — Recommended

```bash
cp scripts/discord-notify.sh /home/YOUR_WSL_USER/.claude/
chmod +x /home/YOUR_WSL_USER/.claude/discord-notify.sh
nano /home/YOUR_WSL_USER/.claude/discord-notify.sh
```

### Windows (PowerShell — no WSL)

```powershell
Copy-Item scripts\discord-notify.ps1 "$env:USERPROFILE\.claude\"
notepad "$env:USERPROFILE\.claude\discord-notify.ps1"
# Find: $WebhookUrl = "YOUR_WEBHOOK_URL_HERE"
```

> If scripts are blocked: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## Step 6: Configure Claude Code Hooks

```bash
cp templates/settings-final.json ~/.claude/settings.json
```

**Or manually add to `~/.claude/settings.json`:**

```json
{
  "skipDangerousModePermissionPrompt": true,
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [{"type": "command", "command": "bash ~/.claude/discord-notify.sh", "timeout": 15}]
      }
    ],
    "Notification": [
      {
        "matcher": "*",
        "hooks": [{"type": "command", "command": "bash ~/.claude/discord-notify.sh", "timeout": 15}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{"type": "command", "command": "bash ~/.claude/discord-bridge/start-bridge.sh 2>/dev/null"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [{"type": "command", "command": "bash ~/.claude/discord-poll.sh"}]
      }
    ]
  }
}
```

> **Note:** The `matcher: "*"` field is required in current Claude Code versions. Hooks without it are silently ignored.

---

## Step 7: Install the Protocol

```bash
cp templates/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/commands
cp templates/discord-protocol.md ~/.claude/commands/discord-protocol.md
```

`CLAUDE.md` installs the STATUS notification protocol globally — active in every session.
`discord-protocol.md` enables the `/discord-protocol` slash command.

---

## Step 8: Test It

**Test outbound notifications:**

```bash
claude --dangerously-skip-permissions
```

Give it a task:
```
Test the Discord notification system. Create a file called hello.txt with "Hello World", then stop.
```

When Claude stops, your phone should buzz with a structured STATUS notification in a named session thread.

**Test the bridge (two-way):**

1. Start a Claude Code session — bridge auto-starts on first tool call
2. Send a message to `#claude-code-chat` from Discord
3. Check the inbox:
```powershell
cat ~/.claude/discord-inbox.jsonl
```
4. On Claude's next tool call, it reads and clears the inbox and surfaces your message

If notifications don't arrive, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Step 9: Use the `/discord-protocol` Command

`/discord-protocol` is a **mode switch** — invoke it at any point during a session. It:

1. Enables Discord webhook notifications
2. Loads STATUS protocol formatting from `CLAUDE.md`
3. Activates the backoff poll loop for remote tasking after completion

```
/discord-protocol Analyze the authentication system and write a security report
```

Or invoke mid-session with no argument:
```
/discord-protocol
```

### Listening Mode — Backoff Poll Loop

After completing a task, Claude enters listening mode. It launches background sleep tasks and checks `discord-inbox.jsonl` on a backoff schedule:

| Cycle | Delay | Cumulative |
|-------|-------|------------|
| 1 | 5 min | 5 min |
| 2 | 5 min | 10 min |
| 3 | 10 min | 20 min |
| 4 | 10 min | 30 min |
| 5 | 10 min | 40 min |
| 6 | 30 min | 1h 10m |
| 7 | 30 min | 1h 40m |
| Stop | — | ~100 min total |

Claude's final STATUS message ends with **"What would you like me to do next?"** Reply in `#claude-code-chat` and Claude acts on it within the next poll cycle. Any inbound message resets the cycle to 1. After 7 cycles with no response, Claude stops fully.

**The remote tasking loop:**
Give Claude a task → walk away → STATUS notification on phone → reply from Discord → Claude picks it up and continues. No terminal required.

### How Notification Gating Works

**Modern (CLAUDE_ENV_FILE):** Session-scoped, auto-destroyed at session end. No cleanup needed.

**Legacy (toggle file):** Falls back to `~/.claude/notifications-enabled`. The hook script detects which is available automatically.

Use `/end-protocol` to disable notifications without ending the session.

---

## Recommended Discord Setup

```
#claude-logs          ← webhook fires here (STATUS notifications, per-session threads)
#claude-code-chat     ← bridge bot listens here (your instructions to Claude)
```

---

## Security Note

This system runs Claude Code with broad local permissions on your own machine. Review `settings.local.json` before use and never commit it to version control. You are responsible for what runs on your system.

---

## Verifying Everything Works

- [ ] `~/.claude/discord-notify.sh` exists and is executable
- [ ] Webhook URL is set (not the placeholder)
- [ ] `~/.claude/settings.json` has all four hooks with `matcher: "*"`
- [ ] `~/.claude/settings.local.json` exists with broad permissions
- [ ] `~/.claude/CLAUDE.md` exists with the STATUS protocol
- [ ] `~/.claude/commands/discord-protocol.md` exists
- [ ] `~/.claude/discord-bridge/` has `bridge.js`, `start-bridge.sh`, `node_modules/`
- [ ] Env vars set: `DISCORD_BOT_TOKEN`, `DISCORD_CHANNEL_ID`, `DISCORD_USER_ID`
- [ ] Message Content Intent enabled in Discord Developer Portal
- [ ] Test notification arrives in Discord
- [ ] Test message to `#claude-code-chat` appears in `discord-inbox.jsonl`

All checked? You're autonomous. 🚀
