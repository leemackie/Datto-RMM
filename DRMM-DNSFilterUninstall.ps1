# DNSFilter Agent uninstallation script
# Written by Lee Mackie - 5G Networks
# Version 1.1: Updated uninstallation commands
# Based off https://help.dnsfilter.com/hc/en-us/community/posts/33824571207955-Migrating-Roaming-Clients-between-organizations-in-DNSFilter

function Uninstall-App {
    Write-Output "Uninstalling $($args[0])"
    foreach($obj in Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall") {
        $dname = $obj.GetValue("DisplayName")
        if ($dname -contains $args[0]) {
            $uninstString = $obj.GetValue("UninstallString")
            foreach ($line in $uninstString) {
                $found = $line -match '(\{.+\}).*'
                If ($found) {
                    $appid = $matches[1]
                    Write-Output $appid
                    Write-Host "Found $($args[0]) - initiating uninstallation command"
                    start-process "msiexec.exe" -arg "/X $appid /qb" -Wait
                }ud
            }
        }
    }
}


# Remove DNSFilter
Write-Host "Attempting uninstallation..."
Uninstall-App "DNSFilter Agent"
Uninstall-App "DNS Agent"

Start-Sleep 10

# Remove registry keys
Write-Host "Removing Registry Keys..."
Remove-Item -Path "HKLM:\Software\DNSFilter" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\DNSAgent" -Recurse -ErrorAction SilentlyContinue

# Remove file paths
Write-Host "Removing remaining files and folders"
Remove-Item "C:\Program Files\DNSFilter Agent\" -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files\DNS Agent\" -Recurse -ErrorAction SilentlyContinue

Write-Host "---- Script completed, DNSFilter software should have been removed."