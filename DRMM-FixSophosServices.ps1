### DRMM process for attempting to repair broken or non-installed Sophos services ###

#Sophos Paths
$sophosRepairPath = "C:\ProgramData\Sophos\AutoUpdate\Cache\sophos_autoupdate1.dir"
$sophosSAUPath = "C:\ProgramData\Sophos\AutoUpdate\Cache\decoded\sau\"

#Sophos Auto-Update install
$sauPathInstaller = "$sophosSAUPath\Sophos AutoUpdate.msi"
$LogFileLocation = "C:\Windows\Temp\Sophos.log"

try {
    if ((Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "health") -ne "1") {
        if ((Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service") -ne "1") {
           $sophosHealth = @{}
           $sophosHealth.Add("HitmanPro.Alert Service", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.HitmanPro.Alert service" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos Endpoint Defense", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos Endpoint Defense" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos Endpoint Defense Service", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos Endpoint Defense Service" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos File Integrity Monitoring", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos File Integrity Monitoring" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos File Scanner", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos File Scanner" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos File Scanner Service", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos File Scanner Service" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos MCS Agent", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos MCS Agent" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos MCS Client", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos MCS Client" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos Network Threat Protection", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos Network Threat Protection" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("System Protection Service", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.System Protection Service" -ErrorAction SilentlyContinue))
           $sophosHealth.Add("Sophos NetFilter", (Get-ItemPropertyValue -Path "HKLM:\Software\WOW6432Node\Sophos\Health\Status\" -Name "service.Sophos NetFilter" -ErrorAction SilentlyContinue))
        }
    }

    #Try and run update and fix the services -- This step may work unless SED service is broken
    if ($sophosHealth['Sophos Endpoint Defense Service'] -eq "1") {
        try {
            $sau = Get-Service "Sophos Autoupdate Service" -ErrorAction SilentlyContinue
            if ($sau) {
                #If the service exists
                Write-Warning "## Sophos Autoupdate service present - skipping installation"
                Write-Host "## Skipping installation of Sophos Autoupdate component as it is already installed"

                #Stop the service
                Write-Host "## Stopping the Sophos AutoUpdate service"
                Stop-Service "Sophos Autoupdate Service" -Force -ErrorAction SilentlyContinue -InformationAction SilentlyContinue

                #Rename AutoUpdate folders as per Sophos troubleshooting procedure
                Write-Host "## Renaming Sophos AutoUpdate folders"
                Rename-Item "C:\ProgramData\Sophos\AutoUpdate\Cache\decoded" "C:\ProgramData\Sophos\AutoUpdate\Cache\decoded_old" -ErrorAction Continue
                Rename-Item "C:\ProgramData\Sophos\AutoUpdate\data\warehouse" "C:\ProgramData\Sophos\AutoUpdate\data\warehouse_old"  -ErrorAction Continue
                Rename-Item "C:\ProgramData\Sophos\AutoUpdate\data\repo" "C:\ProgramData\Sophos\AutoUpdate\data\repo_old"  -ErrorAction Continue

                #If the below file exists, delete it as per Sophos troubleshooting procedure
                Write-Host "## Deleting SophosUpdateStatus.xml if it exists"
                if (Test-Path "C:\ProgramData\Sophos\AutoUpdate\data\status\SophosUpdateStats.xml" -ErrorAction SilentlyContinue) {
                    Remove-Item "C:\ProgramData\Sophos\AutoUpdate\data\status\SophosUpdateStatus.xml" -ErrorAction Continue
                }

                #Start the service
                Write-Host "## Starting the Sophos AutoUpdate service"
                Start-Service "Sophos Autoupdate Service" -ErrorAction SilentlyContinue
            } else {
                #If service does not exist, install

                #Check the Sophos AutoUpdate MSI installer exists
                Write-Host "## Installing the Sophos AutoUpdate service"
                $test = Test-Path $sauPathInstaller -ErrorAction SilentlyContinue
                if ($test) {
                    msiexec /i ""$sauPathInstaller"" /qn /norestart /L*V ""$LogFileLocation""
                    Start-Sleep -Seconds 60
                }
            }

            #Try to run a manual update via CLI
            Write-Host "## Running the Sophos AutoUpdate CLI software to initiate update"
            Start-Process "C:\Program Files (x86)\Sophos\AutoUpdate\SAUcli.exe" -ArgumentList "updatenow"
            $sauStep = "0"
        } catch {
            Write-Host "!!! Something unexpected went wrong trying to install or run Sophos AutoUpdate"
            Write-Output $_
        }
    }

    #Run repair in-built repair operations - this is last resort
    try {
        if (!$sauStep -or $sauStep -ne "0" -or $ENV:ForceFix -eq "true") {
            Write-Host "!!! We are going to run a Sophos Endpoint repair - this will highly likely require a reboot to complete`n"
            if (!(Test-Path $sophosRepairPath -ErrorAction SilentlyContinue)) {
                Write-Host "## We failed to find the repair software - we will try and manually create the required files."
                Write-host "## This may fail - please review output carefully"
                if ((Test-Path "$sophosSAUPath" -ErrorAction SilentlyContinue)) {
                    New-Item -Path "C:\ProgramData\Sophos\AutoUpdate\Cache\" -Name "sophos_autoupdate1.dir"
                    Copy-Item -Path "$sophosSAUPath\su-repair.exe" -Destination $sophosRepairPath
                    Copy-Item -Path "$sophosSAUPath\su-setup32.exe" -Destination $sophosRepairPath
                    Copy-Item -Path "$sophosSAUPath\su-setup64.exe" -Destination $sophosRepairPath
                    Copy-Item -Path "$sophosSAUPath\SopphosUpdate.exe" -Destination $sophosRepairPath
                } else {
                    Write-Host "!!! Sophos Autoupdate directory doesn't exist"
                    Write-Host "!!! Manually reinstall via the installer after removing Sophos from the machine"
                    Exit 1
                }
            }
        }
        Write-Host "## Executing Sophos repair software - this will require a reboot to complete (if successful)"
        Write-Host "!!! Please review output carefully"
        Start-Process "$sophosRepairPath\su-repair.exe"
    } catch {
        Write-Host "!!! Something unexpected went wrong with the repair`n"
        $_
    }
} catch {
    Write-Host "!!! Something unexpected went wrong with the script`n"
    $_
}