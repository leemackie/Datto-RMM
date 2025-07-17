function write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "ALERT=$message"
    write-host '<-End Result->'
}

function write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "$message"
    write-host '<-End Result->'
}
function write-DRMMDiagnostic ($message) {
    write-host '<-Start Diagnostic->'
    write-host $message
    write-host '<-End Diagnostic->'
}

# Define the name of the Liongard agent service
$serviceName = 'roaragent.exe'
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

# Check if the service is running
if (!$service) {
        Write-DRMMAlert "Liongard service not present on system."
        Exit 1
} elseif ($service.Status -eq 'Running') {
    Write-DRMMStatus "Service $serviceName is running."
} else {
    # Attempt to start the service
    try {
        Start-Service -Name $serviceName
    } catch {
        $errorMessage = $_.Exception.Message
        Write-DRMMAlert "Failed to start service $serviceName."
        Write-DRMMDiagnostic "Error message: $errorMessage."
        Exit 1
    }

    if ((Get-Service $serviceName).Status -eq "Running") {
        Write-DRMMStatus "Service $serviceName started successfully."
    } else {
        Write-DRMMAlert "Failed to start service $serviceName."
        Exit 1
    }
}