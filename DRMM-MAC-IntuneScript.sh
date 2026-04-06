#!/bin/bash
Platform=Syrah
SiteID=<siteID>

# Datto RMM Agent deploy designed and written by Jon North, Datto, March 2021
# Download the Agent installer, run it, wait for it to finish, delete it
# First check if Agent is already installed and instantly exit if so

if [ -d "/Applications/AEM Agent.app" ] ; then
    echo "Datto RMM Agent already installed on this device" ; exit
fi

# Output target site ID and timestamp
echo "Target site ID: $SiteID"
echo "Current date and time is `date`"
AgentFilename='/tmp/DRMMSetup_'$(date +"%Y-%m-%d_%H-%M")

# Download the Agent
curl -o $AgentFilename.zip https://$Platform.rmm.datto.com/download-agent/mac/$SiteID

# Unzip and install the Agent
mkdir $AgentFilename
unzip -a -o $AgentFilename.zip -d $AgentFilename
installer -pkg "$AgentFilename/AgentSetup/CAG.pkg" -target /
rm $AgentFilename.zip
rm -rf $AgentFilename
exit