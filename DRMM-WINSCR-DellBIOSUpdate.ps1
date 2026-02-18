<#
.SYNOPSIS
Dell BIOS update script for use with Datto RMM, designed to be used as a component for Dell Pro PC 14250 and 16250 models.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script

.HISTORY
- Version 1.0 - First release
#>

$filename = "Dell_Pro_PC14250_PC16250_1.12.0.exe"
$log = "C:\ProgramData\CentraStage\Temp\DellBiosUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Write-Host "-- Attempting to flash latest BIOS update, we will not force reboot at completion."
Write-Host "-- Logging flash output to $log and will also be displayed in StdErr for RMM visibility."

# Run the update, silently (/s), disabling bitlocker (/bls) and logging to the specified log file (/l=)
$exec = Start-Process $pwd/$filename -ArgumentList "/s /bls /l=$log" -Wait -Passthru

# Write the log output to StdErr for RMM visibility
$host.ui.WriteErrorLine("$(Get-Content $log -Raw)")

# Check if the exit code is 0 (success) or not and output the appropriate message
switch ($exec.ExitCode) {
    0 { Write-Host "-- SUCCESS: BIOS update process completed successfully, please review the StdErr/log for details." }
    2 { Write-Host "-- SUCCESS: BIOS update process completed with exit code 2 but requires reboot to complete. Reboot to complete the update locally."}
    10 { Write-Host "?? WARNING: BIOS update process completed with exit code 10 - is this a Dell Pro PC 14250 or 16250? Please review the StdErr/log for details." }
    Default { Write-Host "!! ERROR:  BIOS update process failed with exit code $($exec.ExitCode), please review the StdErr/log for details."; Exit 1 }
}