## DRMM-LiongardInstall.ps1
## Version 1.1
##
## Update v0.1: Modified for use for Datto RMM
## Update v1.0: Added some error capturing around the installation of the MSI file
## Update v1.1: Silenced the uninstallation of existing Liongard agents, added uninstall success check, removed and cleaned up some redundant code
##
## Thanks to David Chapman @ Liongard for the base script
## Script requires the following variables set at the site level: LiongardURL, LiongardKey, LiongardSecret and LiongardEnvironment

# Set the variables for script execution
$application = Get-WmiObject -Class Win32_Product -Filter "Name = 'Liongard Agent'"
$application2 = Get-WmiObject -Class Win32_Product -Filter "Name = 'RoarAgent'"
$Folder="C:\ProgramData\CentraStage\Temp"
$URL = $ENV:LiongardURL
$Key = $ENV:LiongardKey
$Secret = $ENV:LiongardSecret
$Environment = $ENV:LiongardEnvironment

# Verify the Liongard site variables exist and fail if they don't (these are required)
if (!($URL) -or !($Key) -or !($Secret) -or !($Environment)) {
    Write-Host "!! ERROR: Variables not set on site in DRMM - failing."
    Write-Host "!! Please refer to the onboarding guide for further information."
    Exit 1
}

#Checks for the new and old versions of the Liongard agent and uninstalls them.
if ($application) {
    Write-Host "A recent version of the Liongard Agent was found! Uninstalling the Liongard Agent."
    $uninstall = $application.Uninstall()
    if ($uninstall.ReturnValue -ne "0") {
        Write-Host "!! ERROR: Failed to uninstall old version of Liongard - please review the machine manually"
        Exit 1
    }
} elseif ($application2) {
    Write-Host "An old version of RoarAgent was found. Uninstalling the RoarAgent."
    $uninstall = $application2.Uninstall()
    if ($uninstall.ReturnValue -ne "0") {
        Write-Host "!! ERROR: Failed to uninstall old version of Liongard - please review the machine manually"
        Exit 1
    }
} else {
    Write-Host "No Liongard Agent install was found. Skipping to install."
}

# Set TLS 1.2 to be used in Powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Checks if $Folder exists, creates one if not, and downloads the MSI installer.
Write-Host "Checking if folder [$Folder]  exists..."
if (Test-Path -Path $Folder) {
    Write-Host "Path exists! Downloading Liongard Agent installer, please wait..."
    Start-Sleep -Seconds 2
    # Downloads the Liongard MSI.
    Invoke-WebRequest -Uri "https://agents.static.liongard.com/LiongardAgent-lts.msi" -OutFile "$Folder\LiongardAgent-lts.msi"
} else {
    Write-Host "Path doesn't exist. Creating Liongard folder in [$Folder]"
    # Creates the Liongard folder in C:\.
    New-Item -Path $Folder -ItemType Directory
        if (Test-Path -Path $Folder) {
            Write-Host "[$Folder] was created successfully! Downloading Liongard Agent installer, please wait..."
            Start-Sleep -Seconds 2
            #Downloads the Liongard MSI.
            Invoke-WebRequest -Uri "https://agents.static.liongard.com/LiongardAgent-lts.msi" -OutFile "$Folder\LiongardAgent-lts.msi"
        } else {
            Write-Host "!! ERROR: Unable to create folder, please check permissions."
            Exit 1
        }
}

# Installs the MSI in silent mode, with parameters, and generates a log in the $Folder directory.
Write-Host "Installing the Liongard Agent. Please wait."
$msiparams = "/i ""$Folder\LiongardAgent-lts.msi"" LIONGARDURL=$URL LIONGARDACCESSKEY=$Key LIONGARDACCESSSECRET=$Secret LIONGARDENVIRONMENT=`"$Environment`" LIONGARDAGENTNAME=""$env:computername"" /qn /norestart /L*V ""$Folder\AgentInstall.log"""
$install = Start-Process msiexec.exe -Wait -ArgumentList $msiparams -PassThru
Start-Sleep -Seconds 2

# Remove the Liongard installation file
Write-Host "Install finished, deleting [$Folder\LiongardAgent-lts.msi]"
Remove-Item -Path "$Folder\LiongardAgent-lts.msi"

# Check if the installation was successful, if not mark job as failed
if ($install.Exitcode -eq "0") {
    Write-Host "The script has completed, the install log is located in [$Folder]. Please wait a few minutes and verify the Liongard Agent was installed successfully."
    Start-Sleep -Seconds 5
} else {
    Write-Host "ERROR: The installation failed with exit code $($install.Exitcode) - please review the log in [$Folder] for more information."
    Exit 1
}