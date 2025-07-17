## Set TLS1.2 for Powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Folder = "C:\ProgramData\CentraStage\Temp"
$downloadURL = "https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe"

Write-Host "Checking if folder [$Folder] exists..."
if (Test-Path -Path $Folder) {
    Write-Host "Path exists! Downloading PowerBI installer, please wait..."
    Start-Sleep -Seconds 2
    # Downloads PowerBI
    Invoke-WebRequest -Uri $downloadURL -OutFile "$Folder\PBIDesktopSetup_x64.exe"
} else {
    Write-Host "Path doesn't exist. Creating folder: [$Folder]"
    # Creates the required folder
    New-Item -Path $Folder -ItemType Directory
        if (Test-Path -Path $Folder) {
            Write-Host "[$Folder] was created successfully! Downloading PowerBI installer, please wait..."
            Start-Sleep -Seconds 2
            #Downloads the Liongard MSI.
            Invoke-WebRequest -Uri $downloadURL -OutFile "$Folder\LiongardAgent-lts.msi"
        } else {
            Write-Host "!! ERROR: Unable to create folder, please check permissions."
            Exit 1
        }
}

# Installs the software in silent mode, with parameters
Write-Host "Installing PowerBI. Please wait."
$install = Start-Process "$folder\PBIDesktopSetup_x64.exe" -ArgumentList "-quiet -norestart ACCEPT_EULA=1" -Wait -PassThru
Start-Sleep -Seconds 2

# Remove the installation file
Write-Host "Install process finished, deleting files"
Remove-Item -Path "$Folder\PBIDesktopSetup_x64.exe"

# Check if the installation was successful, if not mark job as failed
if ($install.Exitcode -eq "0") {
    Write-Host "The script has completed. Please wait a few minutes and verify the Liongard Agent was installed successfully."
    Start-Sleep -Seconds 5
} else {
    Write-Host "ERROR: The installation failed with exit code $($install.Exitcode)."
    Exit 1
}