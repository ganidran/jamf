#!/bin/bash
#
# Prompts the user to install a cached macOS update with a configurable deferral
# limit. Uses swiftDialog and a plist to track deferrals; runs install when
# user accepts or when deferrals are exhausted.

###########################
##### SET VARIABLES #######
###########################

# Jamf parameter 4: release date for messaging.
releaseDate="$4"
dialogPath="/usr/local/bin/dialog"
pBuddy="/usr/libexec/PlistBuddy"
deferralMaximum="5"
deferralPlist="/private/var/tmp/com.os$releaseDate.deferrals.plist"

###########################
##### SYSTEM CHECKS #######
###########################

# Require a cached installer in erase-install folder.
for installer in /Library/Management/erase-install/*.pkg; do
    if [ -e "$installer" ]; then
        echo "Cached installer found. Proceeding..."
        break
    else
        echo "Cached installer not found. Exiting."
        exit 0
    fi
done

# Ensure company icon and swiftDialog exist.
if [ -e /usr/local/jamf/company-icon.png ]; then
    echo "Company Images exist. Proceeding..."
else
    echo "Company Images don't not exist. Installing..."
    jamf policy -event install-company-images
fi
if [ -e "$dialogPath" ]; then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
fi
sleep 1

###########################
##### SET FUNCTIONS #######
###########################

# Run the cached OS install policy and exit.
function doTheThings() {
    echo "Installing the cached update..."
    sleep 1
    jamf policy -event install-os-cached
}

# Show dialog offering Update or Not Now (deferral).
function promptWithDeferral() {
    "$dialogPath" \
    --title "Time To Update macOS!" \
    --icon /usr/local/jamf/company-icon.png \
    --message "Hi! Company IT here to inform of an important macOS update released on $releaseDate. This **can take 30 minutes or more**.  \n\nSave any open documents and connect your laptop to power before continuing. If you're able to update now, _Update_ will start the process. Otherwise, _Not Now_ will defer it for a maximum of 5 deferrals. \n\n**You can also update manually anytime from our Company Self Service app. See [our Notion page](<Internal Documentation Link>) for more info.**" \
    --button1text "Update" \
    --button2text "Not Now" \
    --messageposition center \
    --moveable \
    --ontop \
    --messagefont "size=15" \
    --width 650 --height 325
}

# Show final dialog (no deferral left); timer then update.
function promptNoDeferral() {
    "$dialogPath" \
    --title "ALERT: The update is about to start!" \
    --icon /usr/local/jamf/company-icon.png \
    --message "There is an outstanding update that needs to be installed and no deferrals are left. \n\n**This may take 30 minutes or more.** Your Mac will automatically update in 10 minutes. To begin the update immediately, press the 'Update Now' button. \n\nPlease make sure your laptop is plugged in, charging and save any open documents." \
    --moveable \
    --messageposition center \
    --quitkey l \
    --timer 600 \
    --ontop \
    --messagefont "size=15" \
    --button1text "Update Now" \
    --width 600 --height 300
}

function logMessage() {
    echo "$(date): $*"
}

# Exit with optional log message.
function cleanup() {
    logMessage "${2}"
    exit "${1}"
}

# Ensure deferral plist is writable and required keys exist.
function verifyConfigProfile() {
    if $pBuddy -c "Add Verification string Success" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Delete Verification string Success" "$deferralPlist" > /dev/null 2>&1
    else
        cleanup 1 "ERROR: Cannot write to the deferral file: $deferralPlist"
    fi
    verifyDeferralValue "ActiveDeferral"
    verifyDeferralValue "DeferralCount"
}

# Add integer 0 for key if missing so PlistBuddy doesn't error on read.
function verifyDeferralValue() {
    if ! $pBuddy -c "Print :$1" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Add :$1 integer 0" "$deferralPlist"  > /dev/null 2>&1
    fi
}

# If active deferral time is in the future, exit quietly.
function checkForActiveDeferral() {
    currentDeferral=$($pBuddy -c "Print :ActiveDeferral" "$deferralPlist")
}

# Increment deferral count, show message, write plist, and exit.
function executeDeferral() {
    deferralCount=$(( deferralCount + 1 ))
    "$dialogPath" \
    --title "Deferred" \
    --icon /usr/local/jamf/company-icon.png \
    --message "Update will be deferred. You have deferred $deferralCount of $deferralMaximum time(s)." \
    --button1text "OK" \
    --moveable \
    --ontop \
    --messageposition center \
    --messagefont "size=15" \
    --width 500 --height 250
    deferralDialogResults=$?
    if [ "$deferralDialogResults" = 0 ]; then
       true
    fi
    $pBuddy -c "Set DeferralCount $deferralCount" $deferralPlist
    $pBuddy -c "Add :HumanReadableDeferralDate string" "$deferralPlist"  > /dev/null 2>&1
    cleanup 0 "User chose deferral $deferralCount of $deferralMaximum."
}

###########################
##### DO THE THINGS #######
###########################

verifyConfigProfile
unixEpochTime=$(date +%s)
checkForActiveDeferral
deferralCount=$($pBuddy -c "Print :DeferralCount" $deferralPlist)

# Allow or disallow deferral based on count vs maximum.
if [ "$deferralCount" -ge "$deferralMaximum" ]; then
    allowDeferral="false"
else
    allowDeferral="true"
fi

if [ "$allowDeferral" = "true" ]; then
    if promptWithDeferral; then
        doTheThings
        thingsExitCode=$?
        cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
    else
        executeDeferral
    fi
else
    promptNoDeferral
    doTheThings
    thingsExitCode=$?
    cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
fi
