<#
.SYNOPSIS
Datto RMM component to review the event log maximum size and generate an alert if the size is below a specified threshold.

Written by Lee Mackie - 5G Networks

.NOTES

.HISTORY
Version 1.0 - Initial release
#>

function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

function exitScript ($exitCode = 0) {
    Write-Host "<-End Diagnostic->"
    Exit $exitCode
}

Write-Host "<-Start Diagnostic->"

# Check if usrEventLogName is set and matches an existing log
if (-not $ENV:usrEventLogName -or -not $ENV:usrEventLogSize) {
    Write-Host "!! BAD: usrEventLogName or usrEventLogSize component variable not set."
    Write-DRMMStatus "BAD: usrEventLogName component variable not set."
    exitScript
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

# Compare and alert if below threshold
if ($currentMaxKB -lt $thresholdKB) {
    Write-Host "Alert: Event log '$varLogName' maximum size ($currentMaxKB KB) is below threshold ($thresholdKB KB)."
    Write-DRMMAlert "BAD: Event log '$varLogName' maximum size ($currentMaxKB KB) is below threshold ($thresholdKB KB)."
    exitScript 1
} else {
    Write-Host "Event log '$varLogName' maximum size ($currentMaxKB KB) is at or above threshold ($thresholdKB KB)."
    Write-DRMMStatus "OK: Event log '$varLogName' maximum size ($currentMaxKB KB) is at or above threshold ($thresholdKB KB)."
    exitScript
}