#!/bin/bash
#
# Demotes the currently logged-in user from local admin. Skips the companyadmin
# account used at enrollment.

###########################
###### DEMOTE ADMIN #######
###########################

# Resolve the console user.
currentUser=$(ls -l /dev/console | awk '{ print $3 }')
echo "Current user is $currentUser"

# Skip companyadmin; for others, remove from admin group if currently admin.
if [[ $currentUser != "companyadmin" ]]; then
	if id -Gn $currentUser | grep -q -w "admin"; then
		/usr/sbin/dseditgroup -o edit -n /Local/Default -d $currentUser -t "user" "admin"
		echo "Demoted $currentUser from admin"
	else
		echo "$currentUser is not a local admin"
	fi
fi

exit 0
