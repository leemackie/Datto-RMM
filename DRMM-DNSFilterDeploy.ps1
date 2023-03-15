
if (!(Test-Path "C:\Temp")) { 
    mkdir C:\temp
}

# Download DNSFilter installer to C:\Temp
Invoke-WebRequest -Uri "https://download.dnsfilter.com/User_Agent/Windows/DNSFilter_Agent_Setup.msi" -OutFile "C:\temp\DNSFilter_Agent_Setup.msi"

# Install DNSFilter agent
msiexec /qn /i "C:\temp\DNSFilter_Agent_Setup.msi" NKEY="$env:SecretKey" /l* "C:\Temp\DNSFilter_Install.log"

# Wait 30 seconds to make sure install is complete
Pause -Second 30

# Delete the installer once script is complete
Remove-Item "C:\temp\DNSFilter_Agent_Setup.msi" -Force