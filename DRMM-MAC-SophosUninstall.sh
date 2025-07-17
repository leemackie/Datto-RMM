#!/bin/sh

if [ -z "${tamperCode}" ]; then
    echo "!! Tamper protection code was not set in the component - scrcipt will not work!"
    exit 1
fi

echo "-- Executing Sophos Central removal"
echo "-- Tamper protection code: $tamperCode"

/Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer --remove --tamper_password $tamperCode

sleep 120

echo "-- Confirming removal"
if [ -f /Applications/Sophos* ]; then
    echo "!! Sophos applications still found on machine - please review."
    exit 1
fi

echo "-- No Sophos applications found in /Applications - uninstall OK"

exit 0