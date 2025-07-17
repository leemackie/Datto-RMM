#!/bin/sh
# Written by Lee Mackie - 5G Networks
# Version 1.0

echo "DRMM Mac OS X Sophos Update - version 1.0"

# Check for the RunSophosUpdate binary
if [ -f /usr/local/bin/RunSophosUpdate ]; then

	echo "\"/usr/local/bin/RunSophosUpdate\" found"

	# Run the update binary and output to log
	/usr/local/bin/RunSophosUpdate > /var/tmp/SophosUpdate.log 2>&1
	sophosUpdateResult=$( cat /var/tmp/SophosUpdate.log )

	# Check the log output and return the update status
	case "${sophosUpdateResult}" in

		*"URL is invalid"*		)
			echo "FAILED: Updater reports URL is invalid"
			exit 1
			;;

		*"up-to-date"*			)
			echo "OK: Sophos Anti-Virus is up-to-date"
			exit 0
			;;

		*						)
			echo "OK: Update Result: ${sophosUpdateResult}"
			exit 0
			;;

	esac

	rm /var/tmp/SophosUpdate.log

else

	echo "FAILED: \"/usr/local/bin/RunSophosUpdate\" NOT found!"
	exit 1

fi

exit 0