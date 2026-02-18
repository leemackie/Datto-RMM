<#
.SYNOPSIS
Using Datto RMM, reinstall the RMM agent on a Windows machine.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Version 1.0 - Initial release
Version 1.1 - Refactored script to run the reinstall as a seperate script to prevent the job from never completing. Significantly simplified code and improved reliability.
#>

$Platform = "syrah"
$SiteID = $ENV:CS_PROFILE_UID

@"

Start-Transcript $ENV:TEMP\DRMM-DRMMReinstallation.log -Append -NoClobber

Write-Host "- Having a nap - 30 seconds"
Start-Sleep -Seconds 30

# First check if Agent is installed and instantly exit if missing
If (Get-Service CagService -ErrorAction SilentlyContinue) {
    Write-Host "- Datto RMM Agent detected - proceeding with uninstall and reinstall."
    Start-Process "C:\Program Files (x86)\CentraStage\uninst.exe" -Wait -PassThru
} else {
    Write-Host "!! ERROR: Script cannot find CagService - this is too broken to automatically fix (or RMM isn't actually installed). `n We'll try to install anyways."
}

Remove-Item "C:\ProgramData\CentraStage" -Force -Recurse -ErrorAction Continue
Remove-Item "C:\Program Files (x86)\CentraStage\" -Force -Recurse -ErrorAction Continue

# Set the TLS 1.2 security protocol
try {
    [Net.ServicePointManager]::SecurityProtocol=[Enum]::ToObject([Net.SecurityProtocolType],3072)
} catch {
    Write-Host "!! ERROR: Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script."
    exit 1
}

# Download the agent
try {
    (New-Object System.Net.WebClient).DownloadFile("https://$Platform.centrastage.net/csm/profile/downloadAgent/$SiteID", "$env:TEMP\DRMMSetup.exe")
} catch {
    Write-Host "!! ERROR: Agent installer download failed."
    exit 1
}

Write-Host "- Agent download completed"

# Install the Agent
Write-Host "- Starting Agent installation"
Start-Process "$env:TEMP\DRMMSetup.exe" -Verb RunAs -Wait -PassThru

Start-Sleep -Seconds 15

Write-Host - Removing the Agent installer after installation execution"
Remove-Item "$env:TEMP\DRMMSetup.exe" -Force

Write-Host "Script completed."
Stop-Transcript

"@ | Out-File -FilePath $ENV:TEMP\DRMM-DRMMReinstallation.ps1 -Encoding ASCII -Force

Write-Host "- Queuing removal and reinstallation of Datto RMM agent for ~30 seconds time."
Write-Host "- Please check the log file at $ENV:TEMP\DRMM-DRMMReinstallation.log for progress and results."
Write-Host "- This script will complete regardless of reinstallation success."
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ENV:TEMP\DRMM-DRMMReinstallation.ps1`" -WindowStyle Hidden" -Verb RunAs