## DRMM-LiongardUninstall.ps1
## Version 1.0
##
## Update v1.0: Uninstall liongard
##
## Thanks to David Chapman @ Liongard for the base script

# Set the variables for script execution
$application = Get-WmiObject -Class Win32_Product -Filter "Name = 'Liongard Agent'"
$application2 = Get-WmiObject -Class Win32_Product -Filter "Name = 'RoarAgent'"
$Folder="C:\ProgramData\CentraStage\Temp"

if ($application) {
    Write-Host "## A recent version of the Liongard Agent was found! Uninstalling the Liongard Agent."
    $uninstall = $application.Uninstall()
    if ($uninstall.ReturnValue -ne "0") {
        Write-Host "!! ERROR: Failed to uninstall old version of Liongard - please review the machine manually"
        Exit 1
    } else {
        Write-Host "## SUCCESS: Uninstallation completed"
        $success = $true
    }
}

if ($application2) {
    Write-Host "An old version of RoarAgent was found. Uninstalling the RoarAgent."
    $uninstall = $application2.Uninstall()
    if ($uninstall.ReturnValue -ne "0") {
        Write-Host "!! ERROR: Failed to uninstall old version of Liongard - please review the machine manually"
        Exit 1
    } else {
        Write-Host "## SUCCESS: Uninstallation completed"
        $success = $true
    }
}

if (!$success) {
    Write-Host "## No old Liongard Agent install was found."
    Write-Host "## Proceeding with modern uninstall via MSI"
} else {
    Write-Host "## Removal of old installs completed. Fire script again if there is still a Liongard install left over to use the MSI."
    Exit 0
}

# Set TLS 1.2 to be used in Powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Checks if $Folder exists, creates one if not, and downloads the MSI installer.
Write-Host "## Checking if folder [$Folder]  exists..."
if (Test-Path -Path $Folder) {
    Write-Host "## Path exists! Downloading Liongard Agent installer, please wait..."
    Start-Sleep -Seconds 2

} else {
    Write-Host "## Path doesn't exist. Creating Liongard folder in [$Folder]"
    # Creates the Liongard folder in C:\.
    New-Item -Path $Folder -ItemType Directory
        if (Test-Path -Path $Folder) {
            Write-Host "## [$Folder] was created successfully! Downloading Liongard Agent installer, please wait..."
            Start-Sleep -Seconds 2
        } else {
            Write-Host "!! ERROR: Unable to create folder, please check permissions."
            Exit 1
        }
}

# Downloads the Liongard MSI.
Invoke-WebRequest -Uri "https://agents.static.liongard.com/LiongardAgent-lts.msi" -OutFile "$Folder\LiongardAgent-lts.msi"

# Installs the MSI in silent mode, with parameters, and generates a log in the $Folder directory.
Write-Host "## Uninstalling the Liongard Agent"
$msiparams = "/x ""$Folder\LiongardAgent-lts.msi"" /qn /norestart"
$install = Start-Process msiexec.exe -Wait -ArgumentList $msiparams -PassThru
Start-Sleep -Seconds 2

# Remove the Liongard installation file
Write-Host "## Uninstall finished, deleting [$Folder\LiongardAgent-lts.msi]"
Remove-Item -Path "$Folder\LiongardAgent-lts.msi"

# Check if the installation was successful, if not mark job as failed
if ($install.Exitcode -eq "0") {
    Write-Host "## The script has completed, please wait a few minutes and verify the Liongard Agent was uninstalled successfully."
    Start-Sleep -Seconds 5
} else {
    Write-Host "!! ERROR: The uninstallation failed with exit code $($install.Exitcode)."
    Exit 1
}