$Platform = "syrah"
$SiteID = "16a4c08f-38c1-4c2e-b1dc-77b18a1f8c21"

<#
Datto RMM Agent deploy by MS Azure Intune
Designed and written by Jon North, Datto, March 2020
Download the Agent installer, run it, wait for it to finish, delete it
#>

# First check if Agent is installed and instantly exit if so
If (Get-Service CagService -ErrorAction SilentlyContinue) {
    Write-Output "Datto RMM Agent already installed on this device"
    exit
}

# Download the Agent
$AgentURL = "https://$Platform.rmm.datto.com/download-agent/windows/$SiteID"
$DownloadStart = Get-Date
Write-Output "Starting Agent download at $(Get-Date -Format HH:mm) from $AgentURL"

try {
    [Net.ServicePointManager]::SecurityProtocol=[Enum]::ToObject([Net.SecurityProtocolType],3072)
} catch {
    Write-Output "Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script."
    exit 1
}
try {
    (New-Object System.Net.WebClient).DownloadFile($AgentURL, "$env:TEMP\DRMMSetup.exe")
} catch {
    $host.ui.WriteErrorLine("Agent installer download failed. Exit message:`r`n$_")
    exit 1
}

Write-Output "Agent download completed in $((Get-Date).Subtract($DownloadStart).Seconds) seconds`r`n`r`n"

# Install the Agent
$InstallStart = Get-Date
Write-Output "Starting Agent install to target site at $(Get-Date -Format HH:mm)..."
& "$env:TEMP\DRMMSetup.exe" | Out-Null
Write-Output "Agent install completed at $(Get-Date -Format HH:mm) in $((Get-Date).Subtract($InstallStart).Seconds) seconds."
Remove-Item "$env:TEMP\DRMMSetup.exe" -Force
Exit