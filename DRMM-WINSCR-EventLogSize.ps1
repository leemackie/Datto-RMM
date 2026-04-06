<#
.SYNOPSIS
Datto RMM component to set the event log size for a specified log based on user input from the script component variables.

Written by Lee Mackie - 5G Networks

.NOTES

.HISTORY
Version 1.0 - Initial release
#>

# Check if usrEventLogName is set and matches an existing log
if (-not $ENV:usrEventLogName -or -not $ENV:usrEventLogSize) {
    Write-Host "!! BAD: usrEventLogName or usrEventLogSize component variable not set."
    Exit 1
}

$varLogName = $ENV:usrEventLogName
$varSize = $ENV:usrEventLogSize

Write-Host "-- Log Name: $varLogName"
Write-Host "-- Selected Size: $varSize"

$targetLog = Get-WinEvent -ListLog $varLogName
if (-not $targetLog) {
    Write-Host "!! BAD: Event log '$varLogName' does not exist on the system."
    #Exit 1
}

# Parse the size to KB
[int]$thresholdKB = $varSize / 1KB

# Get the maximum size of the event log in KB
$currentMaxKB = $targetLog.MaximumSizeInBytes / 1KB
Write-Host "-- Current maximum size of '$varLogName' event log: $currentMaxKB KB."

$targetLog.MaximumSizeInBytes = $thresholdKB * 1024
$targetLog.SaveChanges()

$newLogInfo = Get-WinEvent -ListLog $varLogName
$newMaxKB = $newLogInfo.MaximumSizeInBytes / 1KB
if ($newMaxKB -ne $thresholdKB) {
    Write-Host "!! BAD: Failed to set the maximum size of '$varLogName' event log to $thresholdKB KB. Current size is still $newMaxKB KB."
    Exit 1
}

Write-Host "-- SUCCESS: Reconfigured the '$varLogName' event log maximum size: $thresholdKB KB."