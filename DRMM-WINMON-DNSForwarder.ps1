<#
.SYNOPSIS
Using Datto RMM, audit local DNS forwarders on DNS server and look for misconfiguration
Written by Lee Mackie - 5G Networks

.NOTES
Type: Monitor
Version 1.0 - Initial release
Variable: usrDnsForwaders [String]
#>

function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "ALERT=$message"
    write-host '<-End Result->'
}

function write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "$message"
    write-host '<-End Result->'
}
function write-DRMMDiagnostic ($message) {
    write-host '<-Start Diagnostic->'
    write-host $message
    write-host '<-End Diagnostic->'
}

$usrDnsForwarders = $env:usrDnsForwarders -split ","
if ($usrDnsForwarders -match "[^\d\,\.]") {
    Write-DRMMAlert "BAD: Script has malformed input!"
    Write-DRMMDiagnostic "Script has malformed input in the variable fields from RMM - $usrDnsForwarders`
Should only contain IP addresses and comma seperation"
    Exit 1
}

try {
    $svrDnsForwarders = (Get-DnsServerForwarder).IPAddress
} catch {
    write-DRMMAlert "BAD: Failed to grab DNS forwarders"
    write-DRMMDiagnostic "Is this definitely a Windows DNS server?"
}

foreach ($address in $svrDnsForwarders) {
    Write-Output "Checking DNS Forwarder: $address"
    if ($usrDnsForwarders -notcontains $address) {
    Write-DRMMAlert "BAD: DNS misconfiguration found!"
    Write-DRMMDiagnostic "Expected DNS Forwarders: $usrDNSForwarders`
Found DNS Forwarders: $svrDnsForwarders"
    Exit 1
    }
    Write-Output "DNS Forwarder $address is configured correctly"
}

write-DRMMStatus "OK: DNS Forwarders configured correctly"