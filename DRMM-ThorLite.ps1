##################################################
# Script Title: THOR Download and Execute Script
# Script File Name: thor-seed.ps1
# Author: Florian Roth
# Version: 0.20.0
# Date Created: 13.07.2020
# Last Modified: 21.01.2022
##################################################

##################################################
# Adapted for use in Datto RMM
# Author: Lee Mackie (leem@5gn.com.au)
# Version: 0.2
# Date Created: 27/01/2022
# Last Modified: 27/01/2023
##################################################

#Requires -Version 3

# #####################################################################
# DRMM Configuration --------------------------------------------------
# #####################################################################

# DRMM Variable detection and set
Write-Output "### Datto RMM Variables"
# The ASGARD instance to download THOR from (license will be generated on that instance)
#$AsgardServer = $env:AsgardServer
$AsgardServer = ''
#Write-Output "# Asgard Server: $AsgardServer"

# Use Nextron's cloud to download THOR and generate a license
#$UseThorCloud = $env:UseThorCloud
$UseThorCloud = ''
#Write-Output "# Use Thor Cloud: $UseThorCloud"

# Set a download token (used with ASGARDs and THOR Cloud)
#$Token = $env:Token
$Token = ''
#Write-Output "# Token: $Token"

# Ignore connection errors caused by self-signed certificates
#$IgnoreSSLErrors = $env:IgnoreSSLErrors
$IgnoreSSLErrors = $true
#Write-Output "# Ignore SSL Errors: $IgnoreSSLErrors"

# Allows you to define a custom URL from which the THOR package is retrieved
$CustomUrl = $env:CustomUrl
Write-Output "# Custom download URL: $CustomURL"

# Add a random sleep delay to the scan start to avoid all scripts starting at the exact same second
$RandomDelay = $env:RandomDelay
Write-Output "# Execution delay: $RandomDelay"

# Execution Directory
$ThorDirectory = Get-Location
Write-Output "# Execution path: $ThorDirectory"

# Directory to write all output files to (default is script directory)
$OutputPath = $env:OutputPath
Write-Output "# Output path: $OutputPath"

# Deactivates log file for this PowerShell script (thor-run.log)
$NoLog = $env:NoLog
Write-Output "# No logging: $NoLog"

# Enables debug output and skips cleanup at the end of the scan
$Debugging = $env:Debugging
Write-Output "# Debugging: $Debugging"

#Create $OutputPath folder if doesn't exist
if (Test-Path $OutputPath) {
    Write-Output "# Output directory found: $OutputPath"
} else {
    New-Item -Path $OutputPath -ItemType 'Directory' -InformationAction SilentlyContinue
    Write-Output "# Output directory created: $OutputPath"
}

Write-Output "### Datto RMM variables complete."
Write-Output " "

# #####################################################################
# Parameters ----------------------------------------------------------
# #####################################################################

# Fixing Certain Platform Environments --------------------------------
$AutoDetectPlatform = ""
#$OutputPath = $PSScriptRoot

# #####################################################################
# Presets -------------------------------------------------------------
# #####################################################################

# Predefined YAML Config
$UsePresetConfig = $True
# Lines with '#' are commented and inactive. We decided to give you
# some examples for your convenience. You can see all possible command
# line parameters running `thor64.exe --help` or on this web page:
# https://github.com/NextronSystems/nextron-helper-scripts/tree/master/thor-help
# Only the long forms of the parameters are accepted in the YAML config.

# PRESET CONFIGS

# FULL with Lookback
# Preset template for a complete scan with a lookback of 2 days
# Run time: 40 minutes to 6 hours
# Specifics:
#   - runs all default modules
#   - only scans elements that have been changed or created within the last 14 days
#   - applies Sigma rules
# cloudconf: [!]PresetConfig_FullLookback [Full Scan with Lookback] Performs a full disk scan with all modules but only checks elements changed or created within the last 14 days - best for SOC response to suspicious events (5 to 20 min)
$PresetConfig_FullLookback = @"
rebase-dir: $($OutputPath)  # Path to store all output files (default: script location)
nosoft: true           # Don't trottle the scan, even on single core systems
global-lookback: true  # Apply lookback to all possible modules
lookback: 14           # Log and Eventlog look back time in days
# cpulimit: 70         # Limit the CPU usage of the scan
sigma: true            # Activate Sigma scanning on Eventlogs
nofserrors: true       # Don't print an error for non-existing directories selected in quick scan
nocsv: true            # Don't create CSV output file with all suspicious files
noscanid: true         # Don't print a scan ID at the end of each line (only useful in SIEM import use cases)
nothordb: true         # Don't create a local SQLite database for differential analysis of multiple scans
"@

# QUICK
# Preset template for a quick scan
# Run time: 3 to 10 minutes
# Specifics:
#   - runs all default modules except Eventlog and a full file system scan
#   - in quick mode only a highly relevant subset of folders gets scanned
#   - skips Registry checks (keys with potential for persistence still get checked in Autoruns module)
# cloudconf: PresetConfig_Quick [Quick Scan] Performs a quick scan on processes, caches, persistence elements and selected highly relevant directories (3 to 10 min)
$PresetConfig_Quick = @"
rebase-dir: $($OutputPath)  # Path to store all output files (default: script location)
nosoft: true       # Don't trottle the scan, even on single core systems
quick: true        # Quick scan mode
nofserrors: true   # Don't print an error for non-existing directories selected in quick scan
nocsv: true        # Don't create CSV output file with all suspicious files
noscanid: true     # Don't print a scan ID at the end of each line (only useful in SIEM import use cases)
nothordb: true     # Don't create a local SQLite database for differential analysis of multiple scans
"@

# FULL
# Preset template for a complete scan
# Run time: 40 minutes to 6 hours
# Specifics:
#   - runs all default modules
#   - only scans the last 14 days of the Eventlog
#   - applies Sigma rules
# cloudconf: PresetConfig_Full [Full Scan] Performs a full disk scan with all modules (40 min to 6 hours)
$PresetConfig_Full = @"
rebase-dir: $($OutputPath)  # Path to store all output files (default: script location)
nosoft: true       # Don't trottle the scan, even on single core systems
lookback: 14       # Log and Eventlog look back time in days
# cpulimit: 70     # Limit the CPU usage of the scan
sigma: true        # Activate Sigma scanning on Eventlogs
nofserrors: true   # Don't print an error for non-existing directories selected in quick scan
nocsv: true        # Don't create CSV output file with all suspicious files
noscanid: true     # Don't print a scan ID at the end of each line (only useful in SIEM import use cases)
nothordb: true     # Don't create a local SQLite database for differential analysis of multiple scans
"@

# SELECT YOU CONFIG
# Select your preset config
# Choose between: $PresetConfig_Full, $PresetConfig_Quick, $PresetConfig_FullLookback
#$PresetConfig = $PresetConfig_FullLookback
# Set the preset switch
if ($env:Preset -eq 'Quick') {
    $PresetConfig = $PresetConfig_Quick
    } elseif ($env:Preset = 'Full') {
    $PresetConfig -eq $PresetConfig_Full
    } else {
    $PresetConfig = $PresetConfig_FullLookback
}

# False Positive Filters
$UseFalsePositiveFilters = $True
# The following new line separated false positive filters get
# applied to all log lines as regex values.
$PresetFalsePositiveFilters = @"
Could not get files of directory
Signature file is older than 60 days
\\Our-Custom-Software\\v1.[0-9]+\\
"@

# Global Variables ----------------------------------------------------
$global:NoLog = $NoLog

# #####################################################################
# Functions -----------------------------------------------------------
# #####################################################################

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

# Required for ZIP extraction in PowerShell version <5.0
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Expand-File {
    param([string]$ZipFile, [string]$OutPath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
}

function Write-Log {
    param (
        [Parameter(Mandatory=$True, Position=0, HelpMessage="Log entry")]
            [ValidateNotNullOrEmpty()]
            [String]$Entry,

        [Parameter(Position=1, HelpMessage="Log file to write into")]
            [ValidateNotNullOrEmpty()]
            [Alias('SS')]
            [IO.FileInfo]$LogFile = "thor-seed.log",

        [Parameter(Position=3, HelpMessage="Level")]
            [ValidateNotNullOrEmpty()]
            [String]$Level = "Info"
    )

    # Indicator
    $Indicator = "[+] "
    if ( $Level -eq "Warning" ) {
        $Indicator = "[!] "
    } elseif ( $Level -eq "Error" ) {
        $Indicator = "[E] "
    } elseif ( $Level -eq "Progress" ) {
        $Indicator = "[.] "
    } elseif ($Level -eq "Note" ) {
        $Indicator = "[i] "
    } elseif ($Level -eq "Help" ) {
        $Indicator = ""
    }

    # Output Pipe
    if ( $Level -eq "Warning" ) {
        Write-Warning -Message "$($Indicator) $($Entry)"
    } elseif ( $Level -eq "Error" ) {
        Write-Host "$($Indicator)$($Entry)" -ForegroundColor Red
    } else {
        Write-Host "$($Indicator)$($Entry)"
    }

    # Log File
    if ( $global:NoLog -eq $False ) {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') $($env:COMPUTERNAME): $Entry" | Out-File -FilePath $LogFile -Append
    }
}

# #####################################################################
# Main Program --------------------------------------------------------
# #####################################################################

Write-Host "==========================================================="
Write-Host "   ________ ______  ___    ____           __    ___        "
Write-Host "  /_  __/ // / __ \/ _ \  / __/__ ___ ___/ /   /   \       "
Write-Host "   / / / _  / /_/ / , _/ _\ \/ -_) -_) _  /   /_\ /_\      "
Write-Host "  /_/ /_//_/\____/_/|_| /___/\__/\__/\_,_/    \ / \ /      "
Write-Host "                                               \   /       "
Write-Host "  Nextron Systems, by Florian Roth              \_/        "
Write-Host "                                                           "
Write-Host "==========================================================="

# Measure time
$DateStamp = Get-Date -f yyyy-MM-dd
$StartTime = $(Get-Date)

Write-Log "Started thor-seed with PowerShell v$($PSVersionTable.PSVersion)"

# ---------------------------------------------------------------------
# Evaluation ----------------------------------------------------------
# ---------------------------------------------------------------------

# Hostname
$Hostname = [System.Net.Dns]::GetHostName()
# Evaluate Architecture
$ThorArch = "64"
if ( [System.Environment]::Is64BitOperatingSystem -eq $False ) {
    $ThorArch = ""
}
# License Type
$LicenseType = "server"
$PortalLicenseType = "server"
$OsInfo = Get-CimInstance -ClassName Win32_OperatingSystem
if ( $osInfo.ProductType -eq 1 ) {
    $LicenseType = "client"
    $PortalLicenseType = "workstation"
}

# Output Info on Auto-Detection
if ( $AutoDetectPlatform -ne "" ) {
    Write-Log "Auto Detect Platform: $($AutoDetectPlatform)"
    Write-Log "Note: Some automatic changes have been applied"
}

# ---------------------------------------------------------------------
# THOR still running --------------------------------------------------
# ---------------------------------------------------------------------
$ThorProcess = Get-Process -Name "thor64" -ErrorAction SilentlyContinue
if ( $ThorProcess ) {
    Write-Log "A THOR process is still running." -Level "Error"
}

# Output File Overview
$OutputFiles = Get-ChildItem -Path "$($OutputPath)\*" -Include "$($Hostname)_thor_*" | Sort CreationTime
if ( -not $Cleanup ) {
    # Give help depending on the auto-detected platform
    if ( $AutoDetectPlatform -eq "MDATP" ) {
        Write-Log "Detected Platform: Microsoft Defender ATP"
        if ( $ThorProcess ) {
            if ( $OutputFiles.Length -gt 0 ) {
                Write-Log "Hint: You can use the following commands to retrieve the scan logs"
                foreach ( $OutFile in $OutputFiles ) {
                    Write-Log "getfile `"$($OutFile.FullName)`"" -Level "Help"
                }
            } else {
                Write-Log "The scan hasn't produced any output files yet."
            }
        }
        # Cannot run new THOR instance as long as old log files are present
        if ( -not $ThorProcess -and $OutputFiles.Length -gt 0 ) {
            Write-Log "Cannot start new THOR scan as long as old report files are present" -Level "Error"
            Write-Log "1.) Retrieve the available log files and HTML reports" -Level "Help"
            foreach ( $OutFile in $OutputFiles ) {
                Write-Log "    getfile `"$($OutFile.FullName)`"" -Level "Help"
            }
            Write-Log "2.) Use the following command to cleanup the output directory and remove all previous reports" -Level "Help"
            Write-Log "    run thor-seed.ps1 -parameters `"-Cleanup`"" -Level "Help"
            Write-Log "3.) Start a new THOR scan with" -Level "Help"
            Write-Log "    run thor-seed.ps1" -Level "Help"
            return
        } else {
            Write-Log "No logs found of a previous scan"
        }
    } else {
        Write-Log "Checking output folder: $($OutputPath)"
        if ( $OutputFiles.Length -gt 0 ) {
            Write-Log "Output files that have been generated so far:"
            foreach ( $OutFile in $OutputFiles ) {
                Write-Log "$($OutFile.FullName)" -Level "Help"
            }
        }
    }
}

# Quit if THOR is still running
if ( $ThorProcess -and $Cleanup ) {
    Write-Log "Please wait until the THOR scan is completed until you cleanup the logs (cleanup interrupted)" -Level "Error"
}
if ( $ThorProcess ) {
    # Get current status
    $LastTxtFile = Get-ChildItem -Path "$($OutputPath)\*" -Include "$($Hostname)_thor_*.txt" | Sort LastWriteTime | Select -Last 1
    Write-Log "Last written log file is: $($LastTxtFile.FullName)"
    Write-Log "Trying to get the last 3 log lines"
    # Get last 3 lines
    $LastLines = Get-content -Tail 3 $LastTxtFile
    $OutLines = $LastLines -join "`r`n" | Out-String
    Write-Log "The last 3 log lines are:"
    Write-Host $OutLines

    # Quit
    return
}

# ---------------------------------------------------------------------
# Cleanup Only --------------------------------------------------------
# ---------------------------------------------------------------------
if ( $Cleanup ) {
    Write-Log "Starting cleanup"
    # Remove logs and reports
    Remove-Item -Confirm:$False -Recurse -Force -Path "$($OutputPath)\*" -Include "$($Hostname)_thor_*"
    Write-Log "Cleanup complete"
    return
}

# ---------------------------------------------------------------------
# Get THOR ------------------------------------------------------------
# ---------------------------------------------------------------------
    $TempPackage = Get-ChildItem -Path $ThorDirectory *.zip

    # Unzip
    try {
        Write-Log "Extracting THOR package"
        Expand-File $TempPackage $ThorDirectory
    } catch {
        Write-Log "Error while expanding the THOR ZIP package $_" -Level "Error"
        break
    }

# ---------------------------------------------------------------------
# Run THOR ------------------------------------------------------------
# ---------------------------------------------------------------------
try {
    # Finding THOR binaries in extracted package
    Write-Log "Trying to find THOR binary in location $($ThorDirectory)"
    $ThorLocations = Get-ChildItem -Path $ThorDirectory -Recurse -Filter thor*.exe
    # Error - not a single THOR binary found
    if ( $ThorLocations.count -lt 1 ) {
        Write-Log "THOR binaries not found in directory $($ThorDirectory)" -Level "Error"
        if ( $CustomUrl ) {
            Write-Log 'When using a custom ZIP package, make sure that the THOR binaries are in the root of the archive and not any sub-folder. (e.g. ./thor64.exe and ./signatures)' -Level "Warning"
            break
        } else {
            Write-Log "This seems to be a bug. You could check the temporary THOR package yourself in location $($ThorDirectory)." -Level "Warning"
            break
        }
    }

    # Selecting the first location with THOR binaries
    $LiteAddon = ""
    foreach ( $ThorLoc in $ThorLocations ) {
        # Skip THOR Util findings
        if ( $ThorLoc.Name -like "*-util*" ) {
            # But first, lets update
            thor-util.exe upgrade
            continue
        }
        # Save the directory name of the found THOR binary
        $ThorBinDirectory = $ThorLoc.DirectoryName
        # Is it a Lite version
         if ( $ThorLoc.Name -like "*-lite*" ) {
             Write-Log "THOR Lite detected"
             $LiteAddon = "-lite"
         }
        Write-Log "Using THOR binaries in location $($ThorBinDirectory)."
        break
    }
    $ThorBinaryName = "thor$($ThorArch)$($LiteAddon).exe"
    $ThorBinary = Join-Path $ThorBinDirectory $ThorBinaryName

    # Use Preset Config (instead of external .yml file)
    $Config = ""
    if ( $UsePresetConfig ) {
        Write-Log 'Using preset config defined in script header due to $UsePresetConfig = $True'
        $TempConfig = Join-Path $ThorBinDirectory "config.yml"
        Write-Log "Writing temporary config to $($TempConfig)"
        Out-File -FilePath $TempConfig -InputObject $PresetConfig -Encoding ASCII
        $Config = $TempConfig
    }

    # Use Preset False Positive Filters
    if ( $UseFalsePositiveFilters ) {
        Write-Log 'Using preset false positive filters due to $UseFalsePositiveFilters = $True'
        $ThorConfigDir = Join-Path $ThorBinDirectory "config"
        $TempFPFilter = Join-Path $ThorConfigDir "false_positive_filters.cfg"
        Write-Log "Writing temporary false positive filter file to $($TempFPFilter)"
        Out-File -FilePath $TempFPFilter -InputObject $PresetFalsePositiveFilters -Encoding ASCII
    }

    # Scan parameters
    [string[]]$ScanParameters = @()
    if ( $Config ) {
        $ScanParameters += "-t $($Config)"
    }

    # Run THOR
    Write-Log "Starting THOR scan ..."
    Write-Log "Command Line: $($ThorBinary) $($ScanParameters)"
    Write-Log "Writing output files to $($OutputPath)"
    if (-not (Test-Path -Path $OutputPath) ) {
        Write-Log "Output path does not exists yet. Trying to create it ..."
        try {
            New-Item -ItemType Directory -Force -Path $OutputPath
            Write-Log "Output path $($OutputPath) successfully created."
        } catch {
            Write-Log "Output path set by $OutputPath variable doesn't exist and couldn't be created. You'll have to rely on the SYSLOG export or command line output only." -Level "Error"
        }
    }
    if ( $ScanParameters.Count -gt 0 ) {
        # With Arguments
        $p = Start-Process $ThorBinary -ArgumentList $ScanParameters -NoNewWindow -PassThru
    } else {
        # Without Arguments
        $p = Start-Process $ThorBinary -NoNewWindow -PassThru
    }
    # Cache handle, required to access ExitCode, see https://stackoverflow.com/questions/10262231/obtaining-exitcode-using-start-process-and-waitforexit-instead-of-wait
    $handle = $p.Handle
    # Wait using WaitForExit, which handles CTRL+C delayed
    $p.WaitForExit()

    # ERROR -----------------------------------------------------------
    if ( $p.ExitCode -ne 0 ) {
        Write-Log "THOR scan terminated with error code $($p.ExitCode)" -Level "Error"
    } else {
        # SUCCESS -----------------------------------------------------
        Write-Log "Successfully finished THOR scan"
        # Output File Info
        $OutputFiles = Get-ChildItem -Path "$($OutputPath)\*" -Include "$($Hostname)_thor_$($DateStamp)*"
        if ( $OutputFiles.Length -gt 0 ) {
            foreach ( $OutFile in $OutputFiles ) {
                Write-Log "Generated output file: $($OutFile.FullName)"
            }
        }
        # Give help depending on the auto-detected platform
        if ( $AutoDetectPlatform -eq "MDATP" -and $OutputFiles.Length -gt 0 ) {
            Write-Log "Hint (ATP): You can use the following commands to retrieve the scan logs"
            foreach ( $OutFile in $OutputFiles ) {
                Write-Log "  getfile `"$($OutFile.FullName)`""
            }
            #Write-Log "Hint (ATP): You can remove them from the end system by using"
            #foreach ( $OutFile in $OutputFiles ) {
            #    Write-Log "  remediate file `"$($OutFile.FullName)`""
            #}
        }
    }
} catch {
    Write-Log "Unknown error during THOR scan $_" -Level "Error"
}

# ---------------------------------------------------------------------
# Cleanup -------------------------------------------------------------
# ---------------------------------------------------------------------
try {
    if ( $Debugging -eq $False ) {
        Write-Log "Cleaning up temporary directory with THOR package ..." -Level Process
        # Delete THOR ZIP package
        Remove-Item -Confirm:$False -Force -Recurse $TempPackage -ErrorAction Ignore
        # Delete THOR Folder
        Remove-Item -Confirm:$False -Recurse -Force $ThorDirectory -ErrorAction Ignore
    }
} catch {
    Write-Log "Cleanup of temp directory $($ThorDirectory) failed. $_" -Level "Error"
}

# ---------------------------------------------------------------------
# End -----------------------------------------------------------------
# ---------------------------------------------------------------------
$ElapsedTime = $(get-date) - $StartTime
$TotalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Log "Scan took $($TotalTime) to complete" -Level "Information"