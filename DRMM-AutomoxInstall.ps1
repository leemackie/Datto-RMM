<#
.SYNOPSIS
  Downloads and installs the latest Automox Agent MSI
  It will also join the device to your organization
  and optionally a specific server group.

.DESCRIPTION
  Uses a WebClient object to download the latest Automox Agent MSI and
  install it with silent options and your specified organization access key.

.PARAMETER AccessKey
  This parameter is required to run.
  Specifies the Automox Organization this device should belong to.
  Can also be referred to as "Organization Key" or
  "Unique User Key". This is a unique identifier for your organization
  and can be found in your Automox Console in these locations:

  Devices -> Add Devices
  Settings -> API

  This must be a valid GUID to allow the script to run

  -AccessKey xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

.PARAMETER GroupName
  Specifies the Automox Server Group to move the device to upon
  joining your Organization. Note that if this isn't a top-level
  Group, then you will also need to specify the ParentGroupName
  as well

  -GroupName "My Group Name"

.PARAMETER ParentGroupName
  Specifies the Parent Group of the Server Group specified
  previously.

  -ParentGroupName "My Parent Group Name"

.NOTES
  If you prefer not to specify parameters to this scritp file,
  you may enter the values manually in the param section in the
  Setup region below.

  Released: 2019-05-08
  Author: Automox Support

.EXAMPLE
  Run this script file with at least an AccessKey specified
    Install-AxAgentMsi.ps1 -AccessKey xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

  Optionally include a Group and Parent Group Name as needed
    Install-AxAgentMsi.ps1 -AccessKey xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -GroupName "My Group Name" -ParentGroupName "My Parent Group Name"

.LINK
http://www.automox.com
#>

#region Setup
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$AccessKey = $ENV:Key
$Group = $ENV:Zone
#[Parameter(Mandatory = $false)][String]$ParentGroupName

# These values are typically fixed. But may be modified to fit a custom scenario
$installerUrl = "https://console.automox.com/installers/Automox_Installer-latest.msi"
$installerName = "AutomoxInstaller.msi"
$installerPath = "$env:TEMP\$installerName"
$agentPath = "${env:ProgramFiles(x86)}\Automox\amagent.exe"
$logFile = "$env:TEMP\AutomoxInstallandLaunch.log"

#endregion Setup

#region Functions

function Write-Log
{
    param (
        [Parameter(Mandatory = $true)][String]$line,
        [Parameter(Mandatory = $true)][String]$file,
        [Parameter(Mandatory = $false)][Switch]$Overwrite
    )
    $timeStamp = "[" + (Get-Date).ToShortDateString() + " " + ((Get-Date).ToShortTimeString()) + "]"

    if ((!(Test-Path $file)) -or ($overwrite))
    {
        Set-Content -Path $file -Value "$timeStamp $line"
    }
    else
    {
        Add-Content -Path $file -Value "$timeStamp $line"
    }
}

function Download-AxInstaller
{
    param (
        [Parameter(Mandatory = $true)][String]$installerUrl,
        [Parameter(Mandatory = $true)][String]$installerPath
    )
    $downloader = New-Object System.Net.WebClient
    try
    {
        $downloader.DownloadFile("$installerUrl", "$installerPath")
        return $true
    }
    catch
    {
        return $false
    }
}

function Set-AxServerGroup
{
    param (
        [Parameter(Mandatory = $true)][String]$Group,
        [Parameter(Mandatory = $false)][String]$ParentGroup
    )
    if ($ParentGroup)
    {
        $argList = "--setgrp `"Default Group/$ParentGroup/$Group`""
    }
    else
    {
        $argList = "--setgrp `"Default Group/$Group`""
    }
    Start-Process -FilePath $agentPath -ArgumentList "$argList" -Wait
    Start-Process -FilePath $agentPath -ArgumentList "--deregister"
}

function Install-AxAgent
{
    param (
        [Parameter(Mandatory = $true)][String]$installerPath,
        [Parameter(Mandatory = $true)][String]$AccessKey
    )
    $process = Start-Process 'msiexec.exe' -ArgumentList "/i `"$installerPath`" /qn /norestart ACCESSKEY=$AccessKey" -Wait -PassThru
    return $process.ExitCode
}

#endregion Functions


#region Operations

# Check for existing Agent Service and Running Status
# If not installed, continue
# If installed and not "Running" start the service
# If installed and "Running" do nothing
Write-Log "Checking Agent Status" $logFile -Overwrite
Write-Host "Checking Agent Status"
$service = Get-Service -Name amagent -ErrorAction SilentlyContinue

## Case 1: Agent exists and status is "Running"
if ($service.Status -eq "Running")
{
    Write-Log "Service is installed and Running. No further action needed`n Exit Code = 0" $logFile
    Write-Host "Service is installed and Running. No further action needed`n Exit Code = 0"
    Exit 0
    ## Case 2: Agent exists and status is NOT "Running"
}
elseif (($null -ne $service) -and ($service.Status -ne "Running"))
{
    Write-Log "Service is installed but not Running" $logFile
    try
    {
        # Attempt to start the Service. Exit 0 for success, Exit 1 for failure
        Start-Service -Name amagent -ErrorAction Stop
        Write-Log "Started Service, no further action needed`nExit Code = 0" $logFile
        Write-Host "Started Service, no further action needed`nExit Code = 0"
        Exit 0
    }
    catch
    {
        Write-Log "Unable to Start Agent Service, Please try to start the Automox Agent (amagent) service manually`n Exit Code = 1" $logFile
        Write-Host "Unable to Start Agent Service, Please try to start the Automox Agent (amagent) service manually`n Exit Code = 1"
        Exit 1
    }
}
else
{
    ## Case 3: Agent is not installed
    Write-Log "Agent is not present. Proceeding to Download and Install" $logFile
    Write-Host "Agent is not present. Proceeding to Download and Install"
}


# Begin File Download. Assert Success before continuing
Write-Log "Download started" $logFile
$download = Download-AxInstaller -installerUrl $installerUrl -installerPath $installerPath

if (!$download)
{
    Write-Log "Download failed. Installation stopped`n Exit Code = 1" $logFile
    Write-Host "Download failed. Installation stopped`n Exit Code = 1"
    Exit 1
}
else
{
    Write-Log "Download succeeded" $logFile
    Write-Host "Download succeeded"
}


# If successful download, then execute installer and log ExitCode
Write-Log "Starting installation of $installerName" $logFile
$exitCode = Install-AxAgent -installerPath $installerPath -AccessKey $AccessKey
Write-Log "Installation completed with Exit Code $exitCode" $logFile
Write-Host "Installation completed with Exit Code $exitCode"


# If successful installation (based on exit code), then proceed
# to set the group.
if (($exitCode -eq '0') -or ($exitCode -eq '1641') -or ($exitCode -eq '3010'))
{
    if (-not [string]::IsNullOrEmpty($parentGroupName))
    {
        Write-Log "Moving Device to Group: $groupName" $logFile
        Write-Host "Moving Device to Group: $groupName"
        Set-AxServerGroup -Group $groupName -ParentGroup $parentGroupName
    }
    elseif (-not [string]::IsNullOrEmpty($groupName))
    {
        Set-AxServerGroup -Group $groupName
    }
}
else
{
    Write-Host "Installation failed. Exit Code = 1"
    Write-Log "Installation failed. Unable to set group. Please try again" $logFile
    Exit 1
}

#endregion Operations