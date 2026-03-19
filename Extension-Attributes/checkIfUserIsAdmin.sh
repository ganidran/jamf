#!/bin/bash
#
# Jamf extension attribute: reports whether the current console user is
# a member of the local admin group (True or False).

# Resolve the console user.
username=$(stat -f "%Su" /dev/console)

###########################
##### CHECK IF ADMIN ######
###########################

if dseditgroup -o checkmember -m "$username" admin &>/dev/null; then
    echo "<result>`True`</result>"
else
    echo "<result>`False`</result>"
fi

exit 0
