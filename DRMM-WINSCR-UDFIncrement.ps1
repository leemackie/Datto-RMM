# Simple script to increment a number in a UDF field
# Useful for things like reboot reminder counters

[int]$usrUDF = $env:usrUDF
if ($usrUDF -ge 1 -and $usrUDF -le 30) {

    [int]$data = (gci env: | ? {$_.Name -match "^UDF_$usrUDF$"}).Value
    $data++

    New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -PropertyType String -Name Custom$usrUDF -Value $data -Force | Out-Null
    Write-Host "NEW UDF ($usrUDF): $data"
} else {
    Write-Host "Incorrect UDF entered - failing"
    Exit 1
}