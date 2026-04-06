<#
.SYNOPSIS
Datto RMM script compnent to download and run the HP Image Assistant tool to check for and install driver and firmware updates on HP devices.

Written by Lee Mackie - 5G Networks

.NOTES
None

.HISTORY
Version 1.0 - Initial release
#>

$HPIADownloadUrl = "https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.4.exe" # See here for latest download: https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html
$HPIAUserGuideUrl = "https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/HPIAUserGuide.pdf"
$HPIAHash = "B6E186787EBF33010C2599A69E79DA4638C8391A74E4E93D6240244FB2A560F0"
$HPAIVersion = "5.3.4.550"
$HPIAPath = "C:\HP\HPIA"
$HPIAInstaller = "hpia_install.exe"
$HPIAExecutable = "HPImageAssistant.exe"
$DownloadPath = "$HPIAPath\HPUpdates"
$SuccessCount = 0
$FailureCount = 0

if (Get-Process -Name "HPImageAssistant" -ErrorAction SilentlyContinue) {
    Write-Host "!! ERROR: HP Image Assistant is currently running, cannot proceed with update analysis"
    exit 1
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
            Write-DRMMStatus "ERROR: Downloaded file hash does not match expected value"
            Write-Host "!! ERROR: Downloaded file hash does not match expected value"
            Write-Host "   Expected: $HPIAHash"
            Write-Host "   Actual: $($downloadedHash.Hash)"
            Write-Host "   HP Image Assistant download failed integrity check, if the issue persists please check for an updated version of this script with the new hash value and try again."
            exitScript 1
        }

        Write-Host "-- HP Image Assistant downloaded and verified successfully"
        Start-Process "$HPIAPath\$HPIAInstaller" -ArgumentList "/s","/e","/f $HPIAPath" -Wait -NoNewWindow
        if (-not (Test-Path "$HPIAPath\$HPIAExecutable")) {
            Write-DRMMAlert "ERROR: HP Image Assistant executable not found after installation. Review installation process and try again."
            exitScript
        }
    }
} catch {
    Write-DRMMAlert "ERROR: Unexpected error during verification, download or extraction. Check diagnostics for details."
    Write-Host "!! ERROR: Unexpected error during download or extraction: $($_.Exception.Message)"
    exit 1
}

try {
    Write-Host "-- HP Image Assistant update process started"
    New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null

    # Check for updates silently
    if (test-Path $HPIAPath\Report\*.json) {
        Remove-Item $HPIAPath\Report\* -Force
    }

    Write-Host "-- Checking for available updates..."
    $analyzeProcess = Start-Process "$HPIAPath\$HPIAExecutable" -ArgumentList "/Operation:Analyze", "/Action:List", "/Silent", "/ReportFolder:$HPIAPath\Report" -NoNewWindow -Wait -PassThru

    If (-not(Test-Path $HPIAPath\Report\*.json)) {
        Write-Host "!! ERROR: No report generated, update analysis failed"
        Write-Host "!! HP Image Assistant update process exit code: $($analyzeProcess.ExitCode)"
        Write-Host "!! Error codes and more info can be found here: $HPIAUserGuideUrl"
        exit 1
    }

    Write-Host "-- Update analysis completed successfully"
    $reqUpdates = Get-Content -Path $HPIAPath\Report\*.json | ConvertFrom-Json

    if (($reqUpdates.HPIA.Recommendations).Count -gt 0) {
        Write-Host "Updates found: $(($reqUpdates.HPIA.Recommendations).Count)"
        foreach ($update in $reqUpdates.HPIA.Recommendations) {
            Write-Host "    -- Update Name: [$($update.SoftPaqID)] $($update.Name)"
            Write-Host "       Version: $($update.RecommendationValue)"
            Write-Host "       Severity: $($update.Severity)"
            Write-Host "       Comments: $($update.Comments)"
        }
    } else {
        Write-Host "-- SUCCESS: No updates required, system is up to date"
        exit 0
    }

    # Install updates silently
    Write-Host "-- Installing updates..."
    $installProcess = Start-Process "$HPIAPath\$HPIAExecutable" -ArgumentList "/Operation:Analyze", "/Action:Install", "/Silent", "/ReportFolder:$HPIAPath\Install", "/SoftpaqDownloadFolder:$DownloadPath" -NoNewWindow -Wait -PassThru

    if (Test-Path $HPIAPath\Install\*.json) {
        $installReport = Get-Content -Path $HPIAPath\Install\*.json | ConvertFrom-Json
        Write-Host "-- Installation report found, processing results..."
        if (($installReport.HPIA.Recommendations).Count -gt 0) {
            Write-Host "----------------------------------------------------------------------------------------------------"
            foreach ($result in $installReport.HPIA.Recommendations) {
                if ($result.Remediation.Status -like "INSTALL_COMPLETED") {
                    $SuccessCount++
                    Write-Host "    -- Successfully installed: [$($result.SoftPaqID)] $($result.Name)"
                    Write-Host "       Version: $($result.RecommendationValue)"
                    Write-Host "       Release Notes: $($result.ReleaseNotesUrl)"
                } else {
                    $FailureCount++
                    Write-Host "    !! ERROR: Failed to install: $($result.Name) - Status: $($result.Remediation.Status)"
                }
            }
            Write-Host "-- HP Image Assistant update process completed with $SuccessCount successes and $FailureCount failures"
            Write-Host "----------------------------------------------------------------------------------------------------"
        }
    }

    Remove-Item $HPIAPath\Report\* -Force -ErrorAction SilentlyContinue
    Remove-Item $HPIAPath\Install\* -Force -ErrorAction SilentlyContinue

    switch ($installProcess.ExitCode) {
        0 { Write-Host "-- HP Image Assistant reported all updates installed successfully." }
        3010 { Write-Host "-- HP Image Assistant reported all updates installed successfully, reboot required to complete installation." }
        3020 { Write-Host "-- HP Image Assistant completed, but installation reported that one or more updates failed. Review the output above for details."
               Write-Host "   Note: This can sometimes be returned, even if all updates were installed successfully." }
        default {
            Write-Host "!! ERROR: HP Image Assistant installation process failed with exit code: $($installProcess.ExitCode)"
            Write-Host "   Error codes and more info can be found here: $HPIAUserGuideUrl"
            Write-Host "   HP Image Assistant process may have failed, please review the report, StdOut and StdErr and try again."
            Exit 1
        }
    }
} catch {
    Write-Host "!! ERROR: Unexpected error: $($_.Exception.Message)"
    exit 1
}