<#
.SYNOPSIS
Using Datto RMM, check Windows defender status. Intended to use alongside your thirdparty AVto ensure that Defender on servers is not running
and thus not causing any issues.
https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-compatibility?view=o365-worldwide#antivirus-protection-without-defender-for-endpoint

Either alert or write status dependant on the status.
Written by Lee Mackie - 5G Networks

.NOTES
Version 1.0 - Initial release
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

if ($(Get-MpComputerStatus).AMRunningMode -eq "Normal") {
    Write-DRMMAlert "BAD: Defender running"
    Exit 1
} else {
    Write-DRMMStatus "OK: Defender not running"
}