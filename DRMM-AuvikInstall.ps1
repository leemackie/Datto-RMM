
<#
.SYNOPSIS
Install the Auvik agent onto a device
Requires 3 variables:
- Tenant URL fom Auvik - tenantURL
- User email address - userEmail
- User Auvik API Key - apiKey

.NOTES
Version 0.1 -
First revision
#>

# Set TLS 1.2 to be used in Powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Download Auvik Service to %temp%

Write-Output "-- Downloading setup to $env:Temp"
Invoke-WebRequest -Uri "https://apt.my.auvik.com/native-binaries/latest-release/MinGW-x86_64/AuvikService.exe" -OutFile "$env:Temp\AuvikService.exe"

# Execute the intallation
if (Get-Item $env:Temp\AuvikService.exe) {
    & $env:Temp\AuvikService -install -dir c:\auvik -tenant $env:tenantURL -user $env:userEmail -password $env:apiKey -noprompt
} else {
    Write-Host "FAILED: Auvik Service has not downloaded - review script output and try again."
    Exit 1
}

Start-Sleep -Seconds 30

if (!(Get-Service AuvikAgent -EA SilentlyContinue) -or !(Get-Service AuvikWatchdog -EA SilentlyContinue)) {
    Write-Host "FAILED: Installation has failed as Auvik services not found - review script output and try again."
    Exit 1
}

Write-Host "OK: Installation has completed and Auvik services are detected"