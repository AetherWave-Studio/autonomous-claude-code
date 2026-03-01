# PowerShell Functions for Discord Notification Toggle
# Add these to your PowerShell profile ($PROFILE)

# Enable Discord notifications
function Enable-DiscordNotifications {
    New-Item -Path "$env:USERPROFILE\.claude\notifications-enabled" -ItemType File -Force | Out-Null
    Write-Host "Discord notifications ENABLED" -ForegroundColor Green
}

# Disable Discord notifications
function Disable-DiscordNotifications {
    Remove-Item -Path "$env:USERPROFILE\.claude\notifications-enabled" -Force -ErrorAction SilentlyContinue
    Write-Host "Discord notifications DISABLED" -ForegroundColor Red
}

# Check notification status
function Get-DiscordNotificationStatus {
    if (Test-Path "$env:USERPROFILE\.claude\notifications-enabled") {
        Write-Host "Discord notifications are ENABLED" -ForegroundColor Green
    } else {
        Write-Host "Discord notifications are DISABLED" -ForegroundColor Red
    }
}

# Convenience aliases
Set-Alias discord-on Enable-DiscordNotifications
Set-Alias discord-off Disable-DiscordNotifications
Set-Alias discord-status Get-DiscordNotificationStatus
