<#
.SYNOPSIS
Using Datto RMM, either install or uninstall Windows Defender features on Windows Server systems.
Depending on the action specified in the 'usrAction' environment variable, this script will either install or remove Windows Defender.
Intended for use in environments where third-party antivirus solutions are deployed, and Windows Defender needs to be managed accordingly.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Version 1.0 - Initial release
#>

$action = $env:usrAction
$defenderStatus = $(Get-MpComputerStatus).AMRunningMode

Write-Host "-- Action: $action"
if ($action -eq "Remove") {
    if ($defenderStatus -ne "Normal") {
        Write-Host "## WARNING: Defender not in NORMAL mode - uninstallation process should not be required."
        Exit 0
    }

    Write-Host "-- Remove Windows Defender"
    try {
        # Remove Windows Defender
        Uninstall-WindowsFeature Windows-Defender | Out-Null

        if ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption -like '*2016*') {
            Write-Host "-- Server 2016 detected, also removing GUI feature"
            # For Server 2016, Remove the GUI also
            Uninstall-WindowsFeature Windows-Defender-Gui | Out-Null
        }
    } catch {
        Write-Host "!! Removal of the Windows Defender features failed."
        Write-Host $_
        Exit 1
    }
} else {
    if ($defenderStatus -eq "Normal") {
        Write-Host "## WARNING: Defender in NORMAL mode - installation process should not be required."
        Exit 0
    }

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
        Write-Host $_
        Exit 1
    }

}

Write-Host "-- $action completed successfully!"