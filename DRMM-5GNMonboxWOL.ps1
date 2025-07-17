function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "$message"
    write-host '<-End Result->'
}

$output = @()
try {
    $currentSetting1 = Get-NetAdapter -Name Ethernet* | Get-NetAdapterAdvancedProperty -RegistryKeyword "*ModernStandbyWoLMagicPacket"
    $currentSetting2 = Get-NetAdapter -Name Ethernet* | Get-NetAdapterAdvancedProperty -RegistryKeyword "*WakeOnMagicPacket"
    $currentSetting3 = Get-NetAdapter -Name Ethernet* | Get-NetAdapterAdvancedProperty -RegistryKeyword "*WakeOnPattern"
    $currentSetting4 = Get-NetAdapter -Name Ethernet* | Get-NetAdapterAdvancedProperty -RegistryKeyword "*S5WakeOnLan"
} catch {
    Write-DRMMStatus "WARNING: Device does not support WOL Settings."
    Exit 0
}

if ($currentSetting1 -and $currentSetting1.RegistryValue -eq "0") {
    Get-NetAdapter -Name Ethernet*  | Set-NetAdapterAdvancedProperty -RegistryKeyword "*ModernStandbyWoLMagicPacket" -RegistryValue 1
    $output += "Modern Standby WOL Enabled"
}

if ($currentSetting2 -and $currentSetting2.RegistryValue -eq "0") {
    Get-NetAdapter -Name Ethernet* | Set-NetAdapterAdvancedProperty -RegistryKeyword "*WakeOnMagicPacket" -RegistryValue 1
    $output += "Standard WOL Enabled"
}

if ($currentSetting3 -and $currentSetting3.RegistryValue -eq "0") {
    Get-NetAdapter -Name Ethernet*  | Set-NetAdapterAdvancedProperty -RegistryKeyword "*WakeOnPattern" -RegistryValue 1
    $output += "WOL Pattern Enabled"
}

if ($currentSetting4 -and $currentSetting4.RegistryValue -eq "0") {
    Get-NetAdapter -Name Ethernet* | Set-NetAdapterAdvancedProperty -RegistryKeyword "*S5WakeOnLan" -RegistryValue 1
    $output += "Shutdown WOL Enabled"
}


if ($output) {
    Write-DRMMStatus $($output -join ", ")
} else {
    Write-DRMMStatus "OK: WoL settings correct"
}