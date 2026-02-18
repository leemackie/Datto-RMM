$install = $env:InstallPath
$download = $env:DownloadURL
$config = $env:TelegrafConfig
$version = $env:TelegrafVersion

## Set TLS1.2 for Powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Get-Item $install -ErrorAction Ignore) {
  Write-Host "Stopping the Telegraf service"
  Get-Service Telegraf | Stop-Service -Force
  Start-Process "$install\telegraf.exe" -ArgumentList "--service uninstall" -ErrorAction SilentlyContinue

  Write-Host "Remove old files, and backup the current config"
  Remove-Item $install\telegraf.conf_orig -Force -ErrorAction SilentlyContinue
  Remove-Item $install\telegraf_latest.zip -Force -ErrorAction SilentlyContinue
  Move-Item $install\telegraf.conf $install\telegraf.conf_bak -Force
} else {
  Write-Host "Install directory does not exist, creating $install"
  New-Item $install -ItemType Directory | Out-Null
}

Write-Host "Downloading Telegraf from $download"
Invoke-WebRequest $download -UseBasicParsing -OutFile $install\telegraf_latest.zip

Write-Host "Extracting the downloaded file to $install"
Expand-Archive $install\telegraf_latest.zip -DestinationPath $install -Force

Write-Host "Moving Telegraf files to the correct locations and removing downloaded files"
Move-Item $install\telegraf-$version\telegraf.* $install -Force
Remove-Item $install\telegraf-$version -Force

Write-Host "Backing up the original config for posterity and deploying config from RMM component"
Move-item $install\telegraf.conf $install\telegraf.conf_orig -Force

if (!$config) {
  Write-Host "Deploying config from RMM component"
  Copy-Item .\telegraf.conf $install\telegraf.conf -Force
} else {
  Write-Host "Deploying config from $config"
  Copy-Item $config $install\telegraf.conf -Force
}

## Test the configuration file - if this fails the service will fail to start
Write-Host "Testing the config file - if this fails please correct and run script again"
if (Start-Process "$install\telegraf.exe" -ArgumentList "--config-directory '$install\telegraf.conf' --test" | Select-String -Pattern 'failed' -SimpleMatch) {
    Write-Error "!! Detected config failure - exiting script !!"
    Exit 1
}

Write-Host "Installing service and starting"
Start-Process "$install\telegraf.exe" -ArgumentList "--service install --service-auto-restart --config $install\telegraf.conf"
Start-Sleep -Seconds 10
Start-Process "$install\telegraf.exe" -ArgumentList "--service start"