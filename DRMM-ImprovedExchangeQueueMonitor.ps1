# Exchange Message Queue Monitor
# version 1.1
# Lee Mackie: Added diagnostic step to get queue items

function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

$maxQueueLength = $env:maxQueueLength # Max Message Queue Length

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin -ErrorAction SilentlyContinue # Exchange 2007
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue # Exchange 2010/2013

$queueLength = Get-ExchangeServer | Where-Object { $_.IsHubTransportServer -eq $true } | Get-Queue | ForEach-Object -Begin { $messageCountTotal = 0 } -Process { $messageCountTotal += $_.MessageCount } -End { $messageCountTotal }

If ( $queueLength -gt $maxQueueLength ) {
    Write-DRMMAlert "Message queue length ($queueLength) is greater than maximum message queue length ($maxQueueLength)"

    Write-Host '<-Start Diagnostic->'
    Get-ExchangeServer | Where-Object { $_.IsHubTransportServer -eq $true } | Get-Queue | Get-Message | Select-Object FromAddress,Queue,Subject
    Write-Host '<-End Diagnostic->'
    Exit 1
}