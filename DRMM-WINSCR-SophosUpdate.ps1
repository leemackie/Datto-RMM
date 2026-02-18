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

#$epochDate = Get-Date ((Get-Date).ToUniversalTime()) -UFormat %s
#$epochDate = Get-Date
#$lastUpdate = Get-ItemPropertyValue -Path HKLM:\Software\WOW6432Node\Sophos\AutoUpdate\UpdateStatus -Name LastUpdateTime
#$updateWindow = [math]::Round($epochDate) - (New-Timespan -Minutes "$env:updateWindow").TotalSeconds
#$lastUpdateHR = (([System.DateTimeOffset]::FromUnixTimeSeconds($lastUpdate)).DateTime).ToString()
#$updadateWindowHR = (([System.DateTimeOffset]::FromUnixTimeSeconds($updateWindow)).DateTime).ToString()

#$updateWindow = (Get-Date) - (New-Timespan -Minutes "$env:updateWindow")
$updateWindow = (Get-Date) - (New-Timespan -Minutes "60")
$lastUpdate = $(Get-Date '1970-01-01 00:00:00.000Z')+([TimeSpan]::FromSeconds($(Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Sophos\AutoUpdate\UpdateStatus "LastUpdateTime").LastUpdateTime))


if ($lastUpdate -le $updateWindow) {
    Write-DRMMAlert("Last update: $lastUpdateHR older than $updadateWindowHR")
    Exit 1
} else {
    write-DRMMStatus("Last update: $lastUpdateHR UTC")
    Exit 0
}