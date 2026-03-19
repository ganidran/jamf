#!/bin/bash
#
# Jamf extension attribute: reports whether the current console user is
# signed into iCloud (Yes + account ID, or No) using system plists.

###########################
##### SET VARIABLES #######
###########################

currentUser=$(stat -f "%Su" /dev/console)
appleAccountsPlist="/Library/Preferences/SystemConfiguration/com.apple.accounts.exists.plist"
mobileMePlist="/Users/$currentUser/Library/Preferences/MobileMeAccounts.plist"
accountId=$(plutil -convert xml1 -o - "$mobileMePlist" | awk '/<key>AccountID<\/key>/{getline; print}' | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')

###########################
### CHECK ICLOUD STATUS ###
###########################

if [ -f "$appleAccountsPlist" ]; then
    appleAccountValue=$(/usr/libexec/PlistBuddy -c "Print :com.apple.account.AppleAccount.exists" "$appleAccountsPlist" 2>/dev/null)
    if [ "$appleAccountValue" == "1" ]; then
        echo "<result>Yes. $accountId logged in</result>"
    else
        echo "<result>No</result>"
        exit 0
    fi
else
    echo "<result>No</result>"
    exit 0
fi
exit 0
