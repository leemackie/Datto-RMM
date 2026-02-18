#!/bin/sh
: '
.SYNOPSIS
    Installs SentinelOne Agent on MacOS devices.

.DESCRIPTION
    This script installs the SentinelOne Agent on MacOS devices using a provided site token.
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
    Requires S1Agent.pkg to be attached to the component.
    Script Version: 1.0 - Initial version - 12/09/25
'

installer="S1Agent.pkg"
#tokendir="/Library/Managed Preferences/"
tokenfile="com.sentinelone.registration-token"

if [ -d /Applications/SentinelOne/ ]; then
  echo "-- WARNING: SentinelOne is already Installed"
  exit 0
else
    if [ -n "$usrSiteToken" ]; then
        echo "-- Using component level site token"
        echo "-- Note: This takes precedence over the site level token if both are provided"
        varSiteToken=$usrSiteToken
    elif [ -n "$S1CustToken" ]; then
        echo "-- Using component level site token"
        varSiteToken=$S1CustToken
    else
        echo "!! ERROR: No valid SentinelOne Site Token provided. Please provide a valid token and re-run the script."
        exit 1
    fi
    # Echo script variables for confirmation
    echo "-- Site Token: $varSiteToken"

    #Create Site Token File
    echo $varSiteToken > $tokenfile
    echo "-- Created Site token file in local directory"

    #Install Agent
    /usr/sbin/installer -pkg ./$installer -target /
    echo "-- Executed installation of SentinelOne Agent"
    installer_status=$?
    echo "-- Installer exit code: $installer_status"

    #Cleanup token file
    #rm -f ./$dir/$tokenfile
    #echo "-- Removed token file"

    if [ $installer_status -eq 0 ] && [ -d /Applications/SentinelOne/ ]; then
        echo "-- OK: SentinelOne Agent installed successfully"
    else
        echo "!! ERROR: SentinelOne Agent installation failed"
        exit 1
    fi
fi