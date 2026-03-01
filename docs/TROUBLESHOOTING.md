# Troubleshooting Guide
### Common issues and how to fix them

---

## Quick Diagnostics

Run these commands to check system status:

```bash
# 1. Check if files exist
ls -la ~/.claude/

# 2. Test webhook
curl -X POST "YOUR_WEBHOOK_URL" -H "Content-Type: application/json" -d '{"content":"Test"}'

# 3. Test hook script
echo '{"hook_event_name":"Stop","last_assistant_message":"Test","session_id":"test"}' | ~/.claude/discord-notify.sh

# 4. Verify settings
cat ~/.claude/settings.json | python -m json.tool
```

If all four work, the system should be functional.

---

## Issue: No Notifications Appearing

### Symptom
Claude Code works fine, but no Discord notifications when it stops.

### Diagnosis

**Step 1: Test webhook directly**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"Direct webhook test"}'
```

- ✅ Message appears in Discord → Webhook works, problem is elsewhere
- ❌ No message → Webhook URL is wrong or invalid

**Step 2: Test hook script**
```bash
echo '{"hook_event_name":"Stop","last_assistant_message":"Test notification","session_id":"test-001"}' | ~/.claude/discord-notify.sh
```

- ✅ Formatted notification appears → Script works, hooks not configured
- ❌ No notification → Script has issues

**Step 3: Check if hooks are running**
```bash
# Add temporary logging to script
# Add this line near the top of discord-notify.sh:
echo "Hook fired at $(date)" >> /tmp/claude-hook.log

# Then check after Claude Code runs:
cat /tmp/claude-hook.log
```

- ✅ Log file has entries → Hooks firing, script issue
- ❌ No log file → Hooks not configured

### Solutions

**If webhook URL is wrong:**
1. Go to Discord → Server Settings → Integrations → Webhooks
2. Find your webhook
3. Click "Copy Webhook URL"
4. Update in `~/.claude/discord-notify.sh`

**If script isn't executable:**
```bash
chmod +x ~/.claude/discord-notify.sh
```

**If hooks not configured:**
1. Check `~/.claude/settings.json` exists
2. Verify it has the "hooks" section
3. Restart Claude Code

---

## Issue: Malformed Notifications

### Symptom
Notifications appear but are garbled, empty, or show JSON instead of formatted embeds.

### Diagnosis

**Check the actual notification in Discord:**
- Shows raw JSON → Payload format issue
- Empty/blank → Message extraction failed
- Garbled text → Character escaping issue

### Solutions

**For raw JSON appearing:**

The script might be sending incorrect content type. Verify this line in the script:

```bash
curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \  # This line is critical
  -d "$PAYLOAD"
```

**For empty messages:**

Claude's last message might be empty. Add fallback:

```bash
if [ -z "$LAST_MESSAGE" ]; then
  LAST_MESSAGE="(No message provided)"
fi
```

**For character issues:**

The `sed` commands might not handle special characters. Enhanced version:

```bash
# Replace the ESCAPED_MESSAGE line with:
ESCAPED_MESSAGE=$(echo "$LAST_MESSAGE" | \
  sed 's/\\/\\\\/g' | \
  sed 's/"/\\"/g' | \
  sed ':a;N;$!ba;s/\n/\\n/g' | \
  sed 's/\t/\\t/g')
```

---

## Issue: Hook Script Fails Silently

### Symptom
No notifications, no errors, hooks appear to be configured correctly.

### Diagnosis

**Add debugging to the script:**

Edit `~/.claude/discord-notify.sh` and add:

```bash
# At the very top, after #!/bin/bash
exec 2>>/tmp/discord-hook-errors.log
set -x  # Enable command tracing

# Rest of script...
```

Then check errors:
```bash
cat /tmp/discord-hook-errors.log
```

### Common Silent Failures

**1. Missing dependencies**
```bash
# Check if curl is installed
which curl

# If not found, install:
# Ubuntu/Debian
sudo apt-get install curl

# macOS (usually pre-installed)
brew install curl
```

**2. JSON parsing issues**

If using `jq` for JSON parsing:
```bash
# Check if jq is installed
which jq

# Install if needed
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

**3. Permission issues**
```bash
# Verify script is executable
ls -la ~/.claude/discord-notify.sh
# Should show: -rwxr-xr-x

# Fix permissions
chmod +x ~/.claude/discord-notify.sh
```

---

## Issue: Windows PowerShell Script Not Working

### Symptom
PowerShell version of script doesn't send notifications.

### Diagnosis

**Test PowerShell execution:**
```powershell
# Run script manually
'{"hook_event_name":"Stop","last_assistant_message":"Test","session_id":"test"}' | & "$env:USERPROFILE\.claude\discord-notify.ps1"
```

### Solutions

**Execution Policy Issue:**
```powershell
# Check current policy
Get-ExecutionPolicy

# If "Restricted", fix it:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy
```

**Path Issues:**
```powershell
# Verify script exists
Test-Path "$env:USERPROFILE\.claude\discord-notify.ps1"

# If False, script is missing or path is wrong
```

**JSON Parsing Issues:**

PowerShell's JSON handling might fail on complex input. Enhanced version:

```powershell
# Replace the input parsing section with:
try {
    $JsonInput = $Input | ConvertFrom-Json
    $EventName = $JsonInput.hook_event_name
    $LastMessage = $JsonInput.last_assistant_message
    $SessionId = $JsonInput.session_id
} catch {
    # Fallback to regex parsing
    # (existing regex code)
}
```

---

## Issue: Notifications Delayed or Batched

### Symptom
Multiple notifications arrive at once, or significant delay between Claude stopping and notification appearing.

### Diagnosis

This is usually a Discord API issue, not the script.

### Solutions

**1. Check Discord status:**
Visit https://discordstatus.com/ to see if Discord is having issues.

**2. Reduce timeout:**

In `settings.json`, try lower timeout:
```json
{
  "hooks": {
    "Stop": [{
      "command": "bash ~/.claude/discord-notify.sh",
      "timeout": 5  // Reduced from 15
    }]
  }
}
```

**3. Check network:**

Test webhook latency:
```bash
time curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"Latency test"}'
```

If this takes >2 seconds, network/Discord might be slow.

---

## Issue: Hook Runs But Claude Continues Working

### Symptom
Notification appears, but Claude didn't actually stop - it kept working.

### Diagnosis

This happens when the hook fires on "Notification" events (permission prompts) not "Stop" events.

### Solution

**Filter notifications in the script:**

```bash
# Add this near the top of discord-notify.sh
if [ "$EVENT_NAME" != "Stop" ]; then
  exit 0  # Only notify on actual stops
fi
```

Or configure hooks to only fire on Stop:

```json
{
  "hooks": {
    "Stop": [{
      "command": "bash ~/.claude/discord-notify.sh",
      "timeout": 15
    }]
    // Remove "Notification" hook
  }
}
```

---

## Issue: Multiple Duplicate Notifications

### Symptom
Same notification appears 2-3 times in Discord.

### Diagnosis

Either the hook is configured multiple times, or the script is being called multiple times.

### Solution

**Check settings.json:**
```bash
cat ~/.claude/settings.json
```

Make sure "Stop" hook is only listed once:

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "bash ~/.claude/discord-notify.sh",
        "timeout": 15
      }
      // Make sure there's only ONE entry here
    ]
  }
}
```

**Check for duplicate script files:**
```bash
find ~ -name "discord-notify.sh" 2>/dev/null
```

Should only find one file at `~/.claude/discord-notify.sh`.

---

## Issue: WSL-Specific Problems

### Symptom
Script works in WSL bash, but Claude Code hooks don't trigger it.

### Diagnosis

Claude Code might be using Windows paths, not WSL paths.

### Solution

**Verify hook path in settings.json:**

**WRONG (Windows path):**
```json
"command": "bash C:\\Users\\username\\.claude\\discord-notify.sh"
```

**CORRECT (WSL path):**
```json
"command": "bash ~/.claude/discord-notify.sh"
```

**Or use wsl command:**
```json
"command": "wsl bash ~/.claude/discord-notify.sh"
```

**Verify the script is in WSL filesystem:**
```bash
# Should be at:
/home/YOUR_USERNAME/.claude/discord-notify.sh

# NOT at:
/mnt/c/Users/YOUR_USERNAME/.claude/discord-notify.sh
```

---

## Issue: STATUS Format Not Appearing

### Symptom
Notifications appear but don't follow the structured STATUS format.

### Diagnosis

Claude isn't loading the CLAUDE.md protocol.

### Solution

**Verify CLAUDE.md exists:**
```bash
ls -la ~/.claude/CLAUDE.md
```

**Check Claude Code is loading it:**

Start Claude Code and immediately ask:
```
"What protocols are you following?"
```

Claude should mention the Discord Notification Protocol.

**If not loading:**

1. Make sure file is named exactly `CLAUDE.md` (case-sensitive)
2. Verify it's in `~/.claude/` not `~/.claude/commands/`
3. Restart Claude Code

**Project-specific protocol:**

You can also place CLAUDE.md in your project's `.claude/` directory:
```bash
mkdir -p ./.claude
cp ~/.claude/CLAUDE.md ./.claude/
```

Project-level protocol takes precedence over global.

---

## Issue: Mobile Notifications Not Working

### Symptom
Notifications appear in Discord desktop/web, but phone doesn't buzz.

### Solution

**Check Discord mobile app settings:**

1. Open Discord app on phone
2. Go to Settings → Notifications
3. Enable "Push Notifications"
4. Go to your server settings
5. Enable notifications for your server
6. Enable notifications for the specific channel

**Check phone settings:**

- iOS: Settings → Discord → Notifications → Allow
- Android: Settings → Apps → Discord → Notifications → Enable

**Test with direct message:**

Ask someone to DM you on Discord. If that buzzes but webhook doesn't:
- Webhook notifications might be treated differently
- Try @mentioning yourself in the webhook message

**Enhanced webhook payload:**

```bash
# Modify the payload to include a mention:
PAYLOAD=$(cat <<EOF
{
  "content": "<@YOUR_USER_ID>",
  "embeds": [{
    "title": "$TITLE",
    "description": "$ESCAPED_MESSAGE",
    "color": $COLOR,
    "footer": {
      "text": "Session: $SESSION_ID | $TIMESTAMP"
    }
  }]
}
EOF
)
```

Replace `YOUR_USER_ID` with your Discord user ID (right-click your name → Copy ID).

---

## Issue: Hook Timeout Errors

### Symptom
Logs show "Hook timeout" errors.

### Diagnosis

The webhook request is taking too long (>15 seconds).

### Solution

**Increase timeout in settings.json:**
```json
{
  "hooks": {
    "Stop": [{
      "command": "bash ~/.claude/discord-notify.sh",
      "timeout": 30  // Increased from 15
    }]
  }
}
```

**Or make script non-blocking:**

```bash
# At the end of discord-notify.sh, run curl in background:
curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  > /dev/null 2>&1 &  # Note the & at the end

exit 0
```

---

## Issue: Special Characters Breaking Notifications

### Symptom
Notifications fail when Claude's message contains quotes, backticks, or special characters.

### Solution

**Enhanced character escaping:**

Replace the ESCAPED_MESSAGE line with:

```bash
# More robust escaping
ESCAPED_MESSAGE=$(echo "$LAST_MESSAGE" | \
  sed 's/\\/\\\\/g' | \          # Escape backslashes first
  sed 's/"/\\"/g' | \             # Escape quotes
  sed 's/`/\\`/g' | \             # Escape backticks
  sed ':a;N;$!ba;s/\n/\\n/g' | \  # Escape newlines
  sed 's/\t/\\t/g' | \            # Escape tabs
  sed 's/\r//g')                  # Remove carriage returns
```

---

## Still Having Issues?

### Get Help

1. **Check the logs:**
   - Hook errors: `/tmp/discord-hook-errors.log`
   - Claude Code logs: Run with `--verbose` flag
   - Discord webhook response: Add `-v` to curl command

2. **Minimal test:**
   Create a minimal test script:
   ```bash
   #!/bin/bash
   curl -X POST "YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content":"Minimal test"}'
   ```
   If this works, the issue is in the main script.

3. **GitHub Issues:**
   Open an issue with:
   - Your OS and version
   - Error messages (sanitize sensitive data!)
   - What you've tried
   - Output of diagnostic commands

4. **Discord Community:**
   Join our Discord server for real-time help (link in main README).

---

## Prevention Tips

**Regular testing:**
```bash
# Test the full chain monthly
echo '{"hook_event_name":"Stop","last_assistant_message":"Monthly test","session_id":"test"}' | ~/.claude/discord-notify.sh
```

**Keep backups:**
```bash
# Backup your working configuration
cp ~/.claude/settings.json ~/.claude/settings.json.backup
cp ~/.claude/discord-notify.sh ~/.claude/discord-notify.sh.backup
```

**Version control:**
```bash
# Track changes to your setup
cd ~/.claude
git init
git add settings.json CLAUDE.md discord-notify.sh
git commit -m "Working autonomous setup"
```

---

*Most issues are simple configuration problems. Work through the diagnostics systematically and you'll find the issue!*
