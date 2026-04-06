<#
Use the following function to standardize the exit process for the script, ensuring that the end diagnostic message is always
printed regardless of the exit point in the script. This function can be called with an optional exit code parameter, defaulting
to 0 for a successful exit.

At the start of the script, you can call Write-Host "<-Start Diagnostic->" to indicate the beginning of the diagnostic output,
and then use Write-DRMMStatus, Write-DRMMAlert, and Write-DRMMDiagnostic throughout the script to log messages. Finally, call
exitScript with the appropriate exit code when you want to exit the script, ensuring that the end diagnostic message is printed.
#>

function exitScript ($exitCode = 0) {
    Write-Host "<-End Diagnostic->"
    Exit $exitCode
}

<#
Function to write a DRMM Alert for a monitor component. This will be used to trigger an alert in RMM with the specified message.
#>
function Write-DRMMAlert ($message) {
    write-host '<-Start Result->'
    write-host "Alert=$message"
    write-host '<-End Result->'
}

<#
Function to write a DRMM Status for a monitor component. This will be used to report a status of OK, WARNING, or ERROR in RMM with the specified message.
#>
function Write-DRMMStatus ($message) {
    write-host '<-Start Result->'
    write-host "STATUS=$message"
    write-host '<-End Result->'
}