# Emergency utility: Kill all Discord bridge Node.js processes
# Usage: powershell.exe -ExecutionPolicy Bypass -File kill-all-bridges.ps1
#
# Use this if zombie bridge processes have accumulated.
# After running, restart with: bash start-bridge.sh

Get-WmiObject Win32_Process -Filter "CommandLine LIKE '%bridge.js%' AND Name='node.exe'" | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
Write-Host "All bridge processes killed"
