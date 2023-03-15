# Scan the 2 known temporary directories for old Windows 10 FU files and delete them if present

Write-Host "Checking $env:HOMEDRIVE\`$WINDOWS.~BT"
If (Test-Path "$env:HOMEDRIVE\`$WINDOWS.~BT") {
    Remove-Item "$env:HOMEDRIVE\`$WINDOWS.~BT" -Recurse -Force
    Write-Host "$env:HOMEDRIVE\`$WINDOWS.~BT deleted!" -ForegroundColor Yellow
} else {
    Write-Host "$env:HOMEDRIVE\`$WINDOWS.~BT not found"
}
 
Write-Host "Checking $env:HOMEDRIVE\`$WINDOWS.~WS"
If (Test-Path "$env:HOMEDRIVE\`$Windows.~WS") {
    Remove-Item "$env:HOMEDRIVE\`$Windows.~WS" -Recurse -Force
    Write-Host "$env:HOMEDRIVE\`$Windows.~WS deleted!" -ForegroundColor Yellow
} else {
    Write-Host "$env:HOMEDRIVE\`$WINDOWS.~WS not found"
}