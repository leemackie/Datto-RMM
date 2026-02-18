<#
DRMM-OutlookMigrationMonitor.ps1

This component will look at all user registry hives for the registry key that controls "New Outlook" migration.
Script will exit if key is not found
Took a large portion of the User registry operations from https://www.pdq.com/blog/modifying-the-registry-users-powershell/ - thanks matey.

Written by Lee Mackie - 5G Networks
Version 1.0 - Initial release
#>

function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "ALERT=$message"
    write-host '<-End Result->'
}

function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

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
}

Get-HKEYUsers

Foreach ($item in $ProfileList) {
    Write-Host "`nProcessing $($item.Username)"
    If ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($item.SID) $($item.UserHive) | Out-Null
    }

    $regKey = Get-ItemProperty registry::HKEY_USERS\$($item.SID)\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General -Name DoNewOutlookAutoMigration -ErrorAction SilentlyContinue

    if ($regKey) {
        #$regKey
        Write-Host "DoNewOutlookAutoMigration registry key set on user $($u.Username)"
    } else {
        Write-Host "DoNewOutlookAutoMigration registry key not set on user $($u.Username)"
        $regValueMissing = $true
    }

     # Unload ntuser.dat
     IF ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}

if ($regValueMissing -eq $true) {
    Write-DRMMAlert "Outlook registry key missing @ $(Get-Date -Format "dd/MM/yyyy HH:mm") "
    Exit 1
} else {
    Write-DRMMStatus "Outlook registry key set on all profiles"
}