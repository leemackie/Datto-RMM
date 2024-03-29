# Improved SentinelOne monitor for Datto RMM
# Written by Lee Mackie - 5G Networks
# Version 0.2 - Updated 21/12/22 - Improved script logic
# Setup component to execute installation on failure

function Get-SentinelOneInstalled {
    $Global:installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sentinel Agent"
    $Global:sentinelagent = Get-Service -name "SentinelAgent" -ea SilentlyContinue
}

function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

function write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

Get-SentinelOneInstalled
if ($installed -eq "true") {
    Write-Host "-- SentinelOne installed"
    if ($sentinelagent.Status -eq "Running"){
        Write-Host "-- SentinelOne Agent service running"
        Write-DRMMstatus "SentinelOne installed and running"
        Exit 0
    } else {
        Write-Host "-- SentinelOne Agent service is NOT running"
        $sentinelagent | Start-Service -ea SilentlyContinue
        Get-SentinelOneInstalled
        if ($sentinelagent.Status -eq "Stopped") {
            Write-Host "-- SentinelOne Agent service is NOT running and start request failed"
            Write-DRMMAlert "SentinelOne Agent service is NOT running. Attempted restart of service failed."
            Exit 0
        }
    }
}

Write-Host "-- SentinelOne NOT installed"
Write-DRMMAlert "SentinelOne missing, review required"
Exit 1