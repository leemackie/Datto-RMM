<#
.SYNOPSIS
Datto RMM monitor component to monitor the length of the message queue on an Exchange server and report status back to the Datto RMM console.
Alert status generated if message queue length exceeds defined threshold.

Written by Lee Mackie - 5G Networks

.NOTES
None

.HISTORY
Version 1.0 - Initial release
Version 1.1 - Added diagnostic step to get queue items
Version 1.2 - Updated to use new DRMM alert and status output format, enhanced output of message items when alert generated
#>

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

$maxQueueLength = $env:maxQueueLength # Max Message Queue Length

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin -ErrorAction SilentlyContinue # Exchange 2007
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue # Exchange 2010/2013

$queueLength = Get-ExchangeServer | Where-Object { $_.IsHubTransportServer -eq $true } | Get-Queue | ForEach-Object -Begin { $messageCountTotal = 0 } -Process { $messageCountTotal += $_.MessageCount } -End { $messageCountTotal }

If ( $queueLength -gt $maxQueueLength ) {
    Write-DRMMAlert "BAD: Queue length > $maxQueueLength [$queueLength]"
    $messageItems = Get-ExchangeServer | Where-Object { $_.IsHubTransportServer -eq $true } | Get-Queue | Get-Message | Select-Object -Property Directionality, OriginalFromAddress, Subject, Status, Size, DateReceived, Queue, LastError
    $messageItems
    Write-Host "--------------------------------------------"
    Write-Host "Queue(s) Summary Table:"
    $messageItems | ft Directionality, OriginalFromAddress, DateReceived, Subject -AutoSize
    Write-Host "Enahnced output available above summary table"
    exitScript 1
} else {
    Write-DRMMStatus "OK: Message queue length [$queueLength]"
}
exitScript