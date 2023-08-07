if ($ENV:UDF_30) {
    if ($ENV:UDF_30 -like "~0,255" -Or $ENV:UDF_30 -eq " ") {
        New-ItemProperty -Path "HKLM:\Software\CentraStage" -Name "Custom30" -Value "$null" -PropertyType "string"
        Start-Sleep 300
    } else {
        Write-Host "OK: Already targeted - exiting."
        Write-Host $ENV:UDF_30
        exit
    }
}

$version = Get-WmiObject -class Win32_OperatingSystem
$os = (Get-WmiObject -class Win32_OperatingSystem).Caption

if ($os -like '*Windows 10*' -and $version.BuildNumber -lt $ENV:Version) {
    Write-Host "OOS: Windows 10 out of support version detected."
    Write-Host $os " - " $version.BuildNumber
    New-ItemProperty -Path "HKLM:\Software\CentraStage" -Name "Custom30" -Value "W10_Targeted" -PropertyType "string"
} else {
    Write-Host "OK: Windows in support - nothing required."
    Write-Host $os " - " $version.BuildNumber
}