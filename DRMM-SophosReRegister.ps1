## Re-register an incorrectly deleted device in Sophos Central, or move device to a different tenancy
## Obviously only works for Windows.

# Check for the Sophos customer token - this is critical to the process
if ($ENV:SophosCustToken -eq $null)	{
    Write-Host "! Customer Token Not Set or Missing"
	Exit 1
} else {
    Write-Host "# CustomerToken = "$ENV:SophosCustToken""
}

# Check for, and remove any old installer files
if ((Test-Path "C:\ProgramData\CentraStage\Temp\SophosSetup.exe") -eq $true) {
    Remove-Item "C:\ProgramData\CentraStage\Temp\SophosSetup.exe" -Force
}

#Force PowerShell to use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download of the Central Customer Installer
Write-Host "# Downloading Sophos Central Installer"
Invoke-WebRequest -Uri "https://central.sophos.com/api/partners/download/windows/v1/$ENV:SophosCustToken/SophosSetup.exe" -OutFile "C:\ProgramData\CentraStage\Temp\SophosSetup.exe"

if ((Test-Path "C:\ProgramData\CentraStage\Temp\SophosSetup.exe") -eq $true) {
    Write-Host "# Sophos Setup Installer downloaded successfully"
} else {
    Write-Host "! Sophos Setup Installer failed to download"
    Exit 1
}

$tpStatus = & "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -status

if ($tpStatus -contains "SED Tamper Protection is enabled") {
    Write-Host "# Tamper protection enabled, attempting to disable"
    if (!($ENV:TPCode)) {
        Write-Host "! Tamper protection code not provided but Tamper Protection is turned on - this script will not work."
        Exit 1
    } else {
        Start-Process "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ArgumentList "-OverrideTPoff $env:TPCode" -Wait -NoNewWindow
        $tpStatus = & "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -status
    }

    if ($tpStatus -contains "SED Tamper Protection is enabled") {
        Write-Host "! Failed to disable tamper protection, please try again."
        Exit 1
    } else {
        Write-Host "# Tamper protection turned off"
    }
}

# Stop the Management Communication Service
Stop-Service "Sophos MCS Client" -Force
Write-Host "# Stopped Sophos MCS Client service"

# Remove the credentials and old EndpointIdentity files
Remove-Item "C:\ProgramData\Sophos\Management Communications System\Endpoint\Persist\Credentials" -Force -Verbose -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Sophos\Management Communications System\Endpoint\Persist\EndpointIdentity.txt" -Force -Verbose -ErrorAction SilentlyContinue

# Execute the installer we downloaded earlier
Write-Host "# Attempting re-registration using Sophos installation file"
Write-Host "? This may fail if the machine requires a reboot"
Start-Process "C:\ProgramData\CentraStage\Temp\SophosSetup.exe" -ArgumentList "--registeronly --customertoken=$ENV:SophosCustToken --products=none --quiet" -Wait -NoNewWindow

# Start all processes again
Start-Service "Sophos MCS Client"
Write-Host "# MCS service resumed"
if ($ENV:TPCode) {
    Start-Process "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ArgumentList "-ResumeTP $env:TPCode" -Wait -NoNewWindow
    Start-Process "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ArgumentList "-Status" -Wait  -NoNewWindow
}

Remove-Item "C:\ProgramData\CentraStage\Temp\SophosSetup.exe" -Force

Write-Host "## Scipt completed - please check for correct re-registration in Sophos Central"