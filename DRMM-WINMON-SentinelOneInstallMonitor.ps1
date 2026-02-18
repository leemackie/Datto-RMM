<#
.SYNOPSIS
SentinelOne installation monitor script for Datto RMM.
Checks if SentinelOne is installed

Written by Lee Mackie - 5G Networks

.HISTORY
Version 0.3 - Updated 11/09/25 - Rewokred component into simpler install logic only and moved other monitor functions to new component
Version 0.2 - Updated 21/12/22 - Improved script logic
#>
function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sentinel Agent"

switch ($installed) {
    $true { Write-Host "-- SentinelOne installed" }
    $false { Write-Host "!! SentinelOne NOT installed"
                Write-DRMMAlert "BAD | SentinelOne NOT installed"
                Exit 1
            }
}

Write-DRMMStatus "OK | SentinelOne installed"