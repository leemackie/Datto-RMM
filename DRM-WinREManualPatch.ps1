# Windows Recovery Environment - manual update procedure - 2025-04 patch
# Written by Lee Mackie - 5G Networks
# Version 1.0: Initial release

switch ($env:OsSelection) {
    "W1022" { $packagePath = "$PWD\w10-22h2-x64.cab"; $newVer = 5728 }
    "W1122" { $packagePath = "$PWD\w11-22h2-x64.cab"; $newVer = 5262 }
    "W1123" { $packagePath = "$PW\w11-23h2-x64.cab"; $newVer = 5262 }
    "W1124" { $packagePath = "$PWD\w11-24h2-x64.cab"; $newVer = 3911 }
}
$mountDir = "C:\WinREMount"
if (!(Get-Item $mountdir -ErrorAction SilentlyContinue)) {
    Write-Host "# Creating $mountDir"
    New-Item $mountDir -ItemType Directory | Out-Null
}

# Install WinRE update
Write-Host "# Mounting WinRE image"
ReAgentC.exe /mountre /path $mountDir

# Adding a sleep in as we've seen issues with AV scanning the update packages causing mount issues
Start-Sleep 60

Write-Host "# Adding update package $packagePath"
Dism /Add-Package /Image:$mountDir /PackagePath:$packagePath
Dism /image:$mountDir /cleanup-image /StartComponentCleanup /ResetBase

Write-Host "# Dismount WinRE image, and preparing for Bitlocker"
ReAgentC.exe /unmountre /path $mountDir /commit
reagentc /disable
reagentc /enable

# Check WinRE Version is correct
Write-Host "# Checking WinRE version"
$WinRELocation = (reagentc /info | Select-String "Windows RE location")
$WinRELocation = $WinRELocation.ToString().Split(':')[-1].Trim()
dism /Mount-Image /ImageFile:"$WinRELocation\winre.wim" /Index:1 /MountDir:$mountDir
$filePath = "$mountDir\Windows\System32\winpeshl.exe"
$WinREVersion = (Get-Item $filePath).VersionInfo.FileVersionRaw.Revision
dism /Unmount-Image /MountDir:$mountDir /Discard

# Remove the mount directory we created once finished
Write-Host "# Removing $mountDir"
Remove-Item $mountDir -Force

Write-Host "# Update process completed"
if ($newVer -ne $WinREVersion) {
    Write-Host "!! Version numbers do not match - update may not have completed as expected. Please review output and operating system for cause."
    Write-Host "# Current version: $winREVersion"
    Write-Host "# Expected version: $newVer"
    #Exit 1
} else {
    Write-Host "### Version numbers match - update completed successfully."
}