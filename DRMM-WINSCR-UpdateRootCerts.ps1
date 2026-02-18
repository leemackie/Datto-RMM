<#
.SYNOPSIS
Using Datto RMM, download and install the latest Windows Root Certificates from Windows Update.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Version 1.0 - Initial release
#>

Write-Host "- Downloading latest Root Certificates from Windows Update - saving to $ENV:TEMP"
$output = CertUtil.exe -generateSSTFromWU $env:TEMP\Rootstore.sst
# $output set to stop the output of CertUtil being shown in the RMM job log

Write-Host "- Importing into Local Machine Trusted Root (Root) certificate store"
Import-Certificate -FilePath $ENV:TEMP\rootstore.sst -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null

Remove-Item -LiteralPath $env:TEMP\Rootstore.sst -ErrorAction SilentlyContinue
Write-Host "- Installation complete."

if ($ENV:AgentRestart -eq "True") {
    Write-Host "- Queuing restart of Datto RMM agent for 60 seconds time."
    Start-Process powershell -ArgumentList "-NoProfile -Command `"Start-Sleep -Seconds 60; Restart-Service -Name 'CagService' -Force`"" -WindowStyle Hidden
}