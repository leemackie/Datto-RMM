try {
    function UpdateOffice {
        param($KBNumber)

        $UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
        $Searcher = New-Object -ComObject Microsoft.Update.Searcher
        $Session = New-Object -ComObject Microsoft.Update.Session

        $InstalledCount = $Searcher.GetTotalHistoryCount()
        $Searcher.QueryHistory(0, $InstalledCount) | Select-Object Title | ForEach-Object {
            if ($_ | Select-String $KBNumber -SimpleMatch) {
                Write-Output "Update already installed."
                Exit 0
            }
        }
        Write-Host "Update not found on machine, proceeding with update"

        $results = $searcher.search("IsInstalled = 0")
        $Results.Updates |
        ForEach-Object {
            if ($_.Title | Select-String "$KBNumber" -SimpleMatch) {
                #Write-Output $_
                Write-Output "Found "($_.Title)""
                $UpdateCollection.Add($_) | Out-Null
            } else {
                Write-Output "Office Update not found from Windows Update"
                Write-Output ($_.Title)
                Exit 1
            }
        }

        $Downloader = $Session.CreateUpdateDownloader()
        $Downloader.Updates = $UpdateCollection
        $Downloader.Download()

        $Installer = New-Object -ComObject Microsoft.Update.Installer
        $Installer.Updates = $UpdateCollection
        $Installer.Install()
    }

    $365CurrentChanVer = "16130.20306"
    $365MonthlyEntChanVer = "16026.20238"
    $365SemiAnnChanVer = "15601.20578"
    $2013Ver = "15.0.5537.1000"
    $2013KB = "KB5002198"
    $2016Ver = "16.0.5387.1000"
    $2016KB = "KB5002254"
    $UDF = "Custom23"
    $M365x32Key = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $M365x64Key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
    $O2016x32Key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\ProductVersion"
    $O2016x64Key = "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\ProductVersion"


    if (Test-Path $M365x32Key){
        $OfficeVersionX32 = (Get-ItemProperty -Path $M365x32Key -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Select-Object -ExpandProperty VersionToReport
    } elseif (Test-Path $M365x64Key){
        $OfficeVersionX64  = (Get-ItemProperty -Path $M365x64Key -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Select-Object -ExpandProperty VersionToReport
    } elseif (Test-Path $O2016x32Key){
        $O2016OfficeVersionX32 = (Get-ItemProperty -Path $O2016x32Key -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Select-Object -ExpandProperty LastProduct
    } elseif (Test-Path $O2016x64Key){
        $O2016OfficeVersionX64 = (Get-ItemProperty -Path $O2016x64Key -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Select-Object -ExpandProperty LastProduct
    }

    if ($OfficeVersionX32 -ne $null -and $OfficeVersionX64 -ne $null) {
        $Office365Version = "Both x32 version ($OfficeVersionX32) and x64 version ($OfficeVersionX64) installed!"
    } elseif ($OfficeVersionX32 -eq $null -or $OfficeVersionX64 -eq $null) {
        $Office365Version = $OfficeVersionX32 + $OfficeVersionX64
    }

    if ($Office365Version) {
        $OfficeVersionMain = $Office365Version.Split(".")[0]
        $OfficeVersionSub1  = $Office365Version.ToString().Replace("16.0.","")

        Switch  ($OfficeVersionMain) {
            16      {
                        $MSOffice = "Office 365 (Version $($OfficeVersionSub1))"
                    }
            default {$MSOffice = $Office365Version}
            $null   {$MSOffice = "No Office 365 installed."}
        }

        Write-Output $MSoffice
    }

    if ($O2016OfficeVersionX32 -ne $null -or $O2016OfficeVersionX64 -ne $null) {
        $OfficeVersion = $O2016OfficeVersionX32 + $O2016OfficeVersionX64
        $OfficeVersionMain = $OfficeVersion.Split(".")[0]
    }

    if ($OfficeVersion) {
        Switch  ($OfficeVersionMain) {
                16      {$MSOffice ="Office 2016 ($OfficeVersion)" }
                $null   {$MSOffice = "No Office installed."}
        }

        Write-Output $MSoffice
    }

    if ($OfficeVersionSub1) {
        $subStr = $OfficeVersionSub1.Substring(0,3)
        switch ($substr) {
            161 {if ($OfficeVersionSub1 -lt $365CurrentChanVer) {
                    Start-Process -FilePath "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" -ArgumentList "/update user displaylevel=false forceappshutdown=false updatepromptuser=false"
                    Write-Output "Out of date version found - Current channel - triggered update to $365CurrentChanVer"
                    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v $UDF /t REG_SZ /d "CVE-2023-23397" /f
                } else {
                    Write-Output "Current version $OfficeVersionSub1 matches latest version $365CurrentChanVer"
                }
                }
            160 {if ($OfficeVersionSub1 -lt $365MonthlyEntChanVer) {
                Start-Process -FilePath "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" -ArgumentList "/update user displaylevel=false"
                Write-Output "Out of date version found - Monthly (Enterprise) channel - triggered update to $365MonthlyEntChanVer"
                REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v $UDF /t REG_SZ /d "CVE-2023-23397" /f
                } else {
                    Write-Output "Current version $OfficeVersionSub1 matches latest version $365MonthlyEntChanVer"
                }
                }
            156 {if ($OfficeVersionSub1 -lt $365SemiAnnChanVer) {
                Start-Process -FilePath "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" -ArgumentList "/update user displaylevel=false"
                Write-Output "Out of date version found - Semi Annual (Enterprise) channel - triggered update to $365SemiAnnChanVer"
                REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v $UDF /t REG_SZ /d "CVE-2023-23397" /f
                } else {
                    Write-Output "Current version $OfficeVersionSub1 matches latest version $365SemiAnnChanVer"
                }
                }
            default {
                Write-Output "Office already up to date - $OfficeVersionSub1"
                Exit 0
            }
        }
    } elseif ($OfficeVersion) {
        switch ($officeVersionMain) {
            15 {if ($officeVersion -lt $2013Ver) {
                Write-Output "Out of date 2013 version found - triggered update to $2013Ver"
                UpdateOffice -KBNumber $2013KB
                REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v $UDF /t REG_SZ /d "CVE-2023-23397" /f
            }
        }
            16 {if ($OfficeVersion -lt $2016Ver) {
                Write-Output "Out of date 2016 version found - triggered update to $2016Ver"
                UpdateOffice -KBNumber $2016KB
                REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v $UDF /t REG_SZ /d "CVE-2023-23397" /f
            }
        }
        default {
            Write-Output "Office already up to date - $OfficeVersion"
            Exit 0
        }
        }
    } else {
        Write-Output "Something went wrong triggering the update procedure!"
        Write-Output "Maybe office isn't installed?"
        Write-Output "Please review output and run again"
    }
} catch {
    Write-Output "Script failed!"
    Write-Output $_
    Exit 1
}