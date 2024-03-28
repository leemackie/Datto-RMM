### DRMM-WinFirewall
### Disable or enable Windows firewall entirely
### v0.1 - First build
### Created by Lee Mackie - leem@5gn.com.au

$fwStatus = $ENV:Status

Write-Host "-- Current firewall mode:"
Write-Host "Public:" $(Get-NetFirewallProfile -Name Public).Enabled
Write-Host "Private:" $(Get-NetFirewallProfile -Name Private).Enabled
Write-Host "Domain:" $(Get-NetFirewallProfile -Name Domain).Enabled

Write-Host "-- Setting all firewall modes to $fwStatus"
try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled $fwStatus
} catch {
    Write-host "-- An error was encountered trying to set the firewall mode."
    Write-Host "Error: $_"
}

Write-Host "-- New firewall mode:"
Write-Host "Public: " $(Get-NetFirewallProfile -Name Public).Enabled
Write-Host "Private: " $(Get-NetFirewallProfile -Name Private).Enabled
Write-Host "Domain: " $(Get-NetFirewallProfile -Name Domain).Enabled

if ($(Get-NetFirewallProfile).Enabled -eq $fwstatus) {
    Write-Host "-- Script ran successfully"
} else {
    Write-Host "-- Failed to set firewall mode"
    Exit 1
}