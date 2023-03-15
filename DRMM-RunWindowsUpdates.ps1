Write-Host "Executing USOClient ScanInstallWait command"
#Run USOClient to scan and download Windows Updates
usoclient.exe ScanInstallWait

Write-Host "Sleeping for 5 minutes to allow scan to complete and download to begin"
#Wait 5 minutes for scan to complete
Start-Sleep 300

Write-Host "Executing USOClient StartInstall to begin installation of outstanding updates"
#Run USOclient to install Windows Updates
usoclient.exe StartInstall