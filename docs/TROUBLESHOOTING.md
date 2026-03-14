# Troubleshooting

Solutions to common issues with the Autonomous Claude Code system.

---

## No Discord Notification Arriving

**Check 1: Script is executable**
```bash
ls -la ~/.claude/discord-notify.sh
# Should show: -rwxr-xr-x
```
If not:
```bash
chmod +x ~/.claude/discord-notify.sh
```

**Check 2: Webhook URL is set**
```bash
grep WEBHOOK_URL ~/.claude/discord-notify.sh
# Should show your actual URL, not "YOUR_WEBHOOK_URL_HERE"
```

**Check 3: Test the webhook directly**
```bash
curl -s -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content": "Test notification from Claude Code setup"}'
```
If this doesn't appear in Discord, the webhook URL is wrong. Regenerate it in Discord Server Settings → Integrations.

**Check 4: Hooks are configured**
```bash
cat ~/.claude/settings.json
# Should contain "Stop" and "Notification" hook entries
```

**Check 5: Windows WSL path mismatch**

The most common Windows issue. Hooks run via WSL bash, so the script **must** be in your WSL filesystem:
```bash
# Correct (WSL path)
/home/YOUR_WSL_USER/.claude/discord-notify.sh

# Wrong (Windows path — hooks can't reach this)
C:\Users\drew_\.claude\discord-notify.sh
```

Check your `settings.json` hook command uses the WSL path format.

---

## Hook Script Not Executing

**Verify Claude Code sees the hook:**
```bash
# Run a quick test task, then check if the script ran
claude code
# Give it: "Say hello and stop immediately"
# Watch terminal for any hook errors
```

**Check JSON syntax in settings.json:**
```bash
cat ~/.claude/settings.json | python3 -m json.tool
# If it errors, you have a syntax issue in the JSON
```

**Manually test the hook script:**
```bash
echo '{"hook_event_name":"Stop","last_assistant_message":"Test message","session_id":"test-001","stop_hook_active":false}' | bash ~/.claude/discord-notify.sh
```
Should send a notification. If it errors, look at the output for clues.

---

## STATUS Format Not Appearing in Notification

The notification arrives but just shows raw text, not the structured STATUS format.

This means CLAUDE.md isn't loaded. Check:
```bash
ls ~/.claude/CLAUDE.md
cat ~/.claude/CLAUDE.md | head -5
# Should show "# Discord Notification Protocol"
```

If missing:
```bash
cp templates/CLAUDE.md ~/.claude/CLAUDE.md
```

Claude Code automatically loads `~/.claude/CLAUDE.md` at session start. No restart needed.

---

## `/discord-protocol` Command Not Found

```bash
ls ~/.claude/commands/
# Should show discord-protocol.md
```

If missing:
```bash
mkdir -p ~/.claude/commands
cp templates/discord-protocol.md ~/.claude/commands/
```

Then **restart Claude Code** — custom commands load at startup.

> Note: Use `.md` files for slash commands, not `.json`. Claude Code auto-discovers `.md` command files.

---

## PowerShell Issues (Windows)

**Scripts not recognized:**
```powershell
# Check execution policy
Get-ExecutionPolicy

# If "Restricted", change it:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Profile not loading:**
```powershell
# Load profile manually
. $PROFILE

# Check profile exists
Test-Path $PROFILE

# Create if missing
New-Item -Path $PROFILE -ItemType File -Force
```

**discord-protocol function not found:**
```powershell
# Verify it's in your profile
Get-Content $PROFILE | Select-String "discord-protocol"

# If missing, add it:
Add-Content $PROFILE @'
function discord-protocol {
    param([string]$Task)
    claude code --dangerously-skip-permissions --system-prompt "Follow the Discord Notification Protocol in CLAUDE.md exactly. Your task: $Task"
}
'@
. $PROFILE
```

---

## Git Issues

**Lock file error:**
```powershell
Remove-Item .git/index.lock -Force
```

**Commit message opens Vim:**
```bash
# Always use -m flag
git commit -m "your message here"

# Or set VS Code as default editor
git config --global core.editor "code --wait"
```

---

## Server Won't Start (AetherWave / Node projects)

**Kill stuck processes:**
```powershell
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name python -ErrorAction SilentlyContinue | Stop-Process -Force
```

Then restart your dev server.

---

## Database Connection Failed

If you're working on a project with a database and Claude reports connection errors:

1. Check your `.env` file has the correct `DATABASE_URL`
2. Verify the database service is running (Neon, Supabase, etc. can sleep)
3. Test the connection directly:
```bash
node -e "const { Pool } = require('pg'); const p = new Pool({connectionString: process.env.DATABASE_URL}); p.query('SELECT 1').then(() => console.log('Connected')).catch(console.error)"
```

---

## Notification Arrives But Content is Cut Off

Discord embeds have a 4096 character limit on the description field. The hook script caps messages at 1500 characters to stay well within this.

If you want more content, split your STATUS messages or adjust the `head -c 1500` value in the script. Keep in mind very long notifications are harder to read on mobile — the point is actionable brevity.

---

## Notifications Not Firing Even After `/discord-protocol`

**Check 1: Which mechanism is active**
```bash
echo $CLAUDE_ENV_FILE
```
- If this returns a path → modern mechanism. Check that `CLAUDE_DISCORD_NOTIFY=true` was written:
```bash
cat $CLAUDE_ENV_FILE
```
- If this returns empty → legacy toggle file mechanism. Check that the file exists:
```bash
ls ~/.claude/notifications-enabled
```

**Check 2: Hook script has the version detection logic**
```bash
grep -A 10 "NOTIFICATION GATE" ~/.claude/discord-notify.sh
```
If you see only one mechanism and not both, you have an older version of the script. Update from the repo.

**Check 3: `CLAUDE_ENV_FILE` not present (most common)**
`CLAUDE_ENV_FILE` may not be implemented in your current Claude Code version. The hook script falls back to the toggle file automatically — but only if it was updated from this repo. Older versions of `discord-notify.sh` that only check `CLAUDE_ENV_FILE` will silently exit without firing.

Fix: update `~/.claude/discord-notify.sh` from `scripts/discord-notify.sh` in this repo.

---


---

## Discord Bridge Not Receiving Messages

**Check 1: Is the bridge running?**
```powershell
cat ~/.claude/discord-bridge/bridge.heartbeat
# Should show a recent Unix timestamp (within 30 seconds)
```
If the heartbeat is stale or missing, the bridge isn't running. Start it manually:
```powershell
cd ~/.claude/discord-bridge
node bridge.js
```

**Check 2: Is the inbox being written to?**

Send a message to `#claude-code-chat`, then check:
```powershell
cat ~/.claude/discord-inbox.jsonl
```
If empty after sending — the bridge is running but not receiving. See checks 3-5.

**Check 3: Message Content Intent**

Discord Developer Portal → Applications → your bot → Bot → Privileged Gateway Intents → **Message Content Intent must be ON**.

Without this, the bridge receives events but `message.content` is empty and nothing gets written.

**Check 4: Verify env vars are set**
```powershell
echo $env:DISCORD_BOT_TOKEN
echo $env:DISCORD_CHANNEL_ID
echo $env:DISCORD_USER_ID
```
All three must return values. If empty, add them to your shell profile and reload.

**Check 5: Channel and User ID match**

Right-click `#claude-code-chat` → Copy Channel ID. Right-click your username → Copy User ID. Confirm both match the env vars you set.

---

## Zombie Bridge Instances (Windows — Message Duplication)

If you're seeing the same message written hundreds of times to `discord-inbox.jsonl`, you have zombie bridge processes accumulating.

**Root cause:** On Windows, the old PID-based liveness check in `start.sh` always failed, spawning a new bridge on every tool call. Each instance writes every incoming message independently.

**Fix:** The current `start-bridge.sh` uses heartbeat-based liveness detection — no PID checks. Update from the repo if you have an older version.

**Emergency cleanup (kill all zombie bridges):**
```powershell
powershell.exe -ExecutionPolicy Bypass -File ~/.claude/discord-bridge/kill-all-bridges.ps1
```

Then restart the bridge:
```powershell
cd ~/.claude/discord-bridge
node bridge.js
```

---

## Bridge Writes to Inbox But Claude Doesn't See Messages

The PostToolUse poll has stale throttle state. Check:
```powershell
ls ~/.claude/discord-poll/
```

If `last-poll` timestamp is old, clear the state:
```powershell
Remove-Item ~/.claude/discord-poll/last-poll
Remove-Item ~/.claude/discord-poll/last-msg-id
```

Next tool call will poll fresh and surface queued messages.

---

## hooks Not Firing (Settings Format Issue)

Current Claude Code versions require the `matcher` field on all hooks. The old format (direct command objects) is silently ignored.

**Wrong (old format):**
```json
"Stop": [{"type": "command", "command": "bash ~/.claude/discord-notify.sh"}]
```

**Correct (current format):**
```json
"Stop": [{"matcher": "*", "hooks": [{"type": "command", "command": "bash ~/.claude/discord-notify.sh", "timeout": 15}]}]
```

Use `templates/settings-final.json` from this repo — it has the correct format for all four hooks.

---



If the Discord MCP server starts but can't authenticate — bot appears offline or `read-messages`/`send-message` tools fail — dotenv is not finding the `.env` file.

This is a Windows-specific issue. On Windows, Claude Desktop may launch the MCP server from a different working directory than the project root, causing dotenv's relative path lookup to fail silently.

**Fix:** Hardcode the absolute path in `E:\Gits\discordmcp\build\index.js`:

```javascript
dotenvMod.default.config({ path: 'E:/Gits/discordmcp/.env' });
```

Note forward slashes — Node.js handles them correctly on Windows.

After editing, restart Claude Desktop for the change to take effect. The bot should authenticate and the MCP tools should become available in your session.

> On macOS/Linux this issue typically doesn't occur as the working directory resolves correctly from the relative path.

---

## Discord Channel Architecture

This system uses two separate Discord channels — by design, not limitation:

**Webhook → `#claude-logs` (or dedicated thread)**
- One-way: Claude → Discord only
- Fires on Stop, Notification, and Error events
- Per-session named threads auto-created — full history in Discord sidebar
- High volume during active sessions — keep it isolated

**Bridge Bot → `#claude-code-chat` (top-level channel)**
- Two-way: your messages → bridge bot → local inbox → Claude via PostToolUse hook
- Real-time WebSocket delivery — messages land in seconds, not minutes
- Send instructions mid-run from your phone; Claude picks them up on next tool call
- Only your messages (filtered by User ID) are written to the inbox

**Recommended Discord setup:**
```
#claude-logs          ← webhook fires here (notifications, session archives)
#claude-code-chat     ← bridge bot listens here (your instructions to Claude)
```

Clear separation: notifications don't bury your instructions, instructions don't get lost in notification noise.

---

## Still Stuck?

Open a [GitHub Issue](https://github.com/AetherWave-Studio/autonomous-claude-code/issues) with:
- Your platform (Windows/WSL/Mac/Linux)
- Output of `cat ~/.claude/settings.json`
- Output of the manual hook test above
- What you expected vs. what happened

---

## Permission Prompts Still Appearing After settings.local.json Setup

**Check 1: Multiple settings.local.json locations**

Claude Code checks each `.claude/` directory independently. If you have project-level `.claude/` folders, they need their own `settings.local.json`:

```powershell
# Find all .claude directories on Windows
Get-ChildItem -Path C:\Users\YOUR_USER -Recurse -Filter ".claude" -Directory 2>$null
Get-ChildItem -Path E:\Gits -Recurse -Filter ".claude" -Directory 2>$null
```

Copy `settings.local.json` to each location found.

**Check 2: settings.local.json syntax**
```powershell
cat ~/.claude/settings.local.json | python3 -m json.tool
```
Any syntax error causes the entire file to be silently ignored.

**Check 3: Permission format**

The allow list uses glob patterns. `Bash(*)` covers all bash commands. Individual entries like `Bash(npm run dev:*)` are redundant once `Bash(*)` is present.

---

## Listening Mode Not Working (Backoff Poll Loop)

If Claude completes a task but doesn't enter listening mode:

**Check 1: `/discord-protocol` was invoked this session**

Listening mode is part of the `/discord-protocol` slash command. If it wasn't invoked, Claude has no instructions to enter the poll loop.

**Check 2: Background task support**

The backoff loop uses `sleep N` as a background task with `block=true` to wait for completion. Verify Claude Code supports background tasks in your version.

**Check 3: Inbox path**

The poll loop reads `~/.claude/discord-inbox.jsonl`. Confirm the bridge is writing to the same path:
```powershell
cat ~/.claude/discord-bridge/bridge.js | grep inboxPath
```
