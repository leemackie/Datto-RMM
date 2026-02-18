<#
.SYNOPSIS
SentinelOne status monitor script for Datto RMM.
Checks if SentinelOne is healthy, checking the service status and agent status.

Written by Lee Mackie - 5G Networks

.HISTORY
Version 0.1 - 11/09/25 - Initial release
Version 0.2 - 11/11/25 - Fixed service name detection
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

function Write-DRMMDiagnostic ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

$sentinelService = Get-Service -name "SentinelAgent" -ea SilentlyContinue
$sentinelInstall = Get-Childitem "C:\Program Files\SentinelOne\" | Sort-Object CreationTime -Descending | Select-Object -First 1
$sentinelStatus = & "$($sentinelinstall.FullName)\sentinelctl.exe" status

switch ($sentinelService) {
    "Running" { Write-Host "-- SentinelOne Agent service running" }
    "Stopped" { Write-Host "-- SentinelOne Agent service is NOT running"
                $sentinelService | Start-Service -ea SilentlyContinue
                if ($sentinelService.Status -eq "Stopped") {
                    Write-Host "!! SentinelOne Agent service is NOT running and start request failed"
                    Write-DRMMAlert "BAD | SentinelOne Agent service is NOT running. Attempted restart of service failed."
                    Write-DRMMDiagnostic "S1 Status:`n $sentinelstatus"
                    Exit 1
                } else {
                    Write-Host "-- SentinelOne Agent service was NOT running but has been started"
                }
    }
}

if ($sentinelStatus -contains "SentinelMonitor is loaded" -and $sentinelStatus -contains "SentinelAgent is loaded") {
    Write-Host "-- SentinelOne status: Monitor and Agent loaded"
} else {
    Write-Host "!! SentinelOne status: Monitor or Agent NOT loaded"
    write-DRMMAlert "BAD | Monitor or Agent NOT loaded"
    Write-DRMMDiagnostic "S1 Status:`n $sentinelStatus"
    Exit 1
}

Write-DRMMStatus "OK | SentinelOne healthy - agent and monitor loaded"