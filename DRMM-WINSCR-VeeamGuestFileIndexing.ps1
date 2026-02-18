<#
.SYNOPSIS
Using Datto RMM, enable Guest File System Indexing for all Veeam Backup, Backup Agent and Replication jobs that require it.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Version 1.0 - Initial release
Version 1.1 - Refactored to support Veeam B&R v13 and PowerShell 7, cleaned up some of the logic and calls

With version 1.1, please ensure that the formatting of the $script variable is carefully preserved, as we are parsing it out to PowerShell 7 via StdIn, the
formatting of the script block is important.
More info: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_Pwsh?view=powershell-7.4
#>

$script = @'

Import-Module "Veeam.Backup.PowerShell" -NoClobber -DisableNameChecking

$misconfigured = @() # Create array for misconfigured jobs
$configured = @() # Create array for configured jobs

try {
    Get-VBRCommand Connect-VBRServer |
    ForEach-Object {
        if ($_.Version -lt [version]"13.0") {
            Write-Host "- Veeam PowerShell module version $($_.Version) detected - using V12 and below connection method."
            Connect-VBRServer -Server localhost
        } else {
            Write-Host "- Veeam PowerShell module version $($_.Version) detected - using V13 and above connection method."
            Connect-VBRServer -Server localhost -ForceAcceptTlsCertificate
        }
    }

    # Grab all backup jobs and iterate through them
    foreach ($job in $(Get-VBRJob)) {
        try {
            if (($job.JobType -eq "Backup") -and $job.VssOptions.AreWinCredsSet -eq $false -and $job.IsScheduleEnabled -eq $true) {
                # If backup job and credentials are not configured
                $misconfigured += "$($job.Name)`n"
            } elseif (($job.JobType -eq "Backup") -and $job.VssOptions.WinGuestFSIndexingOptions.Enabled -eq $false -and $job.IsScheduleEnabled -eq $true) {
                # If backup job, Guest indexing is disabled and guest credentials are configured
                $configured += "$($job.Name)`n"
                Enable-VBRJobGuestFSIndexing -Job $job
            } # Else everything is setup as expected or job is disabled
        } catch {
            Write-Host "!! ERROR: Failed to update $($job.Name) to enable guest file indexing. Failure below:"
            Write-Host $_
            Exit 1
        }
    }

    # Grab all Agent backup jobs, but only if they are managed by the Backup server and iterate through them
    foreach ($cJob in $(Get-VBRComputerBackupJob -Mode ManagedByBackupServer)) {
        try {
            if ($cjob.IndexingEnabled -eq $false -and $cJob.IsScheduleEnabled -eq $true) {
                # If indexing is disabled in job properties
                Enable-VBRJobGuestFSIndexing -Job $cJob
                $configured += "$($cJob.Name)`n"
            } # Else everything configure correctly or job is disabled
        } catch {
            Write-Host "!! ERRROR: Failed to update $($cJob.Name) to enable guest file indexing. Failure below:"
            Write-Host $_
            Exit 1
        }
    }
} catch {
    Write-Host "!! ERROR: Script failed - please investigate VBR and PowerShell on server."
    Write-Host  $_
    Exit 1
}

# Output results
if ($configured.Count -gt 0) {
    Write-Host "- Following jobs have been updated to enable Guest File System Indexing:`n-- $($configured -join "`n")"
} else {
    Write-Host "- No jobs required updating for Guest File System Indexing."
}

'@

# A rather annoying method to determine which version of PowerShell and Veeam module is installed, until Datto RMM supports PowerShell 7 natively
Get-Module -ListAvailable -Name "Veeam.Backup.PowerShell" | ForEach-Object {
    if ($_.Version -lt [version]"13.0" -and $_.Version -ne [version]"0.0") {
        Write-Host "- Veeam PowerShell module version $($_.Version) detected - using standard PowerShell."
        $script | Invoke-Expression
    } elseif ($_.Version -ge [version]"13.0" -or $_.Version -eq [version]"0.0") {
        if (-not $(Get-Command pwsh -ErrorAction SilentlyContinue)) {
            Write-Host "!! ERROR: PowerShell 7 is not installed on this system. This script requires PowerShell 7 to run."
            Exit 1
        }
        Write-Host "- Veeam B&R v13 detected - using PowerShell 7."
        $script | pwsh -Command -

    } else {
        Write-Host "!! ERROR: Veeam PowerShell module not found - please ensure Veeam Backup & Replication is installed on this system."
        Exit 1
    }
}