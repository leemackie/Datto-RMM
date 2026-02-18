<#
.SYNOPSIS
Datto RMM component to configure the Network UAC setting on Windows devices to allow local Administartor accounts to be used for network
management without requiring a domain join.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script

.HISTORY
Version 1.0 - Initial release
#>

$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$name = 'LocalAccountTokenFilterPolicy'
$newValue = $ENV:varEnabled

# Read current value (or absence)
try {
    $current = Get-ItemProperty -Path $regPath -Name $name -ErrorAction Stop | Select-Object -ExpandProperty $name
    Write-Host "- Current value: $current"
} catch {
    $current = $null
    Write-Host "- Current value: Not present (Enabled by default if not present)"
}

# If already configured, report and exit
if ($null -ne $current -and $current -eq $newValue) {
    Write-Host "- LocalAccountTokenFilterPolicy is already configured as $newValue"
    exit
}

# Ensure key exists and set the DWORD
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

New-ItemProperty -Path $regPath -Name $name -Value $newValue -PropertyType DWord -Force | Out-Null
Write-Host "- SUCCESS: Set LocalAccountTokenFilterPolicy to $newValue"