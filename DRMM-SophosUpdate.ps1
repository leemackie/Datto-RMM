function write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "Status=$message"
    write-host '<-End Result->'
} 

function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

$epochDate = Get-Date ((Get-Date).ToUniversalTime()) -UFormat %s
$lastUpdate = Get-ItemPropertyValue -Path HKLM:\Software\WOW6432Node\Sophos\AutoUpdate\UpdateStatus -Name LastUpdateTime
$updateWindow = [math]::Round($epochDate) - (New-Timespan -Minutes "$env:updateWindow").TotalSeconds
$lastUpdateHR = (([System.DateTimeOffset]::FromUnixTimeSeconds($lastUpdate)).DateTime).ToString()
$updadateWindowHR = (([System.DateTimeOffset]::FromUnixTimeSeconds($updateWindow)).DateTime).ToString()

if ($lastUpdate -le $updateWindow) {
    Write-DRMMAlert("Last update: $lastUpdateHR UTC older than $updadateWindowHR")
    Exit 1
} else {
    write-DRMMStatus("Last update: $lastUpdateHR UTC")
    Exit 0
}