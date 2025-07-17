Start-Transcript C:\Windows\Temp\DRMM-DRMMReinstallation.log -Append -NoClobber
$Platform="syrah"
$SiteID=$ENV:CS_PROFILE_UID

# First check if Agent is installed and instantly exit if so
If (Get-Service CagService -ErrorAction SilentlyContinue) {
    $uninstall = Start-Process "C:\Program Files (x86)\CentraStage\uninst.exe" -Wait -PassThru
    if ($uninstall.ExitCode -ne 0) {
        Write-Host "ERROR: Uninstallation failed! `n Fix the machine manually"
        Exit 1
    }
} else {
    Write-Host "ERROR: Script cannot find CagService - this is too broken to automatically fix. `n Fix the machine mannually."
    Exit 1
}

Remove-Item "C:\ProgramData\CentraStage" -Force -Recurse -ErrorAction Continue
Remove-Item "C:\Program Files (x86)\CentraStage\" -Force -Recurse -ErrorAction Continue

# Download the Agent
$AgentURL="https://$Platform.centrastage.net/csm/profile/downloadAgent/$SiteID"
$DownloadStart=Get-Date
Write-Output "Starting Agent download at $(Get-Date -Format HH:mm) from $AgentURL"

# Set the TLS 1.2 security protocol
try {
    [Net.ServicePointManager]::SecurityProtocol=[Enum]::ToObject([Net.SecurityProtocolType],3072)
} catch {
    Write-Host "Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script."
    exit 1
}

# Download the agent
try {
    (New-Object System.Net.WebClient).DownloadFile($AgentURL, "$env:TEMP\DRMMSetup.exe")
} catch {
    Write-Host "Agent installer download failed. Exit message:`r`n$_"
    exit 1
}

Write-Host "Agent download completed in $((Get-Date).Subtract($DownloadStart).Seconds) seconds`r`n`r`n"

# Install the Agent
$InstallStart=Get-Date
Write-Host "Starting Agent install to target site at $(Get-Date -Format HH:mm)..."
& "$env:TEMP\DRMMSetup.exe" | Out-Null

Write-Host "Agent install completed at $(Get-Date -Format HH:mm) in $((Get-Date).Subtract($InstallStart).Seconds) seconds."
Remove-Item "$env:TEMP\DRMMSetup.exe" -Force