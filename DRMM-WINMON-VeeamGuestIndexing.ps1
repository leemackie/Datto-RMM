<#
.SYNOPSIS
Using Datto RMM, check the Veeam Backup and Replication guest file indexing status for all backup and agent backup jobs.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Monitor
Version 1.0 - Initial release
Version 1.1 - Updated to use Veeam.Backup.PowerShell module via code, standardised output and removed scripts ability to
auto-fix which will be broken out into a script component.
Version 1.2 - Refactored to support Veeam B&R v13 and PowerShell 7, cleaned up some of the logic and calls
Version 1.2.1 - Cleaned up some redudnant code and refactored some output
#>

$script = @'

Import-Module "Veeam.Backup.PowerShell" -NoClobber -DisableNameChecking

function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}
function Write-DRMMDiagnostic ($message) {
    write-host '<-Start Diagnostic->'
    write-host $message
    write-host '<-End Diagnostic->'
}

# some counters for the status output
$u = 0
$i = 0

# Create array for misconfigured jobs
$misconfigured = @()

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
        if (($job.JobType -eq "Backup") -and $job.VssOptions.AreWinCredsSet -eq $false -and $job.IsScheduleEnabled -eq $true) {
            # If backup job and credentials are not configured
            $misconfigured += "$($job.Name)`n"
        } elseif (($job.JobType -eq "Backup") -and $job.VssOptions.WinGuestFSIndexingOptions.Enabled -eq $false -and $job.IsScheduleEnabled -eq $true) {
            # If backup job, Guest indexing is disabled and guest credentials are configured
            $u++
        }  else {
            # Else everything is setup as expected or job is disabled
            $i++
        }
    }

    # Grab all Agent backup jobs, but only if they are managed by the Backup server
    $computerJobs = Get-VBRComputerBackupJob -Mode ManagedByBackupServer

    # Iterate through them
    foreach ($cJob in $computerJobs) {
        if ($cjob.IndexingEnabled -eq $false -and $cJob.IsScheduleEnabled -eq $true) {
            # If indexing is disabled in job properties
            $misconfigured += "$($job.Name)`n"
        } else {
            # else everything configure correctly or job is disabled
            $i++
        }
    }

    # Generate DRMM alert for misconfigured job
    if ($misconfigured.Count -ne 0) {
        Write-DRMMAlert "BAD: $($misconfigured.Count) misconfigured jobs found"
        Write-DRMMDiagnostic "Misconfigured jobs found `nLikely credentials not configured in job properties: `n$misconfigured `nThese may require manual resolution"
        Exit 1
    }

    # Final count of all found backup jobs for a nice output to console
    $count = $vbrJobs.Count + $computerJobs.Count

    if ($count -ne 0) {
        Write-DRMMStatus "OK: $count jobs configured correctly | $i with indexing enabled, $u with indexing disabled"
    } else {
        Write-DRMMStatus "OK: No backup jobs found"
    }

} catch {
    write-DRMMAlert "BAD: $(Get-Date -Format HH:mm) | SCRIPT FAILED"
    Write-DRMMDiagnostic  "Script failed - please investigate VBR and PowerShell on server.`n $($_.ScriptStackTrace)`n$($_.Exception)"
    Exit 1
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