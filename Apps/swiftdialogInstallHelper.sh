#!/bin/bash
#
# Prepares the Dialog app for swiftDialog: ensures the app folder and icon
# exist under /Library/Application Support/Dialog, loads fontd if needed,
# and fixes permissions. Used as part of deploying or renewing swiftDialog.

###########################
##### SET VARIABLES #######
###########################

dialogPath="/Library/Application Support/Dialog"
imagePath="/usr/local/jamf/company-icon.png"

###########################
##### DO THE THINGS #######
###########################

# Remove existing Dialog folder and stray binary so install is clean.
if [ -e "$dialogPath" ]; then
    echo "Dialog folder exists. Renewing..."
    rm -rf "$dialogPath"
    rm -f /usr/bin/local/dialog
fi

# Load font daemon to avoid X font errors.
launchctl load -w /System/Library/LaunchAgents/com.apple.fontd.useragent.plist

# Create folder, set ownership and permissions, copy and rename company icon.
mkdir "$dialogPath"
sleep 1
chown root:wheel "$dialogPath"
chmod 755 "$dialogPath"
cp $imagePath "$dialogPath"
mv "$dialogPath/company-icon.png" "$dialogPath/Dialog.png"
exit 0
