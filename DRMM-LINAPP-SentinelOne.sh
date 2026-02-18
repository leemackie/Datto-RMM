#!/bin/bash
: '
.SYNOPSIS
    Installs SentinelOne Agent on Linux devices.

.DESCRIPTION
    This script installs the SentinelOne Agent on Linux devices using a provided site token.
    The site token can be provided at either the Site level or the Component level.
    If both levels are provided, the Component level token takes precedence.

.PARAMETER S1CustToken
    The site token required for the SentinelOne Agent installation.
    This variable is set at the Site level.

.PARAMETER usrSiteToken
    The variable that holds the site token value if input maunally via the script.
    This variable can be set at the Component level.

.NOTES
    Written by Lee Mackie - 5G Networks
    Uses parts of the S1 install script from the S1 Community GitHub repo:
    https://github.com/s1community/install-tools/blob/main/linux/README-install-repo.md

    Requires S1Agent.deb and S1Agent.rpm to be attached to the component.
    Script Version: 1.0 - Initial version - 07/10/25
'

# Check for the type of OS
if (cat /etc/os-release | grep -E "ID=(ubuntu|debian)" &> /dev/null ); then
    echo "-- Detected Debian-based OS..."
    osInstallCmd="dpkg"
elif (cat /etc/os-release | grep -E "ID=\"(rhel|amzn|centos|ol|scientific|rocky|almalinux)\"" &> /dev/null ); then
    echo "-- Detected Red Hat-based OS..."
    osInstallCmd="rpm"
elif (cat /etc/os-release |grep 'ID="fedora"' || cat /etc/os-release |grep 'ID=fedora' &> /dev/null ); then
    echo "-- Detected Red Hat-based OS..."
    osInstallCmd="rpm"
else
    echo "!! ERROR:  Unknown Release ID: $1"
    cat /etc/*release
    exit 1
fi



if [[ -n "$usrSiteToken" ]]; then
    echo "-- Using component level site token"
    echo "-- Note: This takes precedence over the site level token if both are provided"
    S1_AGENT_MANAGEMENT_TOKEN=$usrSiteToken
elif [[ -n "$S1CustToken" ]]; then
    echo "-- Using component level site token"
    S1_AGENT_MANAGEMENT_TOKEN=$S1CustToken
else
    echo "!! ERROR: No site token defined for use with the component. Check the component and site settings and re-run the job."
    exit 1
fi

# Validate the Site Token
if !(echo $S1_AGENT_MANAGEMENT_TOKEN | base64 -d | grep sentinelone.net &> /dev/null ); then
    echo "!! ERROR: Site Token does not decode correctly. Please ensure that you've passed a valid Site Token either via the Site Settings or the Component option."
    exit 1
fi

# Echo script variables for confirmation
echo "-- Site Token: $S1_AGENT_MANAGEMENT_TOKEN"

# Create installation configuration file
echo "S1_AGENT_MANAGEMENT_TOKEN=$S1_AGENT_MANAGEMENT_TOKEN" >> /tmp/sentinelone_install.cfg
echo "S1_AGENT_AUTO_START=true" >> /tmp/sentinelone_install.cfg
# echo "S1_AGENT_DEVICE_TYPE=$usrDeviceType" >> /tmp/sentinelone_install.cfg
export S1_AGENT_INSTALL_CONFIG_PATH="/tmp/sentinelone_install.cfg"
echo "-- Created config file: $S1_AGENT_INSTALL_CONFIG_PATH"

# Install the dang thing
echo "-- Installing SentinelOne Agent..."
if [ $osInstallCmd == "dpkg" ]; then
    dpkg -i ./S1Agent.deb
elif [ $osInstallCmd == "rpm" ]; then
    rpm -i --nodigest ./S1Agent.rpm
fi

if [ $? -eq 0 ]; then
    echo "-- OK:  Finished installing SentinelOne Agent package."
else
    echo "!! ERROR:  Failed to install SentinelOne Agent."
    exit 1
fi

rm $S1_AGENT_INSTALL_CONFIG_PATH
echo "-- Removed config file"

# Set the Site Token - shouldn't be required because we're including it in the config file at installation time
#sentinelctl management token set $S1_SITE_TOKEN

echo "-- Running debug operations to confirm installation status"
echo "------------------------------------------------------------"
# Start the Agent
sentinelctl control start

# Allow everything to start up and connect
sleep 3m

# Check status and version
sentinelctl control status
sentinelctl version
echo "------------------------------------------------------------"
echo ""
echo "-- SUCCESS: SentinelOne Agent installed successfully, check output for running and version status."