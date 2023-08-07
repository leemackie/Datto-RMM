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
function write-DRMMDiagnostic ($message) {
    write-host '<-Start Diagnostic>'
    write-host $message
    write-host '<-End Diagnostic>'
}

# Define the name of the Liongard agent service
$serviceName = 'roaragent.exe'

# Check if the service is running
if ((Get-Service -Name $serviceName).Status -eq 'Running') {
    Write-DRMMStatus "Service $serviceName is running."
} else {
    # Attempt to start the service
    try {
        Start-Service -Name $serviceName -ErrorAction Stop
        Write-DRMMStatus "Service $serviceName started successfully."
    } catch {
        $errorMessage = $_.Exception.Message
        Write-DRMMAlert "Failed to start service $serviceName."
        Write-DRMMDiagnostic "Error message: $errorMessage."
    }
}