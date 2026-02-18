<#
.SYNOPSIS
Datto RMM component to set the required registry key for the 2025 Secure Boot UEFI certificate update on devices with a UEFI BIOS.
https://support.microsoft.com/en-au/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e

.NOTES
Author: Lee Mackie - 5G Networks
Date Created: 29/01/2026

.HISTORY
Version 1.0 - Initial release
#>

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
$valueName = 'AvailableUpdates'
$desiredValue = 0x5944

Write-Host "- INFO: We will atttempt to set the registry value $valueName to $desiredValue under $regPath"
Write-Host "- If the value is not currently 0, this indicates that the update process has already been attempted and script will exit with an error."
Write-Host "- This script does not trigger the update process, it only sets the registry key to enable the update to occur. The update process is handled`n by a scheduled task that fires every 12 hours."
Write-Host "- If you have any issues and need assistance see the folllowing links:"
Write-Host "--- https://support.microsoft.com/en-au/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e"
Write-Host "--- https://support.microsoft.com/en-au/topic/registry-key-updates-for-secure-boot-windows-devices-with-it-managed-updates-a7be69c9-4634-42e1-9ca1-df06f43f360d"
Write-Host "--- https://support.microsoft.com/en-au/topic/secure-boot-certificate-updates-guidance-for-it-professionals-and-organizations-e2b43f9f-b424-42df-bc6a-8476db65ab2f"
Write-Host "`n-------------------------------------`n"

# Read current value
try {
    $prop = Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop
    $current = $prop.$valueName
} catch {
    Write-Host "ERROR: Required registry key/value not found. Likely means machine is not patched to a high enough level."
    Exit 1
}

if ($current -eq 0) {
    # Apply the update value
    try {
        New-Item -Path $regPath -Force | Out-Null
        New-ItemProperty -Path $regPath -Name $valueName -Value $desiredValue -PropertyType DWord -Force | Out-Null
    } catch {
        Write-Host "ERROR: Failed to set registry value: $_"
        Exit 1
    }
} else {
    Write-Host "ERROR: Registry value $valueName is set to $current, expected 0 if process has not been attempted."
    Exit 1
}

# Verify
try {
    $new = (Get-ItemProperty -Path $regPath -Name $valueName).$valueName
    if ($new -eq $desiredValue) {
        Write-Host "OK: Successfully set $valueName to $desiredValue"
    } else {
        Write-Host "ERROR: Verification failed: $valueName value is $new, expected $desiredValue"
        Exit 1
    }
} catch {
    Write-Host "ERROR: Verification failed: $_"
    Exit 1
}