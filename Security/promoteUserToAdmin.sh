#!/bin/bash
#
# Promotes the currently logged-in user to local admin by appending their
# GeneratedUID and username to the admin group (skips if user is root).

###########################
###### SET VARIABLE #######
###########################

# Resolve the console user.
userName=$(stat -f "%Su" /dev/console)

###########################
###### DO THE THINGS ######
###########################

# Root cannot be promoted; otherwise read GeneratedUID and add to admin group.
if [ "$userName" == "root" ]; then
	echo "root user can't be removed"
else
	dscl . -read /Users/$userName GeneratedUID
	cmdResults=$?
	echo "Result: $cmdResults"

	if [ "$cmdResults" == "0" ]; then
		generatedUid=$(dscl . -read /Users/$userName GeneratedUID | awk '{print $2}')
		echo "Adding: $generatedUid"
		dscl . -append /Groups/admin GroupMembers "$generatedUid"
	fi

	echo "Adding: $userName"
	dscl . -append /Groups/admin GroupMembership "$userName"
fi

exit 0
