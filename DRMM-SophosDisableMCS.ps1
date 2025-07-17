try {
    if ($null -ne $env:TamperCode) {
        $tpOff = & "C:\Program Files\Sophos\Endpoint Defense\SEDCli.exe" -OverrideTPOff $env:TamperCode
        if ($tpOff -contains "Password is not correct") {
            Write-Host "ERROR: Tamper protection code was incorrect. Please run job/component again."
            Exit 1
        } else {
            Write-Host "Tamper Protection successfully disabled via code"
        }
    }
} catch {
    Write-Host "ERROR: Failed to confirm Tamper Protection is enabled - likely Sophos isn't installed!"
    Write-Host "Tip: Try rerunning Sophos Central installer, Sophos likely isn't installed"
    Exit 1
}

$tpStatus = & "C:\Program Files\Sophos\Endpoint Defense\SEDCli.exe" -s
if ($tpStatus -like "*enabled") {
    Write-Host "ERROR: Tamper Protection still enabled!"
    Write-Host "Please disable Tamper Protection from the Sophos Central console before retrying"
    Exit 1
}

try {
    Write-Host "Stopping Sophos MCS Agent and MCS client services"
    Stop-Service "Sophos MCS Agent" -ErrorAction Continue
    Stop-Service "Sophos MCS Client" -ErrorAction Continue
} catch {
    Write-Host "WARNING: Stopping of Sophos services failed, this may be OK if the services are already stopped or missing"
}

Write-Host "SUCCESS: Script has completed, reattempt installation of Sophos Central"