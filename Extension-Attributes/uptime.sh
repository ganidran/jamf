#!/bin/bash
#
# Jamf extension attribute: reports system uptime in days (e.g. "5 Days")
# for use in smart groups or reporting.

# Parse days from uptime output; treat non-numeric as 0.
dayCount=$(uptime | awk -F "(up | days)" '{ print $2 }')
if ! [ "$dayCount" -eq "$dayCount" ] 2>/dev/null; then
    dayCount="0"
fi

echo "<result>$dayCount Days</result>"
exit 0
