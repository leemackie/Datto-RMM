$fpath = $ENV:FPath
$hostname = $env:computername

if (!(Test-Path $fpath)) {
    Write-Host "!! Path is not accessible - quitting"
    Exit 1
}

$save = "$fpath\BatteryReport-$hostname.html"
powercfg /batteryreport /output "$save"

Write-Host "Battery report written to $save"