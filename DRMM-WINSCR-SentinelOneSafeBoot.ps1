<#
.SYNOPSIS
Add SafeBoot bypass to SentinelOne installation on a Domain Controller backed up using Veeam (or any other server targeted)
Reference: https://community.sentinelone.com/s/article/000006996

Written by Lee Mackie - 5G Networks

.NOTES

.HISTORY
- Version 1.0 - Initial script creation
#>

try {
    $sentinelInstall = Get-Childitem "C:\Program Files\SentinelOne\" | Sort-Object CreationTime -Descending | Select-Object -First 1 -ExpandProperty Name

    if (Test-Path "C:\Program Files\SentinelOne\$sentinelInstall\sentinelctl.exe") {
        $before = . "C:\Program Files\SentinelOne\$sentinelInstall\sentinelctl.exe" config antiTamperingConfig.allowSignedKnownAndVerifiedToSafeBoot
        Start-Process -FilePath "C:\Program Files\SentinelOne\$sentinelInstall\sentinelctl.exe" -ArgumentList "config antiTamperingConfig.allowSignedKnownAndVerifiedToSafeBoot true -k ""$ENV:Passphrase""" -Wait
        $after = . "C:\Program Files\SentinelOne\$sentinelInstall\sentinelctl.exe" config antiTamperingConfig.allowSignedKnownAndVerifiedToSafeBoot
    }

} catch {
    Write-Host "!! An error occurred: $_"
    Exit 1
}

Write-Host "-- SafeBoot variable change performed successfully"
Write-Host "-- Before: $before"
Write-Host "-- After: $after"
Write-Host "-- If the value did not change to 'True' after running this script, please review the SentinelOne documentation."
Write-Host "   https://community.sentinelone.com/s/article/000006996"