<#
.SYNOPSIS
Using Datto RMM, check machine for installation of DNSFilter Roaming Agent.
Either alert or write status dependant on the status.
Written by Lee Mackie - 5G Networks

.NOTES
Version 0.2 - Simplified detection logic somewhat and cleaned up output. Added check for registered status.
#>
function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

function Get-DNSFilterStatus () {
    $Global:DNSFilterAgent = Get-Service -name "DNSFilter Agent" -ea SilentlyContinue
}

$Installed = Test-Path "HKLM:\Software\DNSFilter\Agent" -ea SilentlyContinue
if ($Installed -eq "true") {
    Write-Host "-- DNSFilter Roaming Client installed"
    Get-DNSFilterStatus

    if (!$DNSFilterAgent) {
        Write-DRMMAlert "ERROR: DNSFilter Roaming Client service missing."
        Exit 1
    }

    if ($DNSFilterAgent.Status -ne "Running") {
        Write-Host "-- DNSFilter Roaming Client service is NOT running"
        $DNSFilterAgent | Start-Service -ea SilentlyContinue
        Get-DNSFilterStatus
        if ($DNSFilterAgent.Status -eq "Stopped") {
            Write-Host "-- DNSFilter Roaming Client is NOT running and start request failed"
            Write-DRMMAlert "ERROR: DNSFilter Roaming Client service is NOT running. Attempted restart of service failed."
            Exit 1
        } elseif ($DNSFilterAgent.Status -eq "Started") {
            Write-Host "-- DNSFilter Roaming Client restarted successfully"
            Write-DRMMStatus "WARNING: DNSFilter Roaming Client restarted successfully and OK"
            Exit 0
        }
    }
} else {
    Write-Host "-- DNSFilter Roaming Client NOT installed"
    Write-DRMMAlert "ERROR: DNSFilter Roaming Client not installed"
    Exit 1
}

$registered = (Get-ItemProperty -Path HKLM:\Software\DNSFilter\Agent -ErrorAction SilentlyContinue).Registered
if ($registered -eq 0) {
    Write-Host "-- DNSfilter Roaming Client not detected as registered to DNSFilter console"
    Write-DRMMAlert "ERROR: DNSFilter Roaming Client not registered"
    Exit 1
}

Write-Host "-- DNSFilter Roaming Client service running"
Write-DRMMStatus "OK: DNSFilter Roaming Client running"