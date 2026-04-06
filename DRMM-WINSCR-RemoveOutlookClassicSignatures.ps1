<#
.SYNOPSIS
Datto RMM script component to clear Outlook Classic signatures from user profiles.

Written by Lee Mackie - 5G Networks

.NOTES
None

.HISTORY
Version 1.0 - Initial release
#>

$profiles = Get-ChildItem C:\users -Directory | Select-Object -ExpandProperty Name
foreach ($profileName in $profiles) {
    if (Test-Path C:\Users\$profileName\AppData\Roaming\Microsoft\Signatures) {
        Remove-Item "C:\Users\$profileName\AppData\Roaming\Microsoft\Signatures\*" -Recurse -Force -ErrorAction Continue -Verbose
    }
}