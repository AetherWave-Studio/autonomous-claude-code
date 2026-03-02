# Setup Guide

Complete installation walkthrough for the Autonomous Claude Code system.

---

## Prerequisites

- **Claude Code** installed ([docs.claude.com](https://docs.claude.com))
- **Discord account** with a server you control
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

> ⚠️ **Windows users:** Claude Code hooks execute via your WSL environment. Install the `.sh` script to your **WSL home path** (`/home/YOUR_WSL_USER/.claude/`), not your Windows home path. The `.ps1` version is provided for users running Claude Code natively under PowerShell without WSL.

---

## Step 1: Clone the Repo

```bash
git clone https://github.com/AetherWave-Studio/autonomous-claude-code.git
cd autonomous-claude-code
```

---

## Step 2: Create Your Discord Webhook

1. Open Discord → your server → **Server Settings**
2. Go to **Integrations → Webhooks → New Webhook**
3. Name it (e.g. "Claude Agent Monitor")
4. Select the channel where notifications should post
5. Click **Copy Webhook URL**
6. Save it somewhere safe — you'll use it in the next step

**Optional: Post to a Forum Thread**

If you want notifications in a specific thread (recommended for organization):
```
https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN?thread_id=YOUR_THREAD_ID
```
Get the thread ID by right-clicking the thread → **Copy Thread ID** (requires Developer Mode in Discord settings).

---

## Step 3: Set Up the Discord Bridge Bot

The bridge bot enables two-way communication — your Discord messages reach Claude mid-session in real time.

### Prerequisites

- **Node.js** v18+ installed
- A **Discord Bot** with a token ([Create one here](https://discord.com/developers/applications))

### Discord Bot Setup

1. Discord Developer Portal → **New Application** → name it (e.g. "ClaudeCode Bridge")
2. Go to **Bot** → **Add Bot**
3. Under **Privileged Gateway Intents**, enable all three:
   - Presence Intent
   - Server Members Intent
   - **Message Content Intent** ← required
4. Click **Reset Token** → copy the token
5. Under **OAuth2 → URL Generator**: select `bot` scope + `Read Messages/View Channels` permission
6. Open the generated URL → add the bot to your server
7. Right-click your `#claude-code-chat` channel → Copy Channel ID (requires Developer Mode in Discord settings)
8. Copy your own Discord User ID the same way

### Install the Bridge

```bash
# Copy bridge files to Claude config directory
cp -r scripts/discord-bridge ~/.claude/
cd ~/.claude/discord-bridge
npm install
```

### Set Environment Variables

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, or PowerShell `$PROFILE`):

```bash
export DISCORD_BOT_TOKEN="your-bot-token-here"
export DISCORD_CHANNEL_ID="your-channel-id-here"
export DISCORD_USER_ID="your-discord-user-id-here"
```

Then reload your profile:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

**Windows PowerShell:**
```powershell
$env:DISCORD_BOT_TOKEN = "your-bot-token-here"
$env:DISCORD_CHANNEL_ID = "your-channel-id-here"
$env:DISCORD_USER_ID = "your-discord-user-id-here"
```

> ⚠️ Never commit your actual token to version control. The bridge.js in this repo uses env vars — keep them in your shell profile only.

---

## Step 4: Install the Hook Script

### macOS / Linux

```bash
# Copy script to Claude config directory
cp scripts/discord-notify.sh ~/.claude/
chmod +x ~/.claude/discord-notify.sh

# Add your webhook URL
nano ~/.claude/discord-notify.sh
# Find: WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"
# Replace with your actual webhook URL
```

Notifications default to off — no shell profile changes needed. The `/discord-protocol` command enables them per-session via `CLAUDE_ENV_FILE`.

### Windows (WSL) — Recommended

```bash
# In your WSL terminal:
cp scripts/discord-notify.sh /home/YOUR_WSL_USER/.claude/
chmod +x /home/YOUR_WSL_USER/.claude/discord-notify.sh

# Edit and add your webhook URL
nano /home/YOUR_WSL_USER/.claude/discord-notify.sh
```

Notifications default to off — no shell profile changes needed. The `/discord-protocol` command enables them per-session via `CLAUDE_ENV_FILE`.

> Your WSL username is shown at your bash prompt. If unsure, run `whoami`.

### Windows (PowerShell — no WSL)

```powershell
# Copy to Claude config directory
Copy-Item scripts\discord-notify.ps1 "$env:USERPROFILE\.claude\"

# Edit and add your webhook URL
notepad "$env:USERPROFILE\.claude\discord-notify.ps1"
# Find: $WebhookUrl = "YOUR_WEBHOOK_URL_HERE"
# Replace with your actual webhook URL
```

> If scripts are blocked: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## Step 5: Configure Claude Code Hooks

Copy the settings template to your Claude config directory:

```bash
cp templates/settings-final.json ~/.claude/settings.json
```

**Or manually add to your existing `~/.claude/settings.json`:**

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

> **Note:** The `matcher: "*"` field is required in current Claude Code versions. Hooks without it will be silently ignored.

> **macOS/Linux:** `bash ~/.claude/discord-notify.sh`  
> **Windows WSL:** `bash /home/YOUR_WSL_USER/.claude/discord-notify.sh`  
> **Windows PowerShell:** `powershell.exe -File "$env:USERPROFILE\\.claude\\discord-notify.ps1"`

---

## Step 6: Install the Protocol

```bash
cp templates/CLAUDE.md ~/.claude/CLAUDE.md
```

This installs the STATUS notification protocol globally so it's active in every Claude Code session.

---

## Step 7: Install the Slash Command (Optional)

```bash
mkdir -p ~/.claude/commands
cp templates/discord-protocol.md ~/.claude/commands/discord-protocol.md
```

This enables the `/discord-protocol` slash command inside Claude Code.

---

## Step 8: Test It

**Test outbound notifications:**

Start Claude Code and give it a simple task:

```bash
claude code --dangerously-skip-permissions
```

Then send:
```
Test the Discord notification system. Create a file called hello.txt with "Hello World", then stop.
```

When Claude stops, you should receive a Discord notification within a few seconds.

**Test the bridge (two-way):**

1. Start a Claude Code session — the bridge auto-starts on the first tool call via PreToolUse hook
2. Send a message to `#claude-code-chat` from your phone
3. Check that the inbox is being written to:
```powershell
cat ~/.claude/discord-inbox.jsonl
```
4. On Claude's next tool call, it will read and clear the inbox and surface your message

**Expected notification:**
- Orange embed titled "🛑 Claude Code Stopped"
- Contains Claude's final STATUS message
- Footer shows session ID and timestamp

If notifications don't arrive, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Step 9: Use the `/discord-protocol` Command

`/discord-protocol` is a **mode switch**, not a session initializer. You can invoke it at any point during a Claude Code session — at the start, before stepping away mid-task, or any time you want notifications active. Use `/end-protocol` to turn it off without ending the session.

```
/discord-protocol Analyze the authentication system and write a security report
```

Or invoke it mid-session with no task argument to simply enable notifications:

```
/discord-protocol
```

### How Notification Gating Works

The system supports two mechanisms depending on your Claude Code version:

**Modern (CLAUDE_ENV_FILE available):**
Notifications are session-scoped. `/discord-protocol` writes `CLAUDE_DISCORD_NOTIFY=true` to `$CLAUDE_ENV_FILE` — a file Claude Code creates at session start and destroys at session end. No cleanup needed, no stale state.

**Legacy (toggle file fallback):**
If `CLAUDE_ENV_FILE` is not available in your Claude Code version, the system falls back to a toggle file at `~/.claude/notifications-enabled`. `/discord-protocol` creates it, `/end-protocol` removes it.

The hook script detects which mechanism is available and uses the right one automatically. Both work. The modern approach is cleaner — update Claude Code when a new version is available to get it.

Walk away. Your phone will buzz when Claude needs you.

---

## PowerShell Profile Setup (Windows)

For a cleaner workflow, add this to your PowerShell profile (`$PROFILE`):

```powershell
function discord-protocol {
    param([string]$Task)
    claude code --dangerously-skip-permissions --system-prompt @"
Follow the Discord Notification Protocol in CLAUDE.md exactly.
Your task: $Task
"@
}
```

Notifications default to off via `CLAUDE_ENV_FILE` — no profile variable needed. The `/discord-protocol` command enables them per-session automatically.

Then use it from any terminal:
```powershell
discord-protocol "Refactor the video editor scaling feature"
```

---

## MCP Integrations (Advanced)

The system works standalone but becomes significantly more powerful with MCP servers added to your Claude Desktop config (`claude_desktop_config.json`):

**Two-way Discord communication** — Claude can read responses from Discord, not just send:
- Discord MCP server enables Claude to monitor threads and receive your replies autonomously

**Vision capabilities** — Claude can analyze screenshots and visual output:
- Z.ai Vision MCP for visual analysis during autonomous sessions

**Browser automation** — Claude can interact with web interfaces:
- Claude in Chrome MCP for browser-based tasks

See [ADVANCED.md](ADVANCED.md) for MCP configuration details.

---

## Verifying Everything Works

Run this checklist:

- [ ] `~/.claude/discord-notify.sh` exists and is executable (`ls -la ~/.claude/`)
- [ ] Webhook URL is in the script (not the placeholder)
- [ ] `~/.claude/settings.json` has all four hooks (Stop, Notification, PreToolUse, PostToolUse)
- [ ] `~/.claude/CLAUDE.md` exists with the STATUS protocol
- [ ] `~/.claude/discord-bridge/` exists with `bridge.js`, `start-bridge.sh`, `node_modules/`
- [ ] Env vars set: `DISCORD_BOT_TOKEN`, `DISCORD_CHANNEL_ID`, `DISCORD_USER_ID`
- [ ] Message Content Intent enabled in Discord Developer Portal
- [ ] Test notification arrives in Discord
- [ ] Test message to `#claude-code-chat` appears in `discord-inbox.jsonl`

All checked? You're autonomous. 🚀
