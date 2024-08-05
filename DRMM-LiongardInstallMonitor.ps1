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

# Get Liongard site variables
$URL = $ENV:LiongardURL
$Key = $ENV:LiongardKey
$Secret = $ENV:LiongardSecret
$Environment = $ENV:LiongardEnvironment

# Confirm the presence of the site variables - if they don't exist kill script but don't fail to trigger the component reaction
if (!($URL) -or !($Key) -or !($Secret) -or !($Environment)) {
    Write-DRMMAlert "ERROR: Variables not set on site in DRMM - failing."
    Write-DRMMDiagnostic "!! Please refer to the onboarding guide for further information."
    Exit 0
}

# Define the name of the Liongard agent service
$serviceName = 'roaragent.exe'

# Check if the service exists
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-DRMMStatus "Liongard installed."
} else {
    Write-DRMMAlert "Liongard NOT installed."
    Write-DRMMDiagnostic "Failure will trigger immediate instllation of Liongard agent"
    Exit 1
}