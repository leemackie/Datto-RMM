<#
.SYNOPSIS
Using Datto RMM, deploy the DNSFilter certificates to the Trusted Root CA store
Written by Lee Mackie - 5G Networks

.NOTES
Version 1.2 - Simplified installation code and added verbosity to script
#>

$url = @("https://app.dnsfilter.com/certs/DNSFilter.cer", "https://app.dnsfilter.com/certs/NetAlerts.cer")
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

foreach($u in $url) {
    try {
        Write-Host "-- Downloading $u"
        Invoke-WebRequest -Uri $u -OutFile "$env:TEMP\cert.cer"
        Write-Host "-- Importing certificate from $env:TEMP"
        Import-Certificate -FilePath $ENV:Temp\cert.cer -CertStoreLocation "Cert:\LocalMachine\Root"
        Remove-Item "$env:TEMP\cert.cer"
    } catch {
        Write-Host "!! Failure downloading or importing DNSFilter certificates."
        Write-Host $_
        Exit 1
    }
}

if (Test-Path "C:\Program Files\Mozilla Firefox\defaults\pref\") {
    Write-Host "-- Changing Firefox configuration to look at machine certificate store"
    Set-Content "C:\Program Files\Mozilla Firefox\defaults\pref\firefox-windows-truststore.js" "pref('security.enterprise_roots.enabled', true);"
}

Write-Host "-- Certificate successfully installed!"