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
function Write-DRMMDiagnostic ($message) {
    write-host '<-Start Diagnostic->'
    write-host $message
    write-host '<-End Diagnostic->'
}

# Define the path to the parent folder containing versioned subfolders
$parentPath = "C:\ProgramData\CentraStage\AEMAgent\RMM.AdvancedSoftwareManagement"

# Get all subfolders in the parent folder
$subfolders = Get-ChildItem -Path $parentPath -Directory

# Find the subfolder with the largest version number
#$largestVersionFolder = $subfolders | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1

# Get all JSON files in the largest version subfolder
$jsonFiles = Get-ChildItem -Path $subFolders.FullName -Filter *.json

# Initialize an array to hold the results
$results = @()

foreach ($file in $jsonFiles) {
    # Read the content of the JSON file
    $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

    # Check if the JSON contains an exitCode key and if its value is not 0
    if ($jsonContent.PSObject.Properties.Name -contains 'exitCode' -and $jsonContent.exitCode -ne 0) {
        $errorMessage = $jsonContent.errorMessage
        # Add the result to the array
        $results += [PSCustomObject]@{
            ExitCode    = $jsonContent.exitCode
            ErrorMessage = $errorMessage
        }
    }
}

# Output the results array to the console
#$results | Format-Table -AutoSize

if ($results) {
    Write-DRMMAlert "ERROR: Failed software update found"
    Write-DRMMDiagnostic $($results | Out-String -Width 1000)
    Exit 1
} else {
    Write-DRMMStatus "OK: No software management issues found"
}