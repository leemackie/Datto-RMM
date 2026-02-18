<#
.SYNOPSIS
zScaler installation script for use with Datto RMM.
Checks if zScaler is already installed, and if not, installs it using the provided MSI installer

Written by Lee Mackie - 5G Networks

.HISTORY
Version 0.1 - 03/12/24 - Initial script creation
#>

$softwareName = "zScaler" # Replace with the name of the software you're looking for
$installationFile = "Zscaler-windows-installer-x64.msi" # Ensure this MSI file is attached to the RMM component
$installedSoftware = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object {$_.DisplayName -like "$softwareName"} |
    Select-Object DisplayName, DisplayVersion

if (!$installedSoftware) {
    # Install the software package
    Write-Host "Installing Software Package..."
    $install = Start-Process msiexec.exe -ArgumentList "/i `"$pwd\$installationFile`" /quiet" -Wait -PassThru
} else {
    Write-Host "ERROR: $softwareName is already installed. Version: $($installedSoftware.DisplayVersion)"
    Exit 1
}

if ($install.ExitCode -eq 0) {
    Write-Host "SUCCESS: $softwareName installed successfully." -ForegroundColor Green
} elseif ($install.ExitCode -eq 3010) {
    Write-Host "WARNING: Installation completed, reboot required. Exit code: $($install.ExitCode)."
} else {
    Write-Host "ERROR: Installation failed with exit code $($install.ExitCode)."
    Exit 1
}
