<#
.SYNOPSIS
Using Datto RMM, enable or disable SMBv1 on a Windows server - 2012 or above.
Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Variable: usrAction [String]

.HISTORY
Version 1.0 - Initial release
#>

$usrAction = $env:usrAction
Write-Host "- SMBv1 selected action: $usrAction"

try {
    if ($usrAction -eq "disable") {
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        Write-Host "- SMBv1 has been disabled on this server."
    } else {
        Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force
        Write-Host "- SMBv1 has been enabled on this server."
    }
} catch {
    Write-Host "!! An error occurred while trying to change the SMBv1 setting: $_"
    Exit 1
}