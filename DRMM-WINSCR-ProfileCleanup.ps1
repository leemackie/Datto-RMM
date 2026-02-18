<#
.SYNOPSIS
Datto RMM component to remove aged profiles from Windows machines, based on user-defined parmaters.
Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Variable: usrDays [String]
Variable: usrDelete [Boolean]

Based of Powershell script by Microsoft:
https://learn.microsoft.com/en-us/troubleshoot/windows-server/support-tools/scripts-retrieve-profile-age-delete-aged-copies

.HISTORY
Version 1.0 - Initial release
#>

# Parameters definition
$Days = $ENV:usrDays
[string]$ComputerName = $env:computername
if ($ENV:usrDelete -eq "True") { [switch]$Delete = $true } else { [switch]$Delete = $false } # Because Datto doens't pass true boolean values

Function ConvertToDate{
    param(
        [uint32]$lowpart,
        [uint32]$highpart
    )

    $ft64 = ( [UInt64]$highpart -shl 32) -bor $lowpart
    [datetime]::FromFileTime( $ft64 )
}

Write-Host "-- Parameters for deletion:"
Write-Host "[ Target Computer: $ComputerName ]"
Write-Host "[ Days not used: $Days ]"
Write-Host "[ Delete: $Delete ]"

if ($days -lt 30) {
    Write-Host "!! ERROR: Deleting profiles that have not been used for less than 30 days is too risky. Please use a value of 30 days or more."
    Exit 1
}

#Get Unloaded profiles
$UnloadedProfiles = Get-WmiObject win32_userprofile -filter "Loaded = 'False' and Special = 'False'" -ErrorAction stop

if( -not ($null -eq $UnloadedProfiles) ) {
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
        $profilelistsidkey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$CurUserSid"
        $SaveErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"

        $localprofileunloadtimelow = 0
        $localprofileunloadtimehigh = 0

        $localprofileunloadtimelow = Get-ItemPropertyValue -Path $profilelistsidkey -Name LocalProfileUnLoadTimeLow
        $localprofileunloadtimehigh = Get-ItemPropertyValue -Path $profilelistsidkey -Name LocalProfileUnLoadTimeHigh

        $lastusetime = ConvertToDate $localprofileunloadtimelow $localprofileunloadtimehigh
        $ErrorActionPreference = $SaveErrorActionPreference

        if( $lastusetime ) {
            $CurUserDaysOld = ((Get-Date) - $lastusetime).days
        } else {
            $CurUserDaysOld = 99999
        }

        if ($CurUserDaysOld -ge $Days) {
            Write-Host " -- Age:" $CurUserDaysOld "-" $CurUser "-" $_.Sid "- Path:" $_.localpath
            if($Delete) {
                Write-Host "-- Deleting profile"
                try {
                    $_.Delete()
                    write-host "-- Successfully deleted profile."
                } catch {
                    write-host "?? WARNING: Error occured deleting profile.  It may have been only partially deleted."
                }
            }else {
                Write-Host "-- No action taken."
            }
        }
    }
    Write-Host "-- Profile cleanup complete. Review the output above for details."
} else {
    Write-Host "?? WARNING: No unloaded profiles found on system that match parameters."
}