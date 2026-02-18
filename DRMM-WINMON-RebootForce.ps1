<#
.SYNOPSIS
Forced reboot monitor script for Datto RMM, to enable the triggering of forced reboots based on custom criteria.

Written by Lee Mackie - 5G Networks

.NOTES
If reboot reminder count is set to 0 in the RMM site variable, then the script will never trigger (infinite reminders, no forced reboot).

Variable varRTimeSched is optional - if set, the script will only force a reboot if the current time is within the specified time range (HH:mm-HH:mm).
Can traverse midnight (e.g. 22:00-06:00).

.HISTORY
Version 1.0 - Initial release
Version 1.1 - Fixed logic to properly count reboot reminders before forcing reboot.
Version 1.2 - Added optional reboot time schedule check before forcing reboot, added alert output variable.
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

# Set required environment variables
$varRRemCount = $ENV:usrRebootReminderCount
$varRRemSched = $ENV:usrRebootReminderSched
$varRTimeSched = $ENV:usrRebootTimeSched
$varRRequired = $ENV:UDF_12
$varRegPath = "HKLM:\SOFTWARE\CentraStage\"
$varRegRReminder = "5GNRebootReminder"
$varRegRReminderCount = "5GNRebootReminderCount"

if (!$varRRemCount -or !$varRRemSched) {
    Write-DRMMStatus "ERROR: Required RMM site variables not set - cannot proceed."
    Exit 0
}

if ($varRRequired -notlike "(RREQ)*") {
    Write-DRMMStatus "OK: Device does not require a reboot"
    Remove-ItemProperty -Path $varRegPath -Name $varRegRReminder -ErrorAction Continue -Force
    Remove-ItemProperty -Path $varRegPath -Name $varRegRReminderCount -ErrorAction Continue -Force
    Exit 0
}

if ($varRRemCount -eq 0) {
    Write-DRMMStatus "OK: Reboot reminder count set to 0, never force reboot."
    Exit 0
}

# Validate and parse Reboot Reminder Schedule string from component
if ($varRRemSched -match '^(\d+)([hd])$') {
    $value = [int]$matches[1]
    $unit = $matches[2]

    switch ($unit) {
        'H' { $varTimeout = New-Timespan -Hours $value }
        'D' { $varTimeout = New-Timespan -Days $value }
    }
} else {
    Write-DRMMStatus "BAD: Invalid format used in the site variable - review and correct."
    Exit 0
}

# Retrieve registry values if there has been a prior reboot reminder
try {
    [datetime]$regTimeValue = Get-ItemPropertyValue -Path $varRegPath -Name $varRegRReminder -ErrorAction Stop
    try { [int]$regCounterValue = Get-ItemPropertyValue -Path $varRegPath -Name $varRegRReminderCount -ErrorAction Stop } catch { $regCounterValue = 0 }

    # Calculate time difference
    $currentDate = Get-Date
    $timeDifference = $currentDate - $regTimeValue
} catch {}

if ($timeDifference -ge $varTimeout -and $regCounterValue -ge $varRRemCount) {
    if ($varRTimeSched) {
        # Check if current time is within the allowed reboot time schedule
        $currentTime = Get-Date
        $startTime = [datetime]::ParseExact($varRTimeSched.Split("-")[0], "HH:mm", $null)
        $endTime = [datetime]::ParseExact($varRTimeSched.Split("-")[1], "HH:mm", $null)

        if ($endTime -lt $startTime) {
            # Time range crosses midnight
            $endTime = $endTime.AddDays(1)
        }

        if ($currentTime.TimeOfDay -lt $startTime.TimeOfDay -or $currentTime.TimeOfDay -gt $endTime.TimeOfDay) {
            Write-DRMMStatus "OK: Reboot required, not within allowed reboot schedule. Current Time: $($currentTime.ToString("HH:mm")) | Allowed: $varRTimeSched"
            Exit 0
        } else {
            $alertOut = "REBOOT: Maximum reboot reminders reached ($regCounterValue/$varRRemCount) and within allowed reboot time schedule | Current Time: $($currentTime.ToString("HH:mm"))/Allowed: $varRTimeSched"
        }
    }
    if (!$alertOut) {
        $alertOut = "REBOOT: Maximum reboot reminders reached ($regCounterValue/$varRRemCount) - performing reboot response."
    }

    Write-DRMMAlert $alertOut
    #Write-DRMMAlert "REBOOT: Maximum reboot reminders reached ($regCounterValue/$varRRemCount) - performing reboot response."
    Exit 1
}

Write-DRMMStatus "OK: Not required. Timeout: $($timeDifference.Days)D:$($timeDifference.Hours)H/$($varTimeout.Days)D:$($varTimeout.Hours)H | Reminder: $regCounterValue of $varRRemCount"