# Enable verbose output
$VerbosePreference = "Continue"

# Check if .NET Framework 3.5 is already installed
$feature = Get-WindowsOptionalFeature -FeatureName NetFx3 -Online

if ($feature.State -eq "Enabled") {
    Write-Verbose "The .NET Framework 3.5 is already installed."
} else {
    Write-Verbose "Installing .NET Framework 3.5 using DISM..."

    # Install .NET 3.5 using DISM
    $logFile = "C:\ProgramData\CentraStage\Temp\DotNet35Install.log"
    Write-Verbose "Writing log file to $logFile"
    $dismCommand = "DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /LogPath:$logFile"

    Invoke-Expression $dismCommand

    # Verify installation
    $feature = Get-WindowsOptionalFeature -FeatureName NetFx3 -Online
    if ($feature.State -eq "Enabled") {
        Write-Verbose "Installation successful!"
    } else {
        Write-Verbose "Installation failed. Check the log for details: $logFile"
    }
}