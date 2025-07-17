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
    Connect-VBRServer -Server localhost
    $config = Get-VBRConfigurationBackupJob

    if ($config.Enabled -eq $true) {
        switch ($config.LastResult) {
            Success {write-DRMMStatus "$(Get-Date -Format HH:mm) | SUCCESS | Next backup: $($config.NextRun)"}
            Warning {write-DRMMStatus "$(Get-Date -Format HH:mm) | WARNING | Next backup: $($config.NextRun)"}
            Failed {
                write-DRMMAlert "$(Get-Date -Format HH:mm) | FAILED | Next backup: $($config.NextRun)"
                Write-DRMMDiagnostic ($config | Format-List)
                Exit 1
            }
        }
    } else {
        write-DRMMAlert "$(Get-Date -Format HH:mm) | NOT CONFIGURED"
        Write-DRMMDiagnostic "Backup configuration job is NOT configured!"
        Exit 1
    }
} catch {
    write-DRMMAlert "$(Get-Date -Format HH:mm) | SCRIPT FAILED"
    Write-DRMMDiagnostic "Script failed - please investigate VBR and PowerShell on server."
    Exit 1
}