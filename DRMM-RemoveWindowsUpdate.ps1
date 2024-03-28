### Requires SearchString string variable setup in component in DRMM

$searchString = $ENV:SearchString
#$searchString = "*KB2839636*"

if ($searchString -ne $null -and $searchString -ne '') {
	Write-Host "--Search string for removal: $searchString"
	$searchString = "*$searchString*"
} else {
	Write-Host "Search string missing from job, exiting"
	Exit 1
}

if ($ENV:Reboot -eq 'null') {
	Write-Host "--Reboot: If required"
	$reboot = ""
} else {
	Write-Host "--Reboot: Skipped"
	#$reboot = "/norestart"
    $reboot = "-NoRestart"
}
try {
    $packages = Get-WindowsPackage -Online
    foreach ($p in $packages) {
        $output = Get-WindowsPackage -Online -PackageName $p.PackageName | Select-Object PackageName,Description

        if (($output.Description -like $searchString) -or ($output.PackageName -like $searchString)) {
            Write-Host "Removing  $($output.PackageName) -- $($output.Description)"
            #dism /Online /Remove-Package /PackageName:$output.PackageName $reboot
            Remove-WindowsPackage -Online -PackageName $output.PackageName -Verbose $reboot
        }
    }
} catch {
    Write-Host "Script failed!" -ForegroundColor Red
    Write-Host $_
}

Write-Host "Script complete, check output to confirm package was successfull removed and if so, schedule a reboot if required"
Write-Host "If there is no removal information, nothing was found"