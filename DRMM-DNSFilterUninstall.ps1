# DNSFilter Agent uninstallation script
# Written by Lee Mackie - 5G Networks
# Version 1.0: Initial release

$Prod = Get-WMIObject -Classname Win32_Product | Where-Object {
    ($_.Name -Match 'DNS Agent' -or $_.Name -Match 'DNSFilter Agent')
}

if ($Prod) {
    Write-Host "# DNSFilter agent found - attempting uninstall"
    foreach ($p in $prod) {
        $result = $p.Uninstall()
        if ($result.ReturnValue -eq 0) {
            Write-Host "# $($p.Name) successfully uninstalled"
        } else {
            Write-Host "!! $($p.Name) failed to remove"
            Write-Host "!! Result code: $($result.ReturnValue)"
            Exit 1
        }
    }
} else {
    Write-Host "! DNSFilter agent not found"
}