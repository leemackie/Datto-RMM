<# windows toast-style notifications :: REDUX :: build 11/seagull, january 2026 :: WJmKStqugMc
   script variables: usrHeroImgURL/str :: usrMessageTitle/str :: usrMessageContent/str :: usrShowRestart/str :: usrAlert/Bln
   thanks: lee m., danny g., datto community :: kelvin tegelaar :: stephanie r., datto labs

   this script, like all datto RMM Component scripts unless otherwise explicitly stated, is the copyrighted property of Datto, Inc.;
   it may not be shared, sold, or distributed beyond the Datto RMM product, whole or in part, even with modifications applied, for
   any reason. this includes on reddit, on discord, or as part of other RMM tools. PCSM and VSAX stand as exceptions to this rule.

   the moment you edit this script it becomes your own risk and support will not provide assistance with it.#>

    #region 5GN VARIABLES AND EDITS -------------------------------------------------------

<# If you update this script, ensure you replicate any 5G Networks specific changes below.
   There is a section at the end of the script labelled '5G NETWORKS REMINDER EDITS BY LEE M' where
   you will find the necessary code to update the reboot reminder count and timestamp in the registry.

    Failure to replicate these changes will result in the reboot reminder toast message not functioning. #>

$env:usrMessageTitle = "Reboot Required"
$env:usrMessageContent = "Your device requires a reboot to complete important Windows updates. Please save your work and restart at your earliest convenience."
$env:usrShowRestart = "true" # False boolean value to show/hide 'Restart now' option
$env:usrHeroImgURL = "5GN_Logo_364px.png" # Attached to the component in RMM
$env:Alert = "true" # False boolean value to force toast past DnD status in Windows
$varRRemCount = $ENV:usrRebootReminderCount
$varRegPath = "HKLM:\SOFTWARE\CentraStage\"
$varRegRReminder = "5GNRebootReminder"
$varRegRReminderCount = "5GNRebootReminderCount"

try {
    $env:usrMessageContent += "`nThis is reminder number $([int]$(Get-ItemPropertyValue -Path $varRegPath -Name $varRegRReminderCount) + 1)."
    if ($varRRemCount -gt 0) {
        $env:usrMessageContent += "`nYour device will be rebooted after $varRRemCount reminders."
    }
} catch {}

   #endregion 5GN VARIABLES AND EDITS ----------------------------------------------------


write-host "Send a branded 'toast' Notification  - modified 5GN version by Lee M"
write-host "============================================"
write-host "- Message title: $env:usrMessageTitle"
write-host "- Message body:  $env:usrMessageContent"

#region Functions & variables ---------------------------------------------------------

$varTime=([DateTime]::Now.AddMinutes(2)).ToString("HH:mm")
$varEpoch=((Get-Date -UFormat %s) -split '\W')[0]

#proxy not-a-function code, build 3/seagull :: copyright datto, inc.
if (([IntPtr]::size) -eq 4) {
    [xml]$varPlatXML= get-content "$env:ProgramFiles\CentraStage\CagService.exe.config" -ea 0
} else {
    [xml]$varPlatXML= get-content "${env:ProgramFiles(x86)}\CentraStage\CagService.exe.config" -ea 0
}
try {
    $script:varProxyLoc= ($varPlatXML.configuration.applicationSettings."CentraStage.Cag.Core.AppSettings".setting | ? {$_.Name -eq 'ProxyIp'}).value
    $script:varProxyPort=($varPlatXML.configuration.applicationSettings."CentraStage.Cag.Core.AppSettings".setting | ? {$_.Name -eq 'ProxyPort'}).value
    if ($($varPlatXML.configuration.applicationSettings."CentraStage.Cag.Core.AppSettings".setting | ? {$_.Name -eq 'ProxyType'}).value -gt 0) {
        if ($script:varProxyLoc -and $script:varProxyPort) {
            $useProxy=$true
        }
    }
} catch {
    $host.ui.WriteErrorLine(": NOTICE: Device appears to be configured to use a proxy server, but settings could not be read.")
}

function downloadFile { #downloadFile, build 32b/seagull :: copyright datto, inc.
    param (
        [parameter(mandatory=$false)]$url,
        [parameter(mandatory=$false)]$whitelist,
        [parameter(mandatory=$false)]$filename,
        [parameter(mandatory=$false,ValueFromPipeline=$true)]$pipe
    )

    function setUserAgent {
        $script:WebClient = New-Object System.Net.WebClient
    	$script:webClient.UseDefaultCredentials = $true
        $script:webClient.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
        $script:webClient.Headers.Add([System.Net.HttpRequestHeader]::UserAgent, 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)');
    }

    if (!$url) {$url=$pipe}
    if (!$whitelist) {$whitelist="the required web addresses."}
	if (!$filename) {$filename=$url.split('/')[-1]}

    try { #enable TLS 1.2
		[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    } catch [system.exception] {
		write-host "! ERROR: Could not implement TLS 1.2 Support."
		write-host "  This can occur on Windows 7 devices lacking Service Pack 1."
		write-host "  Please install that before proceeding."
		exit 1
    }

	write-host "- Downloading:   $url"

	if ($useProxy) {
        setUserAgent
        write-host ": Proxy location: $script:varProxyLoc`:$script:varProxyPort"
	    $script:WebClient.Proxy = New-Object System.Net.WebProxy("$script:varProxyLoc`:$script:varProxyPort",$true)
	    $script:WebClient.DownloadFile("$url","$filename")
		if (!(test-path $filename)) {$useProxy=$false}
    }

	if (!$useProxy) {
		setUserAgent #do it again so we can fallback if proxy fails
		$script:webClient.DownloadFile("$url","$filename")
	}

    if (!(test-path $filename)) {
        write-host "! ERROR: File $filename could not be downloaded."
        write-host "  Please ensure you are whitelisting $whitelist."
        write-host "- Operations cannot continue; exiting."
        exit 1
    } else {
        write-host ": Downloaded:    $filename"
    }
}

#region Verification ------------------------------------------------------------------

#user verification.....................................................................
if (!(get-process explorer -ea 0)) {
    write-host "! NOTICE: No user is logged-onto the device to send a message to."
    exit
} else {
    (gwmi win32_computersystem).username | select -first 1 | % {
        $varUsername=($_ -split '\\')[1]
        $varDomain=($_ -split '\\')[0]
    }
}

if (!$varUsername) {
    write-host "! ERROR: Unable to asertain username for logged-on user."
    write-host "  This may be because no user is logged into the device."
    exit
}

#OS validation.........................................................................
if ([int](gwmi win32_operatingsystem).buildnumber -lt 10240) {
    write-host "! ERROR: This Component requires Windows 10+ or Server 2016+."
    write-host "  Exiting."
    exit 1
}

#image validation......................................................................
if ($env:usrHeroImgURL) {
    downloadFile $env:usrHeroImgURL -filename hero.png
} else {
    downloadFile "https://storage.centrastage.net/dattoHero.png" -filename hero.png
}

#region Cleanup old tasks -------------------------------------------------------------

get-scheduledTask "Toast Message for*" | get-scheduledtaskinfo | ? {$_.lastRunTime -lt $((get-date).AddDays(-1))} | % {
    schtasks /delete /tn "$($_.taskName)" /f #january 2026
}

#region Assemble notification ---------------------------------------------------------

#acquire agent branding................................................................
$varCurrentLocation=$($PWD.Path) -replace '\\','/'
$varBrandLocation="file://$env:ProgramData/CentraStage/Brand" -replace '\\','/'
[xml]$varBrandXML= get-content "$env:ProgramData\CentraStage\Brand\keys.xml" -encoding UTF8 -ErrorAction SilentlyContinue
$varCurrentBrand=($varBrandXML.bundles.bundle.entry | ? {$_.key -eq 'productShortNameText'}).'#text' -replace '[^a-zA-Z0-9\s\u00E1\u00E9\u00ED\u00F3\u00FA\u00E4\u00EB\u00EF\u00F6\u00FC\u00E5\u00DF''"!&\.]',''
write-host ": Using brand:   $varCurrentBrand"

#create notification provider for 'reboot' button......................................
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -erroraction silentlycontinue | out-null
New-Item -Path "HKCR:\AppUserModelId" -Name "dRMMNotifier" -Force | out-null
New-ItemProperty -Path "HKCR:\AppUserModelId\dRMMNotifier" -Name DisplayName -Value "$varCurrentBrand" -PropertyType String -Force | out-null
New-ItemProperty -Path "HKCR:\AppUserModelId\dRMMNotifier" -Name ShowInSettings -Value 0 -PropertyType DWORD -Force | out-null

#remove any preexisting message PS1 file...............................................
remove-item "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -Force -ea 0 | out-null

#region Configure 'Alert' Status ------------------------------------------------------

if ($env:usrAlert -eq 'true') {
@"
#fill some forms
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

#furnish the toast XML
[xml]`$ToastTemplate = @"
<toast duration="long" scenario="incomingCall">
"@ | set-content "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -force
} else {
@"
#fill some forms
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

#furnish the toast XML
[xml]`$ToastTemplate = @"
<toast duration="long">
"@ | set-content "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -force
}

#region Assemble notification XML -----------------------------------------------------
@"
  <visual>
    <binding template="ToastGeneric">
      <text>$env:usrMessageTitle</text>
      <text placement="attribution">System notification</text>
      <image placement="hero" src="file://$varCurrentLocation/hero.png"/>
      <image id="1" placement="appLogoOverride" hint-crop="circle" src="$varBrandLocation/primaryLogo.png"/>
        <group>
            <subgroup>
                <text hint-style="body" hint-wrap="true">$env:usrMessageContent</text>
            </subgroup>
        </group>
    </binding>
  </visual>
"@ | add-content "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -force -Encoding UTF8

#configure reboot message..............................................................
if ($env:usrShowRestart -match 'true') {
    write-host "- Restart option enabled. User will see a localised option to restart the device."

    #internationalisation
    $arrStrings=@{
        1031=[PSCustomObject]@{Caption="German";            rebootString="Jetzt neu starten"}
        1033=[PSCustomObject]@{Caption="English (American)";rebootString="Restart now"}
        1034=[PSCustomObject]@{Caption="Spanish (European)";rebootString="Reiniciar ahora"}
        1036=[PSCustomObject]@{Caption="French";            rebootString="Red?marrer maintenant"}
        1040=[PSCustomObject]@{Caption="Italian";           rebootString="Riavvia ora"}
        1043=[PSCustomObject]@{Caption="Dutch";             rebootString="Nu opnieuw opstarten"}
        2057=[PSCustomObject]@{Caption="English (British)"; rebootString="Restart now"}
        2058=[PSCustomObject]@{Caption="Spanish (Mexican)"; rebootString="Reiniciar ahora"}
    }

    [int]$varLangCode=cmd /c set /a 0x$((Get-ItemProperty hklm:\system\controlset001\control\nls\language -name InstallLanguage).InstallLanguage)
    $varRebootLocalised=$arrStrings[$varLangCode].rebootString
    if (!$varRebootLocalised) {
        write-host ": System Language: Unsupported; Restart option, if enabled, will appear in English"
        $varRebootLocalised="Restart now"
    } else {
        write-host ": System Language: $($arrStrings[$varLangCode].Caption)"
    }

    #protocol handler to reboot (kelvin tegelaar, cyberdrain.com)
        if (!(get-item 'HKCR:\ToastReboot' -erroraction 'silentlycontinue')) {
        #create handler for reboot
        New-item 'HKCR:\ToastReboot' -force | out-null
        set-itemproperty 'HKCR:\ToastReboot' -name '(DEFAULT)' -value 'url:ToastReboot' -force | out-null
        set-itemproperty 'HKCR:\ToastReboot' -name 'URL Protocol' -value '' -force | out-null
        new-itemproperty -path 'HKCR:\ToastReboot' -propertytype dword -name 'EditFlags' -value 2162688 | out-null
        New-item 'HKCR:\ToastReboot\Shell\Open\command' -force | out-null
        set-itemproperty 'HKCR:\ToastReboot\Shell\Open\command' -name '(DEFAULT)' -value 'C:\Windows\System32\shutdown.exe -r -t 10' -force | out-null
    }

    #add the action to the XML
    add-content -path "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -Value "<actions><action content=`"$varRebootLocalised`" arguments=`"ToastReboot:\\`" activationType=`"protocol`" /></actions>" -force -Encoding UTF8
} else {
    add-content -path "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -Value "<actions/>" -force -Encoding UTF8
    write-host "- Restart option has not been enabled."
}

#conclude notification XML.............................................................
@"
</toast>
`"@
`$ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::New()
`$ToastXml.LoadXml(`$ToastTemplate.OuterXml)
`$ToastMessage = [Windows.UI.Notifications.ToastNotification]::New(`$ToastXML)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("dRMMNotifier").Show(`$ToastMessage)
"@ | add-content "$env:ProgramData\CentraStage\temp\toastMessage.ps1" -force -Encoding UTF8

#region Configure scheduled task ------------------------------------------------------

$varTask=new-scheduledTask -Action $(new-scheduledTaskAction -Execute "$env:WinDir\System32\WindowsPowerShell\v1.0\PowerShell.exe" -Argument "-executionpolicy bypass -windowstyle hidden -noprofile -noninteractive -file ""$env:ProgramData\CentraStage\temp\toastMessage.ps1""") -trigger $(new-scheduledTaskTrigger -Once -At $varTime) -Description "Toast-style popup message for $varUsername, from $varCurrentBrand (Datto RMM), at $(get-date)" -settings $(new-scheduledTaskSettingsSet -AllowStartIfOnBatteries)
register-scheduledTask "Toast message for [$varUsername] ($varEpoch)" -InputObject $varTask -User "$varDomain\$varUsername" -Force | Out-Null

#region Closeout ----------------------------------------------------------------------

write-host "============================================"
write-host ": Message has been scheduled for logged-on user and should appear at $varTime (device time):"
get-scheduledTask "*$varEpoch*" | get-scheduledTaskInfo -Verbose | Select Taskname, NextRunTime | Out-Host

#region 5G NETWORKS REMINDER EDITS BY LEE M ------------------------------------------------------

try {
    [int]$currentCount = Get-ItemPropertyValue -Path $varRegPath -Name $varRegRReminderCount -ErrorAction Stop
    $newCount = $currentCount + 1
    Set-ItemProperty -Path $varRegPath -Name $varRegRReminderCount -Value $newCount -Force | Out-Null
    Set-ItemProperty -Path $varRegPath -Name $varRegRReminder -Value (Get-Date) -Force | Out-Null
    Write-Host "-- Updated reboot reminder count to $newCount and timestamp to current date/time."
} catch {
    # Create reboot reminder counter and set to 1
    if ($varRRemCount -gt 0) {
        New-ItemProperty -Path $varRegPath -Name $varRegRReminderCount -Value 1 -PropertyType String -Force | Out-Null
        Write-Host "-- Set reboot reminder count to 1"
    }
        New-ItemProperty -Path $varRegPath -Name $varRegRReminder -Value (Get-Date) -PropertyType String -Force | Out-Null
        Write-Host "-- Created reboot reminder timestamp with current date/time."
}