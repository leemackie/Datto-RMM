#!/bin/sh

echo "-- Executing JAMF policy refresh"
/usr/local/jamf/bin/jamf policy
/usr/local/jamf/bin/jamf recon