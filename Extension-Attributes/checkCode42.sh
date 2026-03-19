#!/bin/bash
#
# Jamf extension attribute: reports Code42 (AAT) status — installed and
# registered (with username), installed but deactivated, unregistered,
# or app/log not found.

###########################
### DOES CODE42 EXIST? ####
###########################

if [[ -e "/Applications/Code42-AAT.app" ]]; then
    appLog=""
    if [[ -e "/Library/Application Support/Code42-AAT/logs/app.log" ]]; then
        appLog="/Library/Application Support/Code42-AAT/logs/app.log"
    elif [[ -e "/Library/Application Support/Code42-AAT/Data/logs/app.log" ]]; then
        appLog="/Library/Application Support/Code42-AAT/Data/logs/app.log"
    fi

    if [[ -n "$appLog" ]]; then
        appLogUsername=$(grep -i "username" "$appLog" | tr '[:upper:]' '[:lower:]' | cut -f 2 -d ':' | cut -f 2 -d \")
        code42AatRegline=$(grep -i "reported as Deactivated" "$appLog")

        if [[ -n "$appLogUsername" ]]; then
            if [[ -z "$code42AatRegline" ]]; then
                echo "<result>Installed and registered to: $appLogUsername</result>"
            else
                echo "<result>Installed, but deactivated</result>"
            fi
        else
            echo "<result>Installed, but unregistered</result>"
        fi
    else
        echo "<result>Installed, but log not found</result>"
    fi
else
    echo "<result>App not installed</result>"
fi
