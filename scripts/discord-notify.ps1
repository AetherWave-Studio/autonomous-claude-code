# Discord Notification Hook for Claude Code (PowerShell)
# Sends formatted status updates to Discord when Claude stops
#
# Installation:
#   1. Copy this file to $env:USERPROFILE\.claude\discord-notify.ps1
#   2. Update $WebhookUrl below with your Discord webhook
#   3. Add hook to $env:USERPROFILE\.claude\settings.json
#      Use: "command": "powershell.exe -File $env:USERPROFILE\.claude\discord-notify.ps1"

# ============================================
# TOGGLE CHECK
# ============================================
$ToggleFile = "$env:USERPROFILE\.claude\notifications-enabled"

if (-not (Test-Path $ToggleFile)) {
    exit 0
}

# ============================================
# CONFIGURATION
# ============================================

# Discord webhook URL (REQUIRED)
$WebhookUrl = "YOUR_WEBHOOK_URL_HERE"

# Optional: Add thread_id parameter if posting to a specific forum thread
# $WebhookUrl = "https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN?thread_id=YOUR_THREAD_ID"

# Embed colors (decimal format)
$ColorStop = 15105570      # Orange - Normal stop
$ColorPermission = 16776960 # Yellow - Permission needed  
$ColorError = 15548997      # Red - Error occurred

# ============================================
# SCRIPT - DO NOT EDIT BELOW
# ============================================

# Read input from stdin
$Input = [Console]::In.ReadToEnd()

# Parse JSON (basic extraction - for complex needs, use ConvertFrom-Json)
$EventName = if ($Input -match '"hook_event_name":"([^"]*)"') { $matches[1] } else { "" }
$LastMessage = if ($Input -match '"last_assistant_message":"([^"]*)"') { 
    $matches[1].Substring(0, [Math]::Min(1500, $matches[1].Length))
} else { "" }
$SessionId = if ($Input -match '"session_id":"([^"]*)"') { $matches[1] } else { "unknown" }
$StopHookActive = if ($Input -match '"stop_hook_active":(true|false)') { $matches[1] } else { "false" }

# Skip if stop hook is active (forced continuation)
if ($StopHookActive -eq "true") {
    exit 0
}

# Get timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"

# Determine embed properties based on event type
switch ($EventName) {
    "Stop" {
        $Color = $ColorStop
        $Title = "🛑 Claude Code Stopped"
    }
    "Notification" {
        $Color = $ColorPermission
        $Title = "⚠️ Permission Needed"
    }
    "Error" {
        $Color = $ColorError
        $Title = "❌ Claude Code Error"
    }
    default {
        $Color = 15548997
        $Title = "ℹ️ Claude Code Event: $EventName"
    }
}

# Escape message for JSON
$EscapedMessage = $LastMessage -replace '"', '\"' -replace "`n", "\n" -replace "`r", ""

# Build Discord embed payload
$Payload = @{
    embeds = @(
        @{
            title = $Title
            description = $EscapedMessage
            color = $Color
            footer = @{
                text = "Session: $SessionId | $Timestamp"
            }
        }
    )
} | ConvertTo-Json -Depth 10

# Send to Discord
try {
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Payload -ContentType "application/json" -ErrorAction SilentlyContinue | Out-Null
} catch {
    # Silently fail - don't block Claude's execution
}

exit 0
