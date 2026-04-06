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