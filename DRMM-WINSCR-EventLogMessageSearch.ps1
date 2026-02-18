$Source = $ENV:Source
$Message = $ENV:Message
$LogName = $ENV:LogName

try {
  $result = Get-EventLog -Source $source -LogName $LogName -Message $Message | Select-Object TimeGenerated,Message
} catch { }

if ($result) {
  Write-Host "-- SUCCESS: Entries found - output below"
  Write-Host $result | Format-Table Wrap
} else {
  Write-Host "-- WARNING: No log entries found according to your search parameters"
  Write-Host "- Source: $Source"
  Write-Host "- Message: $Message"
  Write-Host "- Log Name: $LogName"
}