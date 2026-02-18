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

$version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentVersion
if ($Version -lt "6.3") {
    write-DRMMAlert "Unsupported OS. Only Server 2012R2 and up are supported - exclude this server from the monitor."
    exit 1
}

# Import the Hyper-V module
Import-Module Hyper-V

# Get all VMs on the host
$snapshots = Get-VM | Get-VMSnapshot | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$env:SnapshotAge) -and $_.snapshottype -ne "Replica" -and $_.Name -notlike "Veeam Replica*" }

# Iterate through the VMs
$SnapshotState = foreach ($Snapshot in $snapshots) {
    [PSCustomObject]@{
        VMName          = $snapshot.vmname
        'Creation Date' = $snapshot.CreationTime
        Snapshotname    = $snapshot.Name
    }
}

if (!$SnapshotState) {
    Write-DRMMStatus "No aged snaphots found"
} else {
    Write-DRMMAlert "Found aged snapshots: $($SnapshotState.VMName -join ', ')"
    Write-DRMMDiagnostic ($SnapshotState | fl)
    Exit 1
}