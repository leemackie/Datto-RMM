# SentinelOne installer for Datto RMM
# Written by Lee Mackie - 5G Networks
# Version 0.2 - Updated 30/11/23
# Requires S1CustToken to be set on the customers DRMM Site Variables
# Requires S1Installer.msi be attached the installation component **MUST BE MSI VERSION**

function Get-SentinelOneInstalled {
    $Global:sentinelagent = $null
    $Global:installed = $null
    $Global:installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sentinel Agent"
    $Global:sentinelagent = Get-Service -name "SentinelAgent" -ea SilentlyContinue
}

Write-Host ""

# Check if S1 is already installed, and if so exit
Get-SentinelOneInstalled
if ($sentinelAgent -or $installed) {
    Write-Host "-- WARNING: SentinelOne already installed - exiting"
    Exit 0
}

# Check if S1CustToken is set, if not fail.
Write-Host "-- Checking the DRMM variables"
if ($ENV:S1CustToken -eq $null) {
    Write-Host "-- FAILURE: S1 Customer token not set or missing - please check your site variable for S1CustToken and try again"
	Exit 1
} else {
    Write-Host "-- S1 Customer Token: $ENV:S1CustToken"
}

# Enable installation logging if required
if ($ENV:Logging -eq "true") {
    $logpath = "C:\ProgramData\CentraStage\Temp\DRMM-S1InstallLog.log"
    $logging = "/lv* $logpath"
    Write-Host "-- Install logging enabled: $logpath"
}

# Execute installation of S1 installer MSI
$installer = "S1Installer.msi"
$installargs = "/i $installer /quiet /norestart $logging SITE_TOKEN=$ENV:S1CustToken"
$install = Start-Process msiexec.exe -ArgumentList $installargs -Wait -PassThru

# Check for exit codes
if (($install.ExitCode -eq '0') -or ($install.ExitCode -eq '3010')) {
    Write-Host "-- SUCCESS: Successfully installed SentinelOne agent"
    Get-SentinelOneInstalled
    if ($sentinelagent.Status -eq "Running"){
        Write-Host "-- SUCCESS: SentinelOne Agent service running"
    } else {
        Write-Host "-- WARNING: SentinelOne Agent service not running, but is installed. Reboot likely required."
    }
} elseif ($install.ExitCode -eq '1618') {
    Write-Host "-- FAILURE: Installation failed; the endpoint must be restarted prior to attempting installation again"
    Exit 1
} elseif ($install.ExitCode -eq '1602') {
    Write-Host "-- FAILURE: Installation failed; the installer reports cancelled by user. Review your Event Logs or enable installation logging to troubleshoot further"
    Exit 1
} else {
    Write-Host "-- FAILURE: Installation failed, please review event logs or enable installationg logging and try again"
    Exit 1
}