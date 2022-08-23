if ($ENV:UDF_30) {
    Write-Host "OK: Already targetted - exiting."
    Write-Host $ENV:UDF30
    exit
}

$version = Get-WmiObject -class Win32_OperatingSystem
$os = (Get-WmiObject -class Win32_OperatingSystem).Caption

if ($os -contains 'Windows 10' -and $version.BuildNumber -lt $ENV:Version) {
    Write-Host "OOS: Windows 10 out of support version detected."
    Write-Host $os " - " $version
    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v Custom30 /t REG_SZ /d "W10_Targetted" /f
} else {
    Write-Host "OK: Windows in support - nothing required."
    Write-Host $os " - " ($version.BuildNumber)
}