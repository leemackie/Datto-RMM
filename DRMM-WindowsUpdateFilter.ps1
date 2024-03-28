Write-Host "### Running Windows Update component"
Write-Host "# Searching for updates..."
$filter = $ENV:Filter
$updateSession = new-object -com "Microsoft.Update.Session"
$updateSearcher = $updateSession.CreateupdateSearcher()
$searchResult = $updateSearcher.Search("IsInstalled=0 and isHidden=0")

if ($searchResult.Updates.Count -eq 0) {
    Write-Host "# WARNING: No outstanding updates on this machine."
    Exit 0
} else {
    $updatesToDownload = new-object -com "Microsoft.Update.UpdateColl"
    foreach ($update in $searchResult.Updates) {
        if  ($update.Title -like "*$filter*") {
            Write-Host "-- Adding $($update.Title) for download"
            $updatesToDownload.Add($update) | out-null
        }
    }

    if ($null -eq $updatesToDownload) {
        Write-Host "# FAILED: No updates found according to the $filter filter - run this again with a different filter or investigate further"
        Exit 1
    }
}

$i = 0
Write-Host "- Downloading updates..."
$downloader = $updateSession.CreateUpdateDownloader()
$downloader.Updates = $updatesToDownload
$downloader.Download()
Write-Host "- List of downloaded updates:"
$i = 0
foreach ($update in $updatesToDownload.Updates){
    $i++
    if ( $update.IsDownloaded ) {
        Write-Host $i">" $update.Title "(downloaded)"
    } else  {
        Write-Host $i">" $update.Title "(not downloaded)"
    }
}

$updatesToInstall = new-object -com "Microsoft.Update.UpdateColl"
Write-Host "- Creating collection of downloaded updates to install..."
foreach ($update in $searchResult.Updates){
    if ( $update.IsDownloaded -and $update.Title -like "*$filter*" ) {
        $updatesToInstall.Add($update) | out-null
    }
}

if ( $updatesToInstall.Count -eq 0 ) {
    Write-Host "# FAILED: All updates failed to download - please investigate and try again."
    Exit 1
} else  {
    Write-Host "- Installing" $updatesToInstall.Count "updates..."
    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall
    $installationResult = $installer.Install()
    if ( $installationResult.ResultCode -eq 2 ) {
        Write-Host "# SUCCESS: All updates applied successfully"
    } else  {
        Write-Host "# FAILED: Some updates failed to install - please investigate and try again."
    }

    $installer.updates | Format-Table -autosize -property Title, EulaAccepted, @{label = 'Result';
    expression = {$ResultCode[$installationResult.GetUpdateResult($Global:Counter++).resultCode] }
}

    if ( $installationResult.RebootRequired ) {
        Write-Host "# WARNING: One or more updates require a reboot to complete. Please scheduled a reboot as necessary."
    } else {
        Write-Host "# SUCCESS: No reboot required to complete."
    }
}