<#
.SYNOPSIS
SentinelOne installation script for Datto RMM.
Checks if SentinelOne is already installed, checks for required environment variables and initiates installation with proper exit code handling.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Application
!! Requires EXE installation file for x64 and ARM architectures to be included in the component package.
   x64: S1Installer_x64.exe
   ARM: S1Installer_arm.exe

.HISTORY
- Version 0.4 - Cleaned up installation logic, added ability to use site variable at script level. Added output of last 100 lines of log to StdErr if install fails.
- Version 0.5 - Migrated from MSI to EXE installer, updated exit code handling.
- Version 1.0 - Completed release, fixed token precedence so that the component level token variable takes precedence over site level variable.
- Version 1.1 - Added Clean opreation if SentinelOne is already installed and passphrase is provided.
- Version 1.2 - Added ARM processor architecture detection and support for ARM based devices with the correct installer.
  Also added check for the installation file to ensure it exists before attempting installation and output a failure message if the file is not found.
- Version 1.2.1 - Fixed clean operation
#>

function Get-SentinelOneInstalled {
    $Global:sentinelagent = $null
    $Global:installed = $null
    $Global:installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sentinel Agent"
    $Global:sentinelagent = Get-Service -name "SentinelAgent" -ea SilentlyContinue
}

Write-Host "-- Checking the DRMM variables"
# Determine system Architecture to ensure we use the right installer
$endpointArch = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object OSArchitecture
switch -wildcard ($endpointArch.OSArchitecture) {
    "*ARM*" { $s1Installer = "S1Installer_arm.exe" }
    Default { $s1Installer = "S1Installer_x64.exe" }
}

# Check if S1CustToken is set, if not fail.
if ($ENV:usrS1CustToken) {
    Write-Host "# You have set the component variable for S1 Customer token. Proceeding with component variable."
    Write-Host "## NOTE: This takes precedence over site variable if both are set."
    $s1Token = $ENV:usrS1CustToken
} elseif ($ENV:S1CustToken) {
    $s1Token = $ENV:S1CustToken
    Write-Host "# Using site variable for S1 Customer token."
} else {
    Write-Host "!! FAILURE: No S1 Customer token found for script execution - cannot proceed with installation"
    Exit 1
}
Write-Host "# S1 Customer Token: $s1Token"
Write-Host "# System Architecture: $($endpointArch.OSArchitecture)"
Write-Host "# Installer Filename: $s1Installer"

# Check if S1 is already installed, and either clean or exit if so.
Get-SentinelOneInstalled
if ($sentinelAgent -or $installed) {
    if ($usrClean -match "true") {
        Write-Host "-- SentinelOne already installed"
        Write-Host "-- Clean requested, proceeding with Clean operation first"
        $repair = Start-Process $s1Installer -ArgumentList "-c -q -t $s1Token" -Wait -PassThru
        switch ($repair.ExitCode) {
            0 { Write-Host "-- SUCCESS: Clean completed successfully with exit code 0. Proceeding with installation." }
            200 { Write-Host "?? WARNING: Clean completed successfully with exit code 200 but requires reboot to complete. Reboot and run script again."; exit }
            203 { Write-Host "?? WARNING: Clean completed successfully with exit code 203 but requires reboot to complete. Reboot and run script again."; exit }
            default { Write-Host "!! FAILURE: Clean completed with unexpected exit code $($repair.ExitCode)";
            Write-Host "-- You can review the exit codes in your S1 Knowledgebase: <S1 URL>/soc-docs/en/return-codes-after-installing-or-updating-windows-agents.html#return-codes-after-installing-or-updating-windows-agent";
            Exit 1 }
        }
    } else {
        Write-Host "?? WARNING: SentinelOne Agent already installed."
        Write-Host "-- Clean not flagged, exiting script without making changes."
        Exit
    }
}

# Execute installation of S1 installer
if (-not (Test-Path $PWD\$s1Installer)) {
    Write-Host "!! FAILURE: Installer file $s1Installer not found in component package. Cannot proceed with installation."
    Write-Host "!! Did you forget to attach the installer files to the component? Please attach the correct installer for the architecture of the devices you are targeting."
    Exit 1
}

Write-Host "-- Installing SentinelOne Agent"
$install = Start-Process $s1Installer -ArgumentList "-t $s1Token -q" -Wait -PassThru

# Check for exit codes
switch ($install.ExitCode) {
    0 { Write-Host "-- SUCCESS: Installation completed successfully with exit code 0" }
    12 { Write-Host "-- SUCCESS: Installation completed successfully with exit code 12" }
    205 { Write-Host "!! FAILURE: Installation failed with exit code 205 - installation cancelled by user"; $installFailed = $true }
    206 { Write-Host "!! FAILURE: Installation failed with exit code 206 - parsed a bad argument (has something changed in the version of installer your using?)"; $installFailed = $true }
    1002 { Write-Host "!! FAILURE: Installation failed with exit code 1002 - installation or upgrade canceled. Another installer is already running."; $installFailed = $true }
    1003 { Write-Host "!! FAILURE: Installation failed with exit code 1602 - installation or upgrade canceled. Another MSI installer is already running."; $installFailed = $true }
    2002 { Write-Host "!! FAILURE: Installation failed with exit code 2002 - check site token you have defined is correct and review logging."; $installFailed = $true }
    2013 { Write-Host "!! FAILURE: Installation failed with exit code 2013 - Insufficient system resources."; $installFailed = $true }
    2015 { Write-Host "!! FAILURE: Installation failed with exit code 2015 - System requirements not met."; $installFailed = $true }
    default { Write-Host "!! FAILURE: Installation completed with unexpected exit code $($install.ExitCode)";
    Write-Host "-- You can review the exit codes in your S1 Knowledgebase: <S1 URL>/soc-docs/en/return-codes-after-installing-or-updating-windows-agents.html#return-codes-after-installing-or-updating-windows-agent";
    $installFailed = $true }
}

if ($installFailed -eq $true) {
    Exit 1
}

Get-SentinelOneInstalled
if ($sentinelagent.Status -eq "Running"){
    Write-Host "-- SUCCESS: SentinelOne Agent service running"
} else {
    Write-Host "?? WARNING: SentinelOne Agent service not running, but is installed. Reboot likely required."
}