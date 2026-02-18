#!/bin/sh
echo "-- Executing Sophos Central removal"

if [ -z "${tamperCode}" ]; then
    echo "-- Tamper protection code was not set in the component"
    echo "-- Attempting uninstall without tamper protection code"
    echo "-- If tamper protection is enabled on the Sophos install this will fail"
    /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer --remove
else
    echo "-- Tamper protection code: $tamperCode"
    /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer --remove --tamper_password $tamperCode

fi
rm /Applications/Sophos\ Installer.app
sleep 120

echo "-- Confirming removal"
if [ -f /Applications/Sophos* ]; then
    echo "!! Sophos applications still found on machine - please review."
    exit 1
fi

echo "-- No Sophos applications found in /Applications - uninstall OK"
exit 0