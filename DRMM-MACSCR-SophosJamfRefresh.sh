#!/bin/sh

echo "-- Executing JAMF policy refresh"
/usr/local/jamf/bin/jamf policy
/usr/local/jamf/bin/jamf recon

echo "-- Attempting to kill SophosServiceManager"
pid=$(ps -fe | grep '[S]ophosServiceManager' | awk '{print $2}')
if [[ -n $pid ]]; then
    kill -9 $pid
	echo "-- SUCCESS: SophosServiceManager found and killed"
else
    echo "-- WARNING: SophosServiceManager was not found running"
fi