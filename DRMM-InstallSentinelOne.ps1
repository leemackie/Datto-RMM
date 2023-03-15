# Improved SentinelOne monitor for Datto RMM
# Written by Lee Mackie - 5G Networks
# Version 0.1 - Updated 21/12/22
# Requires S1CustToken to be set on the customers DRMM Site Variables
# Requires S1Installer.msi be attached the installation component **MUST BE MSI VERSION**
function Get-SentinelOneInstalled {
    $Global:installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sentinel Agent"
    $Global:sentinelagent = Get-Service -name "SentinelAgent" -ea SilentlyContinue
}

# Check for the Site Variables
Write-Host ""
Write-Host "-- Checking the DRMM variables"

# Check if S1CustToken is set, if not fail.
if ($ENV:S1CustToken -eq $null) {
    Write-Host "-- Customer Token Not Set or Missing"
	Exit 1
} else {
    Write-Host "-- CustomerToken = $ENV:S1CustToken"
}

# Execute installation of S1 installer MSI
$installer = "S1Installer.msi"
$installargs = "/i $installer /quiet /norestart SITE_TOKEN=$ENV:S1CustToken"
$install = Start-Process msiexec.exe -ArgumentList $installargs -Wait -PassThru

# Check for exit codes
if (($install.ExitCode -eq '0') -or ($install.ExitCode -eq '3010')) {
    Write-Host "-- Successfully installed SentinelOne agent"
    Get-SentinelOneInstalled
    if ($sentinelagent.Status -eq "Running"){
        Write-Host "-- SentinelOne Agent service running"
        Exit 0
    } else {
        Write-Host "-- SentinelOne Agent service not running, but is installed. Reboot likely required."
        Exit 1
    }
} elseif ($install.ExitCode -eq '1618') {
    Write-Host "-- Installation failed; the endpoint must be restarted prior to reinstalling SentinelOne"
    Exit 1
} else {
    Write-Host "-- Installation failed, please review event logs and try again"
    Exit 1
}