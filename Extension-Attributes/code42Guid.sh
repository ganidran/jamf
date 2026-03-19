#!/bin/bash
#
# Jamf extension attribute: reads the Code42 (AAT) device GUID from app.log
# and reports it, or a short message if not found.

# Locate Code42 app.log.
appLog=""
if [[ -e "/Library/Application Support/Code42-AAT/logs/app.log" ]]; then
	appLog="/Library/Application Support/Code42-AAT/logs/app.log"
elif [[ -e "/Library/Application Support/Code42-AAT/Data/logs/app.log" ]]; then
	appLog="/Library/Application Support/Code42-AAT/Data/logs/app.log"
fi

if [[ -f "$appLog" ]]; then
	deviceGuid=$(grep -o '"guid": "[^"]*' "$appLog" | awk -F'"' '{print $4}')
	if [[ -n "$deviceGuid" ]]; then
		echo "<result>$deviceGuid</result>"
	else
		echo "<result>GUID not found in app.log</result>"
	fi
else
	echo "<result>App.log not found</result>"
fi
