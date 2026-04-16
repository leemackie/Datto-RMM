<#
.SYNOPSIS
Datto RMM monitor component to download and run the HP Image Assistant tool to check for driver and firmware updates on HP devices.
Reports status and diagnostic messages back to the Datto RMM console.
Alert status generated if any updates are required otherwise alert output generated, but completes without alert.

Written by Lee Mackie - 5G Networks

.NOTES
None

.HISTORY
Version 1.0 - Initial release
Version 1.0.1 - Updated installation to 5.3.5
Version 1.0.2 - Changed installer download directory, and also added a check for the old installer which can cause the ImageAssistant tool to
                display a prompt. This will cause the execution to fail.
#>

$HPIADownloadUrl = "https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.5.exe" # See here for latest download: https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html
$HPIAUserGuideUrl = "https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/HPIAUserGuide.pdf"
$HPIAHash = "F73EFC953E5D3F900A69C429A7C1CC7441184F8FA4DBB063773D9ABFA0C10009" # Get-Filehash -Path <Installer> -Algorithm SHA256
$HPAIVersion = "5.3.5.579" # Right click HPImageAssistant.exe -> Properties -> Details -> File version, this is the value to compare against to determine if an update is required
$HPIAPath = "C:\HP\HPIA"
$HPIAInstaller = "hpia_install.exe"
$HPIAExecutable = "HPImageAssistant.exe"
$TempPath = "C:\ProgramData\CentraStage\Temp"

function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

function exitScript ($exitCode = 0) {
    Write-Host "<-End Diagnostic->"
    Exit $exitCode
}

Write-Host "<-Start Diagnostic->"

if (Get-Process -Name "HPImageAssistant" -ErrorAction SilentlyContinue) {
    Write-DRMMAlert "ERROR | HP Image Assistant is currently running, cannot proceed with update analysis. Please close any running instances of HP Image Assistant and try again."
    Write-Host "!! ERROR: HP Image Assistant is currently running, cannot proceed with update analysis"
    exitScript 1
}

try {
    Write-Host "-- Starting HP Image Assistant download and verification process"

    # Set TLS 1.2 to be used in Powershell
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    # Check if HP Image Assistant directory ready to go
    if (-not (Test-Path $HPIAPath)) {
        $split = $HPIAPath.Split('\')
        New-Item "$($split[0])\$($split[1])" -ItemType Directory -Force | Out-Null
        New-Item "$($split[0])\$($split[1])\$($split[2])" -ItemType Directory -Force | Out-Null
    }

    if (Test-Path "$HPIAPath\$HPIAExecutable") {
        Write-Host "-- HP Image Assistant detected"
        if ((Get-Item "$HPIAPath\$HPIAExecutable").VersionInfo.FileVersion -ne $HPAIVersion) {
            Write-Host "-- HP Image Assistant version does not match expected value, update required"
            Write-Host "   Expected version: $HPAIVersion"
            Write-Host "   Detected version: $((Get-Item "$HPIAPath\$HPIAExecutable").VersionInfo.FileVersion)"
            $download = $true
        } else {
            Write-Host "-- HP Image Assistant version matches expected value, no update required"
        }
    } else {
        Write-Host "-- HP Image Assistant not detected, installation required"
        $download = $true
    }

    if ($download -eq $true) {
        # Download the latest HP Image Assistant installer to the specified path
        Invoke-WebRequest -Uri $HPIADownloadUrl -OutFile "$HPIAPath\$HPIAInstaller"

        # Verify file hash
        $downloadedHash = Get-FileHash -Path "$HPIAPath\$HPIAInstaller" -Algorithm SHA256 -ErrorAction SilentlyContinue
        if ($downloadedHash.Hash -ne $HPIAHash) {
            Write-DRMMStatus "ERROR | Downloaded file hash does not match expected value"
            Write-Host "!! ERROR: Downloaded file hash does not match expected value"
            Write-Host "   Expected: $HPIAHash"
            Write-Host "   Actual: $($downloadedHash.Hash)"
            Write-Host "   HP Image Assistant download failed integrity check, if the issue persists please check for an updated version of this script with the new hash value and try again."
            exitScript 1
        }

        Write-Host "-- HP Image Assistant downloaded and verified successfully"
        Start-Process "$HPIAPath\$HPIAInstaller" -ArgumentList "/s","/e","/f $HPIAPath" -Wait -NoNewWindow
        if (-not (Test-Path "$HPIAPath\$HPIAExecutable")) {
            Write-DRMMAlert "ERROR | HP Image Assistant executable not found after installation. Review installation process and try again."
            exitScript 1
        }

        # We're doing a check for the old installer in the $HPIAPath folder as this will now cause a prompt during execution of the HP IA tool
        if (Test-Path "$HPIAPath\$HPIAInstaller") {
            Remove-Item "$HPIAPath\$HPIAInstaller" -Force -ErrorAction SilentlyContinue
        }
        Remove-Item "$TempPath\$HPIAInstaller" -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-DRMMAlert "ERROR | Unexpected error during verification, download or extraction. Check diagnostics for details."
    Write-Host "!! ERROR: Unexpected error during download or extraction: $($_.Exception.Message)"
    exitScript 1
}

try {
    Write-Host "-- HP Image Assistant update process started"

    # Check for updates silently
    Write-Host "-- Checking for available updates..."
    $analyzeProcess = Start-Process "$HPIAPath\$HPIAExecutable" -ArgumentList "/Operation:Analyze", "/Action:List", "/Silent", "/ReportFolder:$HPIAPath\Report" -NoNewWindow -Wait -PassThru

    If (-not (Test-Path $HPIAPath\Report\*.json)) {
        Write-DRMMAlert "ERROR | Update analysis failed, no report generated. Check diagnostics for details."
        Write-Host "!! ERROR: No report generated, update analysis failed"
        Write-Host "   HP Image Assistant update process exit code: $($analyzeProcess.ExitCode)"
        Write-Host "   Error codes and more info can be found here: $HPIAUserGuideUrl"
        exitScript 1
    }

    Write-Host "-- Update analysis completed successfully"
    $reqUpdates = Get-Content -Path $HPIAPath\Report\*.json | ConvertFrom-Json

    if (($reqUpdates.HPIA.Recommendations).Count -gt 0) {
        Write-DRMMStatus "UPDATE | $(($reqUpdates.HPIA.Recommendations).Count) update(s) found"
        foreach ($update in $reqUpdates.HPIA.Recommendations) {
            Write-Host "    -- Update Name: [$($update.SoftPaqID)] $($update.Name)"
            Write-Host "       Version: $($update.RecommendationValue)"
            Write-Host "       Severity: $($update.Severity)"
            Write-Host "       Comments: $($update.Comments)"
        }
        exitScript 1
    } else {
        Write-DRMMStatus "OK | No updates required, system is up to date"
    }
} catch {
    Write-DRMMAlert "ERROR | Unexpected error during update analysis. Check diagnostics for details."
    Write-Host "!! ERROR: Unexpected error during update analysis: $($_.Exception.Message)"
    exitScript 1
}

exitScript