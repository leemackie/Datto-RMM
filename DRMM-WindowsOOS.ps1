#requires -Version 5.0
$computerinfo = Get-ComputerInfo -Property "OsbuildNumber","OSName"
$build = $computerinfo.OsBuildNumber
$os = $computerinfo.OSname
$UDF30 = $ENV:UDF_30

if ($UDF30) {
    if ($ENV:Version -eq "W10" -and $os -like '*Windows 10*' -and $UDF30 -like "*W11*") {
        Write-Host "WARNING: Found unexpected data in UDF 30, clearing field."
        Write-Host "UDF30 contents: $UDF30"
        New-ItemProperty -Path "HKLM:\Software\CentraStage" -Name "Custom30" -Value "$null" -PropertyType "string" | Out-Null
        $UDF30 = $null
        Start-Sleep 120
    } elseif ($ENV:Version -eq "W11" -and $os -like '*Windows 11*' -and $UDF30 -like "*W10*") {
        Write-Host "WARNING: Found unexpected data in UDF 30, clearing field."
        Write-Host "UDF30 contents: $UDF30"
        New-ItemProperty -Path "HKLM:\Software\CentraStage" -Name "Custom30" -Value "$null" -PropertyType "string" | Out-Null
        $UDF30 = $null
        Start-Sleep 120
    } elseif ($UDF30 -like "~0,255" -Or $UDF30 -eq " ") {
        Write-Host "WARNING: Found unexpected data in UDF 30, clearing field."
        Write-Host "UDF30 contents: $UDF30"
        New-ItemProperty -Path "HKLM:\Software\CentraStage" -Name "Custom30" -Value "$null" -PropertyType "string" | Out-Null
        Start-Sleep 120
    }

    if ($UDF30 -like "*NotifyDay*" -Or $UDF30 -like "*Notified*" -Or $UDF30 -like "*Targeted*" -Or $UDF30 -like "*Bypass*") {
        Write-Host "OK: Already targeted or bypassed - exiting."
        Write-Host "UDF30 contents: $UDF30"
        Write-Host "----------"
        Write-Host $os
        Write-Host "Current Build: $build"
        Write-Host "Minimum Build: $ENV:Build"
        exit
    }
}

if (($os -like '*Windows 11*' -and $build -lt $ENV:Build -and $ENV:Version -eq "W11") -Or ($os -like '*Windows 10*' -and $build -lt $ENV:Build -and $ENV:Version -eq "W10")) {
    Write-Host "WARNING: Windows current build is out of support."
    New-ItemProperty -Path "HKLM:\Software\CentraStage" -Name "Custom30" -Value $ENV:Version"_Targeted" -PropertyType "string" | Out-Null
    $target = $true
}

if (!$target) {
    Write-Host "OK: Script not targeting this version of Windows."
}

Write-Host "----------"
Write-Host "Current OS: $os"
Write-Host "Current Build: $build"
Write-Host "Minimum OS/Build: $ENV:Version - $ENV:Build"