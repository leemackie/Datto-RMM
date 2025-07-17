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

function Write-DRMMDiagnostic ($messages) {
    write-host '<-Start Diagnostic->'
    foreach ($Message in $Messages) { $Message }
    write-host '<-End Diagnostic->'
}

$thumbprint = $ENV:CertThumbprint
$date = Get-Date
$date = $date.ToUniversalTime()
$cert = Get-ChildItem -path "Cert:\*$thumbprint" -Recurse
$expired = $false

if (!$cert) {
    Write-DRMMAlert "ERROR: Certificate not found!"
    Exit 1
}

foreach ($c in $cert) {
    Write-Host $date " -- " $c.NotAFter.ToUniversalTime()
    if ($date -gt $c.NotAfter.ToUniversalTime()) {
        $expired = $true
    }
}

if ($expired -eq $true -and $ENV:ExpiryMonitor -eq "True") {
    Write-DRMMAlert "ERROR: Certificate found but expired!"
    Write-DRMMDiagnostic $cert
    Exit 1
} elseif ($expired -eq $true) {
    Write-DRMMStatus "WARNING: Certificate found but expired!"
} else {
    Write-DRMMStatus "OK: Certificate found and valid!"
}