<#
.SYNOPSIS
Sophos Connect deployment script.
Will execute the Sophos Connect installation MSI and apply a configuration profile if specified.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Application
!! Requires EXE installation file attached to installer with filename 'SophosConnect.msi'

.HISTORY
Version 0.1 - Initial release.
#>

# Execute installation of Sophos Connect MSI file
try {
    Write-Host "-- Starting Sophos Connect installation"
    $installer = "$pwd\SophosConnect.msi"
    $installargs = "/i $installer /qn /norestart /L*V $env:Temp\SophosConnect_Install.log"
    $install = Start-Process msiexec.exe -ArgumentList $InstallArgs -PassThru -Wait

    # Check for exit codes
    if (($install.ExitCode -eq '0') -or ($install.ExitCode -eq '3010')) {
        Write-Host "-- Installer exited successfully, indications are install was successful"
    } elseif ($install.ExitCode -eq '1618') {
        Write-Host "-- Installation failed; the endpoint must be restarted prior to retrying installation"
        Exit 1
    } else {
        Write-Host "-- Installation failed unexpectedly, please review logs and try again. Installation exit code: $($install.ExitCode)"
        Write-Host "---- MSIExec Install log $env:Temp\SophosConnect_Install.log"
        Exit 1
    }
} catch {
    Write-Host "!! FAILURE: Script failed unexpectedly"
    Write-Host $_
}

# Check the sccli executable exists as a guardrail for weird install failure
$scExec = Get-Item "C:\Program Files (x86)\Sophos\Connect\sccli.exe" -ErrorAction SilentlyContinue

# Install Sophos Connect profile if specified
if ($scExec) {
    if ($ENV:usrInstallProfile -eq "True") {
        #$output = . $scExec add -f "$pwd\SophosConnectProfile.scx"
        Write-Host "-- Installing Sophos Connect profile"
        $decodedProfile = [System.Convert]::FromBase64String($ENV:usrSCProfileBase64)
        Set-Content -Path "$env:Temp\SophosConnectProfile.scx" -Value $decodedProfile -Encoding Byte
        Write-Host "-- Executing sccli to add profile"
        Start-Process $scExec -ArgumentList "add -f `"$env:Temp\SophosConnectProfile.scx`"" -NoNewWindow -Wait #-PassThru
        Remove-Item "$env:Temp\SophosConnectProfile.scx" -Force
    }
} else {
    Write-Host "!! FAILURE: Sophos Connect executable not found, cannot proceed. Installation has failed, please review logs."
    Write-Host "-- MSIExec Install log $env:Temp\SophosConnect_Install.log"
    Exit 1
}

Write-Host "-- Sophos Connect installation script completed."