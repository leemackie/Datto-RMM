<#
.SYNOPSIS
Using Datto RMM, check if a APPX package is installed
Written by Lee Mackie - 5G Networks

.NOTES
Version 1.1: Moved from try catch to if statement when app not found
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

$appName = $ENV:usrPackageName
if ($ENV:usrWildcard -contains "True") {
    $appName = "*$appName*"
}

$allUserPackages = Get-AppxPackage -Name $appName -AllUsers

if (!$allUserPackages) {
    Write-DRMMAlert "BAD: Package $appName not found"
    Write-Host "Error: $_"
    Exit 1
}

if ($allUserPackages.Count -gt 1) {
    $arrPackageName = @()
    foreach ($package in $allUserPackages) {
        $arrPackageName += $package.Name
        $packageName =$arrPackageName -join ", "
    }
} else {
    $packageName = $allUserPackages.Name
}

Write-DRMMStatus "OK | Package(s) $packageName found"