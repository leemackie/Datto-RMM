$varRegPath = "HKLM:\SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences"
Write-Host "Setting Dell Command Update settings in registry"

# Set the required registry keys to lock settings and set schedule to manual updates
try {
    if (!(Test-Path "$varRegPath\CFG")) { New-Item -Path "$varRegPath" -Name "CFG" | Out-Null }
    if (!(Test-Path "$varRegPath\Settings\Schedule")) { New-Item -Path "$varRegPath\Settings\" -Name "Schedule" | Out-Null }
    if (!(Test-Path "$varRegPath\Settings\General")) { New-Item -Path "$varRegPath\Settings\" -Name "General"  | Out-Null }

    Write-Host "-- Configuring settings lock"
    New-ItemProperty -Path "$varRegPath\CFG" -Name "LockSettings" -PropertyType DWORD -Value 1 -Force | Out-Null

    Write-Host "-- Disabling setup prompt"
    New-ItemProperty -Path "$varRegPath\CFG" -Name "ShowSetupPrompt" -PropertyType DWORD -Value 0 -Force | Out-Null

    Write-Host "-- Setting ScheduleMode to ManualUpdates"
    New-ItemProperty -Path "$varRegPath\Settings\Schedule" -Name "ScheduleMode" -PropertyType String -Value "ManualUpdates" -Force | Out-Null

    Write-Host "-- Configuring update exclusion time period of $ENV:usrDays days"
    New-ItemProperty -Path "$varRegPath\Settings\General" -Name "ExcludeUpdatesFromLastNDays" -PropertyType String -Value $ENV:usrDays -Force | Out-Null
} catch {
    Write-Host "!! Dell Command Update settings failed to apply - error output in stdErr" -ForegroundColor Red
    Write-Error $_
    #Exit 1
}

Write-Host "-- Dell Command Update settings applied successfully"
