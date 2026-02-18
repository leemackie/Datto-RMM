$Filter = $ENV:Filter

Write-Host "### Running Windows Update with filtering component"
Write-Host "# Searching for updates..."
Write-Host "# Filter: $filter"

$Criteria = "IsInstalled=0 and isHidden=0"

$resultcode = @{
    0 = "Not Started";
    1 = "In Progress";
    2 = "Succeeded";
    3 = "Succeeded With Errors";
    4 = "Failed" ;
    5 = "Aborted"
}

$updateSession = New-Object -com "Microsoft.Update.Session"
$updatesToDownload = New-Object -com "Microsoft.Update.UpdateColl"

$updates = $updateSession.CreateupdateSearcher().Search($criteria).Updates

if ($Updates.Count -eq 0) {
    "-- WARNING: There are no outstanding updates."
    Exit 0
} else {
    Write-Host "-- Found $($updates.Count) updates"

    $downloader = $updateSession.CreateUpdateDownloader()
    $i = 0
    foreach ($update in $updates) {
        if  ($update.Title -like "*$filter*") {
            Write-Host "-- Adding $($update.Title) for download"
            $update.AcceptEula()
            $output = $updatesToDownload.Add($update) #| out-null
            $i++
        }
    }

    if ($i -eq 0) {
        Write-Host "-- WARNING: No updates match the filter $filter"
        Exit 0
    } else {
        Write-Host "-- Total updates queued for download: $i"
    }
    try {
        $downloader.Updates = $updatesToDownload #| Out-Null

        $Result = $downloader.Download()
    } catch {
        Write-Host "FAILED: Something went wrong downloading - see error message below."
        Write-Host $_
        Exit 1
    }
    #if (($Result.Hresult -eq 0) -or (($result.resultCode -eq 2) -or ($result.resultCode -eq 3)) ) {
    Write-Host "-- Installing updates"
        $updatesToInstall = New-object -com "Microsoft.Update.UpdateColl"

        $updatesToDownload | Where-Object {$_.isdownloaded} | foreach-Object {$updatesToInstall.Add($_) | out-null }
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $installationResult = $installer.Install()
        $Global:counter = -1
        $installer.updates | Format-Table -autosize -property Title, EulaAccepted, @{label = 'Result';
            expression = {$ResultCode[$installationResult.GetUpdateResult($Global:Counter++).resultCode] }
        }
    #}
}

Write-Host "SUCCESS: Script has completed successfully."