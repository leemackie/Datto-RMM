
<#
.SYNOPSIS
Using Datto RMM, install the DNSFilter agent to a Windows device.
Requires either DNSFilter secret key to be set at the site level with the name DNSFilterCustToken
 or set at the component level during one-off execution

.NOTES
Version 0.2 - Written by Lee Mackie
Increased logic significantly, allowing for linking with a monitor component
Also added error capture
#>

try {
    function Get-DNSFilterStatus () {
        $Global:DNSFilterAgent = Get-Service -name "DNSFilter Agent" -ea SilentlyContinue
    }

    function Remove-DNSFilterInstaller () {
        # Delete the installer once script is complete
        Remove-Item "$ENV:temp\DNSFilter_Agent_Setup.msi" -Force
        Write-Output "-- Deleted installer at $env:temp\DNSFilter_Agent_Setup.msi"
    }

    # Check for the Site Variables
    Write-Output ""
    Write-Output "-- Checking the DRMM variables"

    # Check if DNSFilter secret key is set
    if ($ENV:DNSFilterCustToken -ne $null) {
        Write-Host "-- DNSFilter secret key set at customer level, proceeding"
        $Token = $env:DNSFilterCustToken
    } elseif ($env:SecretKey -ne $null){
        Write-Output "-- DNSFilter Secret Key set at component level, proceeding."
        $Token = $env:SecretKey
    } else {
        Write-Output "-- No secret key defined, please re-execute the script with either the secret key configured at site or component level."
        Exit 1
    }


    # Download DNSFilter installer to C:\Temp
    Write-Output "-- Downloading setup to $env:Temp"
    Invoke-WebRequest -Uri "https://download.dnsfilter.com/User_Agent/Windows/DNSFilter_Agent_Setup.msi" -OutFile "$env:Temp\DNSFilter_Agent_Setup.msi"

    # Install DNSFilter agent
    Write-Output "-- Starting installation"
    $installer = "$env:Temp\DNSFilter_Agent_Setup.msi"
    $installargs = "/i $installer /qn /norestart NKEY=$Token /l* $env:Temp\DNSFilter_Install.log"
    $install = Start-Process msiexec.exe -ArgumentList $InstallArgs -PassThru -Wait

    # Check for exit codes
    if (($install.ExitCode -eq '0') -or ($install.ExitCode -eq '3010')) {
        Write-Output "-- Installer exited successfully, indications are install was successful"

        Get-DNSFilterStatus
        if ($DNSFilterAgent.Status -eq "Running") {
            Write-Output "-- DNSFilter Service running"

            # Delete the installer once script is complete
            Remove-DNSFilterInstaller
        } elseif ($DNSFilterAgent.Status -eq "Stopped") {
            Write-Output "-- DNSFilter installed but service stopped"
            Write-Output "-- Please investigate further"

            # Delete the installer once script is complete
            Remove-DNSFilterInstaller
        }
    } elseif ($install.ExitCode -eq '1618') {
        Write-Host "-- Installation failed; the endpoint must be restarted prior to retrying installation"
        Exit 1
    } else {
        Write-Host "-- Installation failed unexpectedly, please review logs and try again"
        Write-Output "-- MSIExec Install log $env:Temp\DNSFilter_Install.log"
        Exit 1
    }
} catch {
    Write-Output "Script failed unexpectedly"
    Write-Output $_
}