# Check the status of SMB v1, v2, and v3 - SERVERS ONLY!

function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}

function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "ALERT=$message"
    write-host '<-End Result->'
}

# Evaluate the status
if ($(Get-SmbServerConfiguration).EnableSMB1Protocol -eq $true) {
    Write-Output "Bad Status: SMB v1 is enabled. For security reasons, SMB v1 should be disabled."
    Write-DRMMAlert "BAD: SMBv1 enabled"
    Exit 1
}

Write-Output "Good Status: SMB v1 is disabled"
Write-DRMMStatus "OK: SMBv1 disabled"