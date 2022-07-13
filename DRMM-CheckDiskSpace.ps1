#Requires -Version 4
function write-DRMMDiag ($messages) {
    write-host '<-Start Diagnostic->'
    foreach ($Message in $Messages) { $Message }
    write-host '<-End Diagnostic->'
} 

function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

if ([Environment]::OSVersion.Version -lt (New-Object 'Version' 6,2)) {
    write-DRMMAlert "Unsupported OS detected"
    #exit 0
}
    

####### Disk settings
$DiskSettings = [PSCustomObject]@{
    LargeDiskPercent     = $ENV:LargeDiskPercent
    LargeDiskAbsolute    = $ENV:LargeDiskAbsolute
    LargeDisksThreshold  = $ENV:LargeDiskThreshold
    MediumDiskPercent    = $ENV:MediumDiskPercent
    MediumDiskAbsolute   = $ENV:MediumDiskAbsolute
    MediumDiskThreshold  = $ENV:MediumDiskThreshold
    SmallDiskThreshold   = $ENV:SmallDiskThreshold
    SmallDiskPercent     = $ENV:SmallDiskPercent
    SmallDiskAbsolute    = $ENV:SmallDiskAbsolute
    ExcludedDriveLetters = (Get-Item "ENV:\UDF_$ENV:ExcludeUDF").value -split ','
}
####### Disk settings
try {
    $Volumes = get-volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveLetter -notin $DiskSettings.ExcludedDriveLetters -and $_.DriveType -eq 'fixed' }   
}
catch {
    write-DRMMAlert "Could not get volumes: $($_.Exception.Message)"
    exit 1
}
$DisksOutOfSpace = Foreach ($Volume in $Volumes) {
    if ($volume.size -gt $DiskSettings.LargeDisksThreshold) { $percent = $DiskSettings.LargeDiskPercent; $absolute = $DiskSettings.LargeDiskAbsolute }
    if ($volume.size -lt $DiskSettings.LargeDisksThreshold) { $percent = $DiskSettings.MediumDiskPercent; $absolute = $DiskSettings.MediumDiskAbsolute }
    if ($volume.size -lt $DiskSettings.MediumDiskThreshold) { $percent = $DiskSettings.MediumDiskPercent; $absolute = $DiskSettings.MediumDiskAbsolute }
    if ($volume.size -lt $DiskSettings.SmallDiskThreshold) { $percent = $DiskSettings.SmallDiskPercent; $absolute = $DiskSettings.SmallDiskAbsolute }
 
    if ($volume.SizeRemaining -lt $absolute -or ([Math]::Round(($volume.SizeRemaining / $volume.Size * 100), 0)) -lt $percent ) {
        [PSCustomObject]@{
            Hostname            = $env:Computername
            DiskName            = $Volume.FileSystemLabel
            DriveLetter         = $volume.DriveLetter
            Size                = [math]::Round($volume.Size/1GB,2)
            SizeRemaining       = [math]::Round($volume.SizeRemaining/1GB,2)
            PercentageRemaining = [Math]::Round(($volume.SizeRemaining / $volume.Size * 100), 0)
            ThresholdTrigger    = "less than $absolute or less than $($percent)% left"
        } 
    }
}
 
if ($DisksOutOfSpace) {
    write-DRMMAlert "Some disks are running low on space. Please investigate"
    write-DRMMDiag $DisksOutOfSpace
    #exit 1
}
else {
    write-DRMMAlert "Healthy - No disks running out of space"
}