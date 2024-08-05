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

# Import require Powershell module
# Veeam.Backup.PowerShell
if (-not(Get-Module -ListAvailable -Name "Veeam.Backup.PowerShell")) {
    if (Get-Item "C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1") {
        Import-Module -Name "C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1"
    } else {
        Write-Host "Veeam PowerShell module not present and could not be found at the default location"
        Write-DRMMAlert "BAD | Missing PowerShell module"
        if ($verbose -eq "True") {
            Write-Host $(Get-Module -ListAvailable -Name Veeam*)
        }
        Exit 1
    }
} else {
    Import-Module "Veeam.Backup.PowerShell"
}

# some counters for the status output
$u = 0
$i = 0

# Create array for misconfigured jobs
$misconfigured = @()

# Grab all VM backup jobs
$vbrJobs = Get-VBRJob

# Iterate through them
foreach ($job in $vbrJobs) {
    try {
        if (($job.JobType -eq "Backup" -or $job.JobType -eq "Replica") -and $job.VssOptions.AreWinCredsSet -eq $false -and $job.IsScheduleEnabled -eq $true) {
            # If backup or replica job and credentials are not configured
            $misconfigured += "$($job.Name)`n"
        } elseif (($job.JobType -eq "Backup" -or $job.JobType -eq "Replica") -and $job.VssOptions.WinGuestFSIndexingOptions.Enabled -eq $false -and $job.IsScheduleEnabled -eq $true) {
            # If backup or replica job, Guest indexing is disabled and guest credentials are configured
            Enable-VBRJobGuestFSIndexing -Job $job
            $u++
        }  else {
            # Else everything is setup as expected or job is disabled
            $i++
        }
    } catch {
        Write-DRMMAlert "BAD | Failed to update $($Job.Name) to enable guest file indexing"
        Write-DRMMDiagnostic "$($_.ScriptStackTrace)`n$($_.Exception)"
        Exit 1
    }
}

# Grab all Agent backup jobs, but only if they are managed by the Backup server
$computerJobs = Get-VBRComputerBackupJob -Mode ManagedByBackupServer

# Iterate through them
foreach ($cJob in $computerJobs) {
    try {
        if ($cjob.IndexingEnabled -eq $false -and $cJob.IsScheduleEnabled -eq $true) {
            # If indexing is disabled in job properties
            Enable-VBRJobGuestFSIndexing -Job $job
            $u++
        } else {
            # else everything configure correctly or job is disabled
            $i++
        }
    } catch {
        Write-DRMMAlert "BAD | Failed to update $($cJob.Name) to enable guest file indexing"
        Write-DRMMDiagnostic "$($_.ScriptStackTrace)`n$($_.Exception)"
        Exit 1
    }
}

# Generate DRMM alert for misconfigured job
if ($misconfigured.Count -ne 0) {
    Write-DRMMAlert "BAD | Misconfigured jobs found"
    Write-DRMMDiagnostic "Misconfigured jobs (likely credentials not configured in job properties):`n$misconfigured`nThese will require manual resolution"
    Exit 1
}

# Final count of all found backup jobs for a nice output to console
$count = $vbrJobs.Count + $computerJobs.Count

if ($count -ne 0) {
    Write-DRMMStatus "OK | $count jobs | $u updated | $i OK"
} else {
    Write-DRMMStatus "OK | No backup jobs found"
}