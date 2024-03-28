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

# Import the Hyper-V module
Import-Module Hyper-V

# Set the threshold for snapshot age in days
$Threshold = $env:SnapshotAge

# Get all VMs on the host
$VMs = Get-VM
$SnapshotVms = @()

# Iterate through the VMs
foreach ($VM in $VMs) {
    # Get all snapshots for the VM
    $Snapshots = Get-VMSnapshot -VMName $VM.Name

    # Iterate through the snapshots
    foreach ($Snapshot in $Snapshots) {
        # Calculate the age of the snapshot
        $Age = (Get-Date) - $Snapshot.CreationTime

        # Check if the snapshot is older than the threshold
        if ($Age.Days -gt $Threshold) {
            # Write the VM name and snapshot name to the console
            Write-Host "VM: $($VM.Name) Snapshot: $($Snapshot.Name) is older than $Threshold days"
            $SnapshotVms += $Vm.Name
        }
    }
}


if ($SnapshotVms.Count -eq 0) {
    Write-DRMMStatus "No aged snaphots found"
} else {
    Write-DRMMAlert "Found aged snapshots:  $($SnapshotVms -join ', ')"
}