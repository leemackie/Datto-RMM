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

$varRegPath = "HKLM:\SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences"
$varAlert = $false
$varDiag = @()

# Have to set it at the script level as the Get-ItemPropertyValue cmdlet does not respect -ErrorAction configuration properly
$ErrorActionPreference="SilentlyContinue"

if ($(Get-ItemPropertyValue -Path "$varRegPath\CFG\" -Name "LockSettings") -ne 1) {
    $varAlert = $true
    $varDiag += "LockSettings not enabled"
}

if ($(Get-ItemPropertyValue -Path "$varRegPath\Settings\Schedule" -Name "ScheduleMode") -ne "ManualUpdates") {
    $varAlert = $true
    $varDiag += "ScheduleMode not set to ManualUpdates"
}

if ($(Get-ItemPropertyValue -Path "$varRegPath\Settings\General" -Name "ExcludeUpdatesFromLastNDays") -ne $ENV:usrDays) {
    $varAlert = $true
    $varDiag += "ExcludeUpdatesFromLastNDays not set to $ENV:usrDays"
}

if ($varAlert) {
    $strDiag = $varDiag -join ", "
    Write-DRMMAlert "BAD: Dell Command Update misconfigured: $strDiag."
    Exit 1
}

Write-DRMMStatus "OK: Dell Command Update configuration set correctly"