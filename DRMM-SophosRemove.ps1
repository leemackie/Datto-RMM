<#
.SYNOPSIS
Using Datto RMM, uninstall Sophos Central Endpoint
Written by Lee Mackie - 5G Networks

.NOTES
Version 2.0: Major re-release, adding in functionality to reinstall Windows Defender
#>

Write-Host "** Executing uninstallation - this will fail if you have not disabled tamper protection at the bare minimum **"
Write-Host "** It is recommended you remove all products from the endpoints in Sophos Central before executing the removal script **"
Write-Host "------------------------------------------"

$tpStatus = & "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -status

if ($tpStatus -contains "SED Tamper Protection is enabled") {
    Write-Host "!! Tamper protection code not provided but Tamper Protection is turned on - this script will not work."
    Exit 1
}

### Stop the 2 core services that prevent uninstallation
Write-Host "-- Stopping services"
Stop-Service "SAVService" -Force -ErrorAction SilentlyContinue
Stop-Service "Sophos Autoupdate Service" -Force -ErrorAction SilentlyContinue

### Removing registry key that has been known to prevent uninstallation from succeeding
Write-Host "-- Removing IsUpdating registry key (if exists)"
Remove-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Sophos\AutoUpdate\UpdateStatus -Name "IsUpdating" -ErrorAction SilentlyContinue

### These are generally the remenants left over after you remove the products from Sophos Central
# Sophos Endpoint Agent
Write-Host "-- Attempting uninstallation of Sophos Endpoint Agent"
try {
    Start-Process -FilePath "C:\Program Files\Sophos\Sophos Endpoint Agent\SophosUninstall.exe" -ArgumentList "--quiet" -Wait
} catch {
    Write-Host "-- Attempt to uninstall using SophosUninstall.exe failed - falling back to older uninstallcli.exe"
    try {
        Start-Process -FilePath "C:\Program Files\Sophos\Sophos Endpoint Agent\uninstallcli.exe" -Wait
    } catch {
        Write-Host "!! Failed to run either uninstall executable - review and attempt manual uninstallation"
        Write-Host "!! Script will now exit with failure status"
        Exit 1
    }
}


### Clean up the ProgramData folders
Write-Host "-- Attempting clean up of ProgramData\Sophos directory"
Remove-Item -Path "C:\ProgramData\Sophos" -Force -ErrorAction SilentlyContinue -Recurse

### Re-installation of Windows Defender
Write-Host "-- Install Windows Defender"
try {
    # For Windows Server 1803 and later, including Windows Server 2019 and 2022
    Dism /Online /Enable-Feature /FeatureName:Windows-Defender | Out-Null

    if ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption -like '*2016*') {
        Write-Host "-- Server 2016 detected, installation additional features"
        # For Windows Server 2016
        Dism /Online /Enable-Feature /FeatureName:Windows-Defender-Features | Out-Null
        Dism /Online /Enable-Feature /FeatureName:Windows-Defender-Gui | Out-Null
    }
} catch {
    Write-Host "!! Installation of the Windows Defender features failed."
    Wite-Host $_
}

### Script finished
Write-Host "### Script is now completed - we do not perform any checks if uninstall was successful."
Write-Host "### Review services and confirm removed, and review logs found in C:\Windows\Temp for confirmation if required"