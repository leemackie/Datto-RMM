Write-Host "** Executing uninstallation - this will fail if you have not disabled tamper protection at the bare minimum **"
Write-Host "** It is recommended you remove all products from the endpoints in Sophos Central before executing the removal script **"

### Stop the 2 core services that prevent uninstallation
Write-Host "-- Stopping services"
Stop-Service "SAVService" -Force -ErrorAction Continue
Stop-Service "Sophos Autoupdate Service" -Force -ErrorAction Continue

### These are generally the remenants left over after you remove the products from Sophos Central
# Sophos Endpoint Agent
Write-Host "-- Attempting uninstallation of Sophos Endpoint Agent"
Start-Process -FilePath  "C:\Program Files\Sophos\Sophos Endpoint Agent\SophosUninstall.exe" -ArgumentList "--quiet" -Wait -ErrorAction Continue
#Start-Process -FilePath  "C:\Program Files\Sophos\Sophos Endpoint Agent\uninstallcli.exe" -Wait    #This may be the old name of the uninstaller

### Clean up the ProgramData folders
Write-Host "-- Cleaning up ProgramData\Sophos directory"
Remove-Item -Path "C:\ProgramData\Sophos" -Force -ErrorAction Continue -Recurse