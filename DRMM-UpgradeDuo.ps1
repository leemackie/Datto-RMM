## Dwonload, and upgrade an existing Duo Authentication for Windows installation
## Version 1.1
## Written by Lee Mackie - leem@5gn.com.au
## V1.1 - Added TLS 1.2 security protocol

# Download the latest install file
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://dl.duosecurity.com/duo-win-login-latest.exe" -OutFile "C:\ProgramData\CentraStage\Temp\duo-win-login-latest.exe" -UseBasicParsing

# Confirm download was successful and file is present
if (!(Get-Item "C:\ProgramData\CentraStage\Temp\duo-win-login-latest.exe")) {
    Write-Host "ERROR: Failed to find downloaded Duo installer."
    Exit 1
}

# Execute the Duo installation file silently
$duoInstall = Start-Process "C:\ProgramData\CentraStage\Temp\duo-win-login-latest.exe" -ArgumentList "/S /v/qn" -PassThru -Wait

# Check that the install succeeded
if ($duoInstall.ExitCode -eq "0" -or $duoInstall.ExitCode -eq "3010") {
    Write-Host "SUCCESS: Upgrade of the installation was successful!"

    Remove-Item "C:\ProgramData\CentraStage\Temp\duo-win-login-latest.exe" -Force
} else {
    Write-Host "ERROR: Something may have gone wrong with the install, we did not see the expected exit code."
    Write-Host "Please check the machine and try again"
    Write-Host "Exit code: $duoInstall.ExitCode"

    Remove-Item "C:\ProgramData\CentraStage\Temp\duo-win-login-latest.exe" -Force
    Exit 1
}