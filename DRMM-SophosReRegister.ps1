## Re-register an incorrectly deleted device in Sophos Central
## Obviously only works for Windows.

Start-Process "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ArgumentList "-OverrideTPoff $env:TPCode" -Wait -NoNewWindow
Stop-Service "Sophos MCS Client" -Force
Remove-Item "C:\ProgramData\Sophos\Management Communications System\Endpoint\Persist\Credentials" -Force -Verbose
Remove-Item "C:\ProgramData\Sophos\Management Communications System\Endpoint\Persist\EndpointIdentity.txt" -Force -Verbose
Start-Service "Sophos MCS Client"
Start-Process "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ArgumentList "-ResumeTP $env:TPCode" -Wait -NoNewWindow
Start-Process "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ArgumentList "-Status" -Wait  -NoNewWindow