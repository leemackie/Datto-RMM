## Script to find issues with RMM agent via a monitor, so it can be triaged via automation
## Author: Lee Mackie - 5G Networks
## Version: 0.1 - Pre-release

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

# Set all the required variables
$reinstall = $false
$logPath = "C:\Program Files (x86)\CentraStage\log.txt"
$folderPath = $(Get-ItemProperty "HKLM:\SOFTWARE\CentraStage" -Name "AgentFolderLocation" -ErrorAction SilentlyContinue).AgentFolderLocation
$auditPath = "$folderPath\AuditSnapshot.xml"

# Examine the log file and find any issues that we know are resolvable wiht reinstall
switch -Wildcard -File $logPath  {
"*Newton.Json*" { Write-Host "Newton.Json Issue found"; $reinstall = $true; $issue = "Newton.Json error in log"; break }
}

while ($reinstall -eq $false) {
    # Check the audit file, if it is missing then we will trigger a reinstall
    $auditFile = Get-Item $auditPath -ErrorAction SilentlyContinue

    if (!$folderPath) {
        $folderPath = (Get-Item C:\ProgramData\Centra*).FullName | Select-Object -First 1
    }

    if ($auditFile -and $auditFile.LastWriteTime -lt (Get-Date).AddDays(-7)) {
        Write-Host "Audit file @ $auditPath has not been modified in the last 7 days."
        $reinstall = $true
        $issue = "Audit XML not modified recently"
    } elseif (!$auditFile) {
        Write-Host "Audit XML file missing - trying alternative directory"
        if ($folderPath -ne "C:\ProgramData\CentraStage") {
            $folderPath = (Get-Item C:\ProgramData\Centra*).FullName | Select-Object -First 1
            $auditPath = "$folderPath\AuditSnapshot.xml"
            $auditFile = Get-Item $auditPath -ErrorAction SilentlyContinue

            if ($auditFile -and $auditFile.LastWriteTime -lt (Get-Date).AddDays(-7)) {
                Write-Host "Audit file @ $auditPath has not been modified in the last 7 days."
                $reinstall = $true
                $issue = "Audit XML not modified recently"
            } elseif (-not(Get-Item $auditPath -ErrorAction SilentlyContinue)) {
                $reinstall = $true
                $issue = "Audit XML missing"
            }
        }
    }
    Break
}

# Trigger alert condition
if ($reinstall -eq $true) {
    Write-DRMMAlert "BAD: $(Get-Date -Format "dd/MM/yyyy HH:mm") | Issue: $issue"
    Exit 1
}

Write-DRMMStatus "OK: $(Get-Date -Format "dd/MM/yyyy HH:mm") | No issues found"