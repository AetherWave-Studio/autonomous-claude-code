# Complete Setup Guide
### Get autonomous coding working in 20 minutes

This guide walks you through setting up the autonomous Claude Code system from scratch.

---

## Prerequisites

Before starting, make sure you have:

- **Claude Code** installed and working ([Install Guide](https://docs.claude.com/code))
- **Discord account** (free tier works fine)
- **Terminal access** (bash, zsh, or PowerShell)
- **20 minutes** of focused time

**Operating Systems:**
- ✅ macOS
- ✅ Linux
- ✅ Windows (via WSL or PowerShell)

---

## Part 1: Discord Webhook Setup (5 minutes)

### Step 1.1: Create a Discord Server (If Needed)

If you don't have a Discord server:

1. Open Discord (app or web)
2. Click the "+" button in the left sidebar
3. Select "Create My Own"
4. Name it (e.g., "Dev Notifications")
5. Click "Create"

### Step 1.2: Create a Webhook

1. Right-click your server name
2. Select "Server Settings"
3. Click "Integrations" in the left menu
4. Click "Webhooks" (or "Create Webhook" if first time)
5. Click "New Webhook"
6. Name it: "Claude Code Alerts"
7. Select the channel (recommend creating a dedicated #dev-notifications channel)
8. Click "Copy Webhook URL"

**Your webhook URL looks like:**
```
https://discord.com/api/webhooks/1234567890/AbCdEfGhIjKlMnOpQrStUvWxYz
```

**Save this URL** - you'll need it shortly!

### Step 1.3: Test the Webhook

Quick test to verify it works:

```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"Test notification from terminal"}'
```

Check Discord - you should see the message appear!

---

## Part 2: Install Hook Script (5 minutes)

### Step 2.1: Clone This Repository

```bash
# Clone the repo
git clone https://github.com/yourusername/autonomous-claude-code.git
cd autonomous-claude-code
```

### Step 2.2: Install the Hook Script

**For macOS/Linux:**

```bash
# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Copy the hook script
cp scripts/discord-notify.sh ~/.claude/

# Make it executable
chmod +x ~/.claude/discord-notify.sh

# Edit and add your webhook URL
nano ~/.claude/discord-notify.sh
```

**For Windows (WSL):**

```bash
# Same as macOS/Linux above - WSL uses bash
mkdir -p ~/.claude
cp scripts/discord-notify.sh ~/.claude/
chmod +x ~/.claude/discord-notify.sh
nano ~/.claude/discord-notify.sh
```

**For Windows (PowerShell):**

```powershell
# Create .claude directory
New-Item -Path "$env:USERPROFILE\.claude" -ItemType Directory -Force

# Copy PowerShell script
Copy-Item scripts\discord-notify.ps1 "$env:USERPROFILE\.claude\"

# Edit to add webhook URL
notepad "$env:USERPROFILE\.claude\discord-notify.ps1"
```

### Step 2.3: Add Your Webhook URL

In the script file you just opened, find this line:

```bash
WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"
```

Replace `YOUR_WEBHOOK_URL_HERE` with the URL you copied from Discord.

**Example:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/1234567890/AbCdEfGhIjKlMnOpQrStUvWxYz"
```

Save and close the file.

### Step 2.4: Test the Hook Script

**macOS/Linux/WSL:**
```bash
echo '{"hook_event_name":"Stop","last_assistant_message":"Test notification from hook script","session_id":"test-001"}' | ~/.claude/discord-notify.sh
```

**Windows PowerShell:**
```powershell
'{"hook_event_name":"Stop","last_assistant_message":"Test notification from hook script","session_id":"test-001"}' | & "$env:USERPROFILE\.claude\discord-notify.ps1"
```

Check Discord - you should see a formatted notification appear!

---

## Part 3: Configure Claude Code Hooks (5 minutes)

### Step 3.1: Create/Edit settings.json

Claude Code reads hooks configuration from `~/.claude/settings.json`.

**Check if it exists:**

```bash
# macOS/Linux/WSL
ls ~/.claude/settings.json

# Windows PowerShell
Test-Path "$env:USERPROFILE\.claude\settings.json"
```

### Step 3.2: Add Hooks Configuration

**If file doesn't exist, create it:**

```bash
# macOS/Linux/WSL
cp templates/settings.json ~/.claude/settings.json

# Windows PowerShell
Copy-Item templates\settings.json "$env:USERPROFILE\.claude\settings.json"
```

**If file exists, add the hooks section:**

Open the file:
```bash
# macOS/Linux/WSL
nano ~/.claude/settings.json

# Windows PowerShell
notepad "$env:USERPROFILE\.claude\settings.json"
```

Add or merge this configuration:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/discord-notify.sh",
            "timeout": 15
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/discord-notify.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

**For Windows PowerShell**, use this instead:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File %USERPROFILE%\\.claude\\discord-notify.ps1",
            "timeout": 15
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File %USERPROFILE%\\.claude\\discord-notify.ps1",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

Save the file.

---

## Part 4: Install Protocol Document (3 minutes)

The protocol document trains Claude to write structured, useful notifications.

### Step 4.1: Copy CLAUDE.md

```bash
# macOS/Linux/WSL
cp templates/CLAUDE.md ~/.claude/

# Windows PowerShell
Copy-Item templates\CLAUDE.md "$env:USERPROFILE\.claude\"
```

### Step 4.2: Verify Installation

```bash
# macOS/Linux/WSL
ls -la ~/.claude/

# Should show:
# - discord-notify.sh (executable)
# - settings.json
# - CLAUDE.md

# Windows PowerShell
Get-ChildItem "$env:USERPROFILE\.claude"
```

---

## Part 5: Toggle System (Optional but Recommended)

The notification system includes a toggle so you can turn notifications on/off without restarting Claude Code or editing settings.json.

### How It Works

Both hook scripts check for a toggle file (`~/.claude/notifications-enabled`). If the file exists, notifications are sent. If it doesn't, the hook exits silently.

**Default state: notifications are OFF.**

### For PowerShell Users

Add convenience functions to your PowerShell profile:
```powershell
# Open profile
notepad $PROFILE

# Copy the functions from scripts/powershell-functions.ps1
# Save and reload:
. $PROFILE
```

Now you can use:
- `discord-on` - Enable notifications
- `discord-off` - Disable notifications
- `discord-status` - Check current state

### For Bash Users

Add these to your `.bashrc` or `.zshrc`:
```bash
alias discord-on='touch ~/.claude/notifications-enabled && echo "Discord notifications ENABLED"'
alias discord-off='rm -f ~/.claude/notifications-enabled && echo "Discord notifications DISABLED"'
alias discord-status='[ -f ~/.claude/notifications-enabled ] && echo "ENABLED" || echo "DISABLED"'
```

### Using Slash Commands

The toggle is built into the slash commands:
- `/discord-protocol "task"` - Enables notifications AND starts autonomous work
- `/end-protocol` - Disables notifications

### Manual Toggle

```bash
# Enable
touch ~/.claude/notifications-enabled

# Disable
rm ~/.claude/notifications-enabled
```

---

## Part 6: Test the Complete System (2 minutes)

Time to verify everything works end-to-end!

### Step 5.1: Start Claude Code

```bash
claude code
```

### Step 5.2: Give a Simple Test Task

In the Claude Code session, try:

```
"Create a simple hello world function in test.js and write a test for it"
```

### Step 5.3: Watch for Notification

When Claude stops (completes the task), you should:

1. ✅ See Claude's response in terminal
2. ✅ Hear/see your phone buzz (if Discord app installed)
3. ✅ See notification in Discord channel

The notification should look like:

```
🛑 Claude Code Stopped

**STATUS: COMPLETED**

- What was done: Created hello world function and test
- Current state: Function working, test passing
- Next step: Ready for review
- Session: test-hello-001
- Modified: test.js, test.spec.js
- Test: npm test

Session: test-hello-001 | 2026-02-24 19:30:45 PST
```

**If you see this notification, congratulations! The system is working!** 🎉

---

## Part 7: Optional - Slash Command (2 minutes)

Add a slash command for quick activation.

### Step 6.1: Create commands directory

```bash
# macOS/Linux/WSL
mkdir -p ~/.claude/commands

# Windows PowerShell
New-Item -Path "$env:USERPROFILE\.claude\commands" -ItemType Directory -Force
```

### Step 6.2: Copy command definition

```bash
# macOS/Linux/WSL
cp templates/commands/discord-protocol.md ~/.claude/commands/

# Windows PowerShell
Copy-Item templates\commands\discord-protocol.md "$env:USERPROFILE\.claude\commands\"
```

### Step 6.3: Test the command

Restart Claude Code, then try:

```
/discord-protocol "Analyze the package.json file and suggest improvements"
```

Claude Code should activate with the protocol loaded.

---

## Verification Checklist

Before moving on, verify:

- ✅ Discord webhook working (test message appeared)
- ✅ Hook script working (test notification appeared)
- ✅ settings.json configured correctly
- ✅ CLAUDE.md installed
- ✅ End-to-end test successful (Claude Code → Discord notification)
- ✅ Phone receives notifications (if Discord app installed)

---

## Next Steps

### Immediate

1. **Try a real task:**
   ```bash
   claude code --dangerously-skip-permissions
   "Analyze this codebase and create a technical debt report"
   ```

2. **Monitor from phone:**
   - Install Discord mobile app
   - Enable push notifications for your server
   - Test that phone buzzes when Claude stops

3. **Refine your protocol:**
   - Edit `~/.claude/CLAUDE.md`
   - Add project-specific guidelines
   - Customize STATUS format if needed

### Advanced

1. **Multi-agent setup** - See [ADVANCED.md](ADVANCED.md)
2. **Supervisor pattern** - Automate routine decisions
3. **Custom protocols** - Project-specific templates

---

## Troubleshooting

### Notifications not appearing

**Check Discord webhook:**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"Direct test"}'
```

If this fails, webhook URL is wrong.

**Check hook script permissions:**
```bash
ls -la ~/.claude/discord-notify.sh
# Should show: -rwxr-xr-x (executable)
```

If not executable:
```bash
chmod +x ~/.claude/discord-notify.sh
```

**Check settings.json syntax:**
```bash
cat ~/.claude/settings.json | python -m json.tool
# Should show formatted JSON without errors
```

**Check Claude Code is using settings:**
```bash
# Start Claude Code with verbose logging
claude code --verbose
# Look for "Loaded settings from..." message
```

### Hook script runs but no Discord notification

**Test the script directly:**
```bash
echo '{"hook_event_name":"Stop","last_assistant_message":"Test","session_id":"test"}' | ~/.claude/discord-notify.sh
```

**Check for errors:**
```bash
# Add this to the script for debugging:
# echo "$PAYLOAD" > /tmp/discord-debug.json
# Check the file for malformed JSON
```

**Verify webhook URL is set:**
```bash
grep "WEBHOOK_URL=" ~/.claude/discord-notify.sh
# Should show your actual webhook URL, not placeholder
```

### Windows-specific issues

**PowerShell execution policy:**
```powershell
Get-ExecutionPolicy
# If "Restricted", change it:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Path issues:**
```powershell
# Verify script exists
Test-Path "$env:USERPROFILE\.claude\discord-notify.ps1"

# Test running directly
& "$env:USERPROFILE\.claude\discord-notify.ps1"
```

### WSL-specific issues

**Ensure script is in WSL filesystem:**
```bash
# Script should be at
/home/YOUR_USERNAME/.claude/discord-notify.sh

# NOT at
/mnt/c/Users/YOUR_USERNAME/.claude/discord-notify.sh
```

**Check curl is installed:**
```bash
which curl
# Should show: /usr/bin/curl

# If not installed:
sudo apt-get install curl
```

---

## Common Questions

**Q: Do I need to restart Claude Code after changing settings?**  
A: Yes, Claude Code reads settings.json at startup.

**Q: Can I use different webhooks for different projects?**  
A: Yes! Create project-specific CLAUDE.md files with different webhook URLs, or use environment variables.

**Q: Will this work with Claude API (not Claude Code)?**  
A: The hook system is Claude Code specific, but you can implement similar webhooks in your own code that calls Claude API.

**Q: Can I use Slack instead of Discord?**  
A: Yes! Slack has webhooks too. Just change the webhook URL and adjust the payload format to match Slack's API.

**Q: How do I stop getting notifications?**
A: Run `discord-off` (if you added the PowerShell/bash functions), use `/end-protocol` in Claude Code, or manually `rm ~/.claude/notifications-enabled`. The hooks stay registered but the scripts exit silently when the toggle file is absent.

**Q: Can other people see my notifications?**  
A: Only people in your Discord server who have access to the channel where the webhook posts.

---

## Tips for Success

**Start small:**
- Test with trivial tasks first
- Verify notifications work before autonomous work
- Build confidence in the system

**Monitor closely at first:**
- Keep Discord open initially
- Watch how Claude structures notifications
- Refine protocol based on what works

**Iterate on protocol:**
- Edit CLAUDE.md based on experience
- Add examples from your actual work
- Make STATUS format work for your workflow

**Trust but verify:**
- Review all AI-generated code
- Use version control
- Have rollback plan

---

## You're Ready!

The system is installed. Time to experience autonomous coding.

Try this:

```bash
claude code --dangerously-skip-permissions
"Analyze the most complex file in this codebase. Find potential bugs, suggest refactorings, and create a detailed report."
```

Then put your phone in your pocket and go make coffee. ☕

When it buzzes, you'll have your report.

**Welcome to autonomous development.** 🚀

---

*Having issues? Open an issue on GitHub or check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more help.*
