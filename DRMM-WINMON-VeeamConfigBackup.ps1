<#
.SYNOPSIS
Using Datto RMM, check the Veeam Backup and Replication backup configuration backup stastus.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Monitor
Version 1.0 - Initial release
Version 1.1 - Updated to use Veeam.Backup.PowerShell module via code, standardised output and added verbosity
Version 1.2 - Refactored to support Veeam B&R v13 and PowerShell 7, cleaned up some of the logic and calls
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
function Write-DRMMDiagnostic ($messages) {
    write-host '<-Start Diagnostic->'
    foreach ($message in $messages) { $message }
    write-host '<-End Diagnostic->'
}

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

    $config = Get-VBRConfigurationBackupJob

    if ($config.Enabled -eq $true) {
        switch ($config.LastResult) {
            Success {write-DRMMStatus "OK: $(Get-Date -Format HH:mm) | Next backup: $($config.NextRun)"}
            Warning {write-DRMMStatus "WARNING: $(Get-Date -Format HH:mm) | Next backup: $($config.NextRun)"}
            Failed {
                write-DRMMAlert "FAILED: $(Get-Date -Format HH:mm) | Next backup: $($config.NextRun)"
                Write-DRMMDiagnostic ($config | Format-List)
                Exit 1
            }
        }
    } else {
        write-DRMMAlert "BAD: $(Get-Date -Format HH:mm) | NOT CONFIGURED"
        Write-DRMMDiagnostic "Backup configuration job is NOT configured!"
        Exit 1
    }
} catch {
    write-DRMMAlert "BAD: $(Get-Date -Format HH:mm) | SCRIPT FAILED"
    Write-DRMMDiagnostic "Script failed - please investigate VBR and PowerShell on server.`n $($_.ScriptStackTrace)`n$($_.Exception)"
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