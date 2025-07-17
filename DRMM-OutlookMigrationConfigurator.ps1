<#
DRMM-OutlookMigrationConfigurator.ps1

This component will take the input of the component, and set the "New Outlook" migration registry key.
Best teamed up with the monitor DRMM-OutlookMigrationMonitor
Took a large portion of the User registry operations from https://www.pdq.com/blog/modifying-the-registry-users-powershell/ - thanks matey.

Written by Lee Mackie - 5G Networks
Version 1.0 - Initial release
#>

function Get-HKEYUsers {
    # Regex pattern for SIDs
    $PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

    # Get Username, SID, and location of ntuser.dat for all users
    $global:ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} |
        Select  @{name="SID";expression={$_.PSChildName}},
                @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}},
                @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}

    # Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
    $global:LoadedHives = Get-ChildItem Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select @{name="SID";expression={$_.PSChildName}}

    # Get all users that are not currently logged
    $global:UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select @{name="SID";expression={$_.InputObject}}, UserHive, Username

    # Output users found
    Write-Host "Found the following users:"
    Write-Host $ProfileList.Username
}

Get-HKEYUsers

Foreach ($item in $ProfileList) {
    Write-Host "`nProcessing $($item.Username)"
    If ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($item.SID) $($item.UserHive) | Out-Null
    }

    try {
        reg add HKEY_USERS\$($item.SID)\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General\ /v DoNewOutlookAutoMigration /t REG_DWORD /d 0 /f
        #reg delete HKEY_USERS\$($item.SID)\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General\ /v DoNewOutlookAutoMigration
        Write-Host "Successfully set the registry key to $($env:policySetting) for $($item.Username) - SID: $($item.SID)"
    } catch {
        Write-Host "WARNING: Failed to set the registry key for $item.Username - SID: $($item.SID)"
    }

     # Unload ntuser.dat
     If ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}