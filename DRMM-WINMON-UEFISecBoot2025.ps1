<#
.SYNOPSIS
Datto RMM component to check devices with a UEFI BIOS for the 2025 Secure Boot UEFI certificate status and determine if remediation is required.
https://support.microsoft.com/en-au/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e

.NOTES
Author: Lee Mackie - 5G Networks
Date Created: 29/01/2026

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

$secureBootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot"
$servicingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"
$availableKey = "AvailableUpdates"
$statusKey = "UEFICA2023Status"
$errorKey = "UEFICA2023Error"

try {
    if ($(Confirm-SecureBootUEFI) -eq $false) {
        Write-DRMMStatus "OK: Secure Boot is disabled. No action required."
        Exit
    }
} catch {
    Write-DRMMStatus "WARN: Secure Boot status could not be determined. System may not support UEFI."
    Exit
}

$certStatus = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Windows UEFI CA 2023'
if ($certStatus -eq $true) {
    Write-DRMMStatus "OK: Secure Boot is enabled and Windows UEFI CA 2023 is present. No action required."
    Exit
}

try {
    $availableUpdates = (Get-ItemProperty -Path $secureBootPath -Name $availableKey -ErrorAction Stop).$availableKey
    $secureBootUpdateState = (Get-ItemProperty -Path $servicingPath -Name $statusKey -ErrorAction Stop).$statusKey
    $secureBootErrorState = (Get-ItemProperty -Path $servicingPath -Name $errorKey -ErrorAction SilentlyContinue).$errorKey

    switch ($secureBootErrorState) {
        1032 { Write-DRMMAlert "BAD: Error Detected `nThe Secure Boot update was not applied due to a known incompatibility with the current BitLocker configuration."; Exit 1 }
        1033 { Write-DRMMAlert "BAD: Error Detected `nPotentially revoked boot manager was detected in EFI partition."; Exit 1 }
        1795 { Write-DRMMAlert "BAD: Error Detected `nThe system firmware returned an error when attempting to update a Secure Boot variable. (Check event logs for firmware error code)"; Exit 1 }
        1796 { Write-DRMMAlert "BAD: Error Detected `nThe Secure Boot update failed to update a Secure Boot variable with error. (Check event logs for firmware error code)"; Exit 1 }
    }

    switch ($availableUpdates) {
        0 { Write-DRMMAlert "BAD: Update required, update registry key not set. Execute component to add registry key to facilitate update."; Exit 1 }
        {$_ -ge 2 -and $_ -le 4096} { Write-DRMMStatus "OK: Secure Boot update is queued to execute"; Exit }
        #16640 { Write-DRMMStatus "OK: Secure Boot update is pending reboot to complete" }
        22852 { Write-DRMMStatus "WARN: Secure Boot update is pending install."; Exit }
    }

    if ($secureBootUpdateState -eq "InProgress" -and $availableUpdates -eq 16640 -and $secureBootErrorState -eq 1800) {
        Write-DRMMStatus "WARN: Secure Boot update is in progress and reboot is required to complete"
    } elseif ($secureBootUpdateState -eq "Updated" -and $availableUpdates -eq 16384) {
        Write-DRMMStatus "OK: Secure Boot update has been completed successfully"
    } elseif ($secureBootUpdateState -eq "InProgress") {
        Write-DRMMStatus "WARN: Secure Boot update is in progress"
    } else {
        Write-DRMMAlert "BAD: Secure Boot update status is unknown. Remediation may be required"
        Exit 1
    }
} catch {
    Write-DRMMAlert "BAD: Unable to determine Secure Boot update status. Remediation may be required"
    Exit 1
}