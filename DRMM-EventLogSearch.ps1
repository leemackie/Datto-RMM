$detect = $env:Detect
$interval = $env:Interval
$time = $env:Time
$LogName = $env:LogName
$EventID = $env:EventID
$EventType = $env:EventType
$Comment = $env:Comment

switch ($interval) {
  "seconds" {$date = (Get-Date).addseconds(-$time)} 
  "minutes" {$date = (Get-Date).addminutes(-$time)}
  "hours" {$date = (Get-Date).addhours(-$time)}
  "days" {$date = (Get-Date).adddays(-$time)}
}

write-host (Get-Date) -ForegroundColor Green 
write-host "Checking $LogName for EventID $EventID since $date..." -ForegroundColor Green 

$search = Get-EventLog -LogName $LogName -After $date -EntryType $EventType | Where-Object {$_.EventId -eq $EventID}

if ($search) {
	if ($comment) {
		Write-Host "====== ENGINEER COMMENT ======"
		Write-Host $comment
		write-host ""
		Write-Host "====== DIAGNOSTIC INFO ======"
	}

	if ($detect -eq "true") {
		Write-Host "DETECTED"
	}
	Write-Host "$env:COMPUTERNAME - Event ID $EventID written to $LogName log within the last $time $interval"
} else {
	if ($comment) {
		Write-Host "====== ENGINEER COMMENT ======"
		Write-Host $comment
		write-host ""
		Write-Host "====== DIAGNOSTIC INFO ======"
	}
	if ($detect -eq "false") {
		Write-Host "NOT DETECTED"
	}
	Write-Host "$env:COMPUTERNAME - Event ID $EventID not written in $LogName log within the last $time $interval"
}