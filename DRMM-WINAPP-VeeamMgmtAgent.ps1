<#
.SYNOPSIS
Veeam Service Provider Management Agent installation script.

Written by Lee Mackie - 5G Networks

.HISTORY
Version 1.1 - 18/09/25 - Simplified script, updated installation parameters and logging
Version 1.0 - 24/06/20 - Initial script creation
#>

$veeamURL = $ENV:VeeamURL+":6180:0"

$installArgs = '/qn /l*v C:\ProgramData\CentraStage\Temp\VACAgentSetup.log ACCEPT_THIRDPARTY_LICENSES="1" ACCEPT_EULA="1" ACCEPT_REQUIRED_SOFTWARE="1" ACCEPT_LICENSING_POLICY="1"'
$install = Start-Process ".\ManagementAgent.exe" -ArgumentList $installArgs -Wait -PassThru

if ($install.ExitCode -ne 0 -and $install.ExitCode -ne 3010) {
    Write-Host "!! FAILURE: Veeam Management Agent installation failed with exit code $($install.ExitCode)"
    Exit 1
} else {
    Write-Host "-- SUCCESS: Veeam Management Agent installation completed successfully with exit code $($install.ExitCode)"
}

Set-Location -Path HKLM:\Software\Veeam\VAC\Agent
$currentReg = (Get-ItemProperty -Path . -Name CloudGatewayAddress).CloudGatewayAddress

Set-ItemProperty -Path . -Name "CloudGatewayAddress" -Value $null
Set-ItemProperty -Path . -Name "CertificateThumbprint" -Value $null
Set-ItemProperty -Path . -Name "CloudGatewayAddressManual" -Value $VeeamURL

Stop-Service -Name "VeeamManagementAgentSvc" -Force
Start-Service -Name "VeeamManagementAgentSvc"

Start-Sleep -Seconds 60

$newReg = (Get-ItemProperty -Path . -Name CloudGatewayAddressManual).CloudGatewayAddressManual

Write-Host "-- Old value: $currentReg"
Write-Host "-- New value: $newReg"