<#
.SYNOPSIS
Datto RMM component to remove aged profiles from Windows machines, based on user-defined parmaters.
Written by Lee Mackie - 5G Networks, with assistance from Jim Anderson - Acture Solutions

.NOTES
Type: Script
Variable: usrDays [String]
Variable: usrDelete [Boolean]

Based of Powershell script by Microsoft:
https://learn.microsoft.com/en-us/troubleshoot/windows-server/support-tools/scripts-retrieve-profile-age-delete-aged-copies

.HISTORY
Version 1.0 - Initial release
Version 1.1 - Added list of Excluded profiles, moved from WMI to CIM, included output of folder size, notified on skipped profiles and
              cleaned up some scripting to be more efficient. Enhanced output formatting also.
              > Thanks to Jim Anderson - Acture Solutions for the input and suggestions for improvements.
#>

Function ConvertToDate{
    param(
        [uint32]$lowpart,
        [uint32]$highpart
    )

    $ft64 = ( [UInt64]$highpart -shl 32) -bor $lowpart
    [datetime]::FromFileTime( $ft64 )
}

# Define variables and parameters for use in the script
$Days = $ENV:usrDays
[string]$ComputerName = $env:computername
if ($ENV:usrDelete -eq "True") { [switch]$Delete = $true } else { [switch]$Delete = $false } # Because Datto doens't pass true boolean values
# Excluded profiles
$excludeProfiles = @(
    'C:\Users\Administrator',
    'C:\Users\Default',
    'C:\Users\Public',
    'C:\Users\LocalService',
    'C:\Users\NetworkService',
    'C:\Users\SystemProfile',
    'C:\Users\DefaultAppPool',
    'C:\Users\All Users',
    'C:\Users\defaultuser',
    'C:\Users\defaultuser0',
    'C:\Users\WsiAccount',
    'C:\Users\.NET v4.5',
    'C:\Users\.NET v4.5 Classic'
)

Write-Host "-- Parameters for deletion:"
Write-Host "   - Target Computer: $ComputerName"
Write-Host "   - Days not used: $Days"
Write-Host "   - Delete: $Delete"

if ($days -lt 30) {
    Write-Host "!! ERROR: Deleting profiles that have not been used for less than 30 days is too risky. Please use a value of 30 days or more."
    Exit 1
}

#Get Unloaded profiles
$unloadedProfiles = Get-CimInstance -Class Win32_UserProfile -Filter "Loaded = 'False' and Special = 'False'" -ErrorAction Stop

if (-not ($null -eq $UnloadedProfiles)) {
    #Match Profiles to delete
    Write-Host "-- Matching profiles on system"
    $UnloadedProfiles | ForEach-Object {
        $CurUserSid = $_.sid
        $CurUserObj = [wmi]"\\$ComputerName\root\cimv2:Win32_SID.SID='$CurUserSid'"
        $CurUserDomain = $CurUserObj.ReferencedDomainName
        if( $CurUserDomain -eq "" ) { $CurUserDomain = "<Unresolved>" }
        $CurUserName = $CurUserObj.AccountName
        if( $CurUserName -eq "" ) { $CurUserName = "<Unresolved>" }
        $CurUser = "$CurUserDomain\$CurUserName"

        #Use registry keys
        $profileListSidKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$CurUserSid"
        $SaveErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"

        $localProfileUnloadTimeLow = 0
        $localProfileUnloadTimeHigh = 0

        $localProfileUnloadTimeLow = Get-ItemPropertyValue -Path $profileListSidKey -Name LocalProfileUnLoadTimeLow
        $localProfileUnloadTimeHigh = Get-ItemPropertyValue -Path $profileListSidKey -Name LocalProfileUnLoadTimeHigh
        if ($localProfileUnloadTimeLow -or $localProfileUnloadTimeHigh) {
            $lastUseTime = ConvertToDate $localProfileUnloadTimeLow $localProfileUnloadTimeHigh
        } elseif ($_.LastUseTime) {
            $host.ui.WriteErrorLine("-- We did not find last use information in the registry for profile $CurUser. Falling back to the CIM value.")
            $lastUseTime = $_.LastUseTime
        }
        $ErrorActionPreference = $SaveErrorActionPreference

        if ($lastUseTime) {
            $CurUserDaysOld = ((Get-Date) - $lastUseTime).days
        } else {
            $host.ui.WriteErrorLine("-- We did not find any last use information, so we defaulted to an age of 99999 days for profile $CurUser. This means the profile will be deleted if it is not in the excluded list.")
            $CurUserDaysOld = 99999
        }

        if ($CurUserDaysOld -ge $Days -and -not ($excludeProfiles -contains $_.localpath)) {
            $directorySize = (Get-Childitem "\\?\$($_.localpath)" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            Write-Host "-- Found: $CurUser - Age:" $CurUserDaysOld "-" $_.Sid "- Path:" $_.localpath "- Size: $([Math]::Round($directorySize/1MB, 2)) MB"
            if($Delete) {
                Write-Host "   Deleting profile"
                try {
                    Remove-CimInstance -InputObject $_
                    write-host "-- Successfully deleted profile."
                } catch {
                    write-host "?? WARNING: Error occured deleting profile.  It may have been only partially deleted."
                    Write-Host "   Error details: $_"
                }
            } else {
                Write-Host "   Dry run: No action taken."
            }
        } else {
            Write-Host "-- Skipped: $CurUser - Age: $CurUserDaysOld days - Path: $($_.localpath)"
        }
    }
    Write-Host ""
    Write-Host "-- Profile cleanup execution complete. Review the output above for details."
} else {
    Write-Host "?? WARNING: No unloaded profiles found on system that match parameters."
}